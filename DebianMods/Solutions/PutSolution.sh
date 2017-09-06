#!/bin/bash
# Last update:  05/12/2017
#
# Extracts all files listed in the tar gzipped archive
# and places them in the solution folder named in the 
# archive.
#
# Usage:
#
#   /opt/nHDpem/data/bin/PutSolution.sh <Root_TarGZ_Name> 
#
cur_dir=`pwd`

cd /opt/nHDpem/data/nHD
tar -xzf ../archive/$1.tar.gz 

cd $cur_dir

