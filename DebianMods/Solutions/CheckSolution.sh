#!/bin/bash
# Last update:  05/12/2017
#
# Reads all files listed in the tar gzipped archive
#
# Usage:
#
#   /opt/nHDpem/data/bin/CheckSolution.sh <Root_TarGZ_Name> 
#
cur_dir=`pwd`

cd /opt/nHDpem/data/archive
tar -tvf $1.tar.gz

cd $cur_dir

