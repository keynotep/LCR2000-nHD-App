#!/bin/bash
#
# sol.sh - LC4500-PEM Solution management script
#
#    This script is designed to be ran from a linux development station and requires internet connection to
# the target BB/PEM system.  The purpose is to be able to install or capture full solution sets on a target
# LC4500-PEM.  It works by copying a set of scripts to the target that allow Tar'ing the desired solution or
# Un-Tar'ing as necessary.  These single files can then be ported between PEM units assuming they are compatible
# Solution version.
#
#	Updates:
#  05/11/2017  Initial release. Expects <Check/Put/Get>Solution.sh scripts to be in [SolTools]
#
#
#  EX:
#	sudo ./sol.sh get 1Bit_768Pat_10ms beaglebone-grn0.local
#
#
function Command_Usage
{
        echo "usage:"
        echo "  solutions.sh <command> <Solution Name> <optional target IP>"
        echo ""
        echo "commands:"
        echo "  list - returns a list of solutions available on the target"
        echo "  get - <requires sol name> - packages and retrieves a specified solution from the target"
        echo "  put - <requires sol name> - installs a specified solution on the target"
        echo "  install - copies the required tools (scripts) on the target"
        echo "  installZ - copies the required tools (scripts) FROM the target"
        exit
}

cur_dir=`pwd`

# Change this IP address to match that of the target BB
#DefaultAddress=beaglebone-grn0
DefaultAddress=10.10.0.43

DefaultFilename=nHD_pem

PutTool=PutSolution.sh
GetTool=GetSolution.sh
CheckTool=CheckSolution.sh
# Install command currently copies all solution files
SolFile=BitPlane-Test

SolRoot=/opt/nHDpem/data/nHD
SolTools=/opt/nHDpem/data/bin
SolArchive=/opt/nHDpem/data/archive

ToolArchive=tool_pack.tar

# Make sure we have a command or no reason to continue
if [ $1x == x ]
  then
    Command_Usage
fi

# Make sure we have a target address
if [ $3x == x ]
  then
	target=root@$DefaultAddress
  else
	target=root@$3
fi
echo "  Attempting to access target unit at " $target

echo ========= update target time to local time =============
LocalDate=`date +'%Y-%m-%d %H:%M:%S'`
echo setting target date to $LocalDate
rsh $target date --set=\""$LocalDate"\"


#
# Install tools on target
#
if [ $1 == install ]
  then
    echo ========= Add tools to remote device and install =============
    rsh $target mkdir $SolTools
    rsh $target mkdir $SolArchive

    scp $PutTool $target:$SolTools
#    rsh $target sudo chmod +x $SolTools/$PutTool
    scp $GetTool $target:$SolTools
#    rsh $target sudo chmod +x $SolTools/$GetTool 
    scp $CheckTool $target:$SolTools
#    rsh $target sudo chmod +x $SolTools/$CheckTool 

# Also install any default solutions into the archive   
    scp *.tar.gz $target:$SolArchive
else

#
# Copy tools FROM the target (in case they were modified on the target)
#  NOTE: this will overwrite the local copy!
#
if [ $1 == installZ ]
  then
    echo ========= copy tools from the remote device =============
    scp $target:$SolTools/$PutTool .
    scp $target:$SolTools/$GetTool .
    scp $target:$SolTools/$CheckTool .
else

#
# Packages and pulls a specified solution from the target
#  - NOTE: tools must have been installed on target first
#
  if [ $1 == get ]
    then
      if [ $2x == x ]
      then
        Command_Usage
      else
        echo ========= Get a specified solution from the target =============
        rsh $target sudo $SolTools/$GetTool $2
        scp $target:$SolArchive/$2.tar.gz .
      fi
  else

#
# Pushes an archived package onto the target and installs the solution
#  - NOTE: tools must have been installed on target first
#
  if [ $1 == put ]
    then
      if [ $2x == x ]
        then
        Command_Usage
      else
        echo ========= Put a specified solution onto target =============
        scp $2.tar.gz $target:$SolArchive
        rsh $target sudo $SolTools/$PutTool $2
      fi
  else

#
# Lists the solutions available on the target system
#
  if [ $1 == list ]
    then
      echo ========= Lists the solutions installed on target =============
      rsh $target ls $SolRoot

  else
#
# No valid command so provide usage instructions to user
#
      Command_Usage
fi
fi
fi
fi
fi

