#!/bin/bash

#
# Copyright (c) 2014, UChicago Argonne, LLC
# See LICENSE file.
#
source ${HOME}/.MIDAS/paths
echo "Spot ID:"
echo $1
${BINFOLDER}/IndexerLinuxArgsShm paramstest.txt $1
${BINFOLDER}/FitPosOrStrains paramstest.txt $1
# This was the idea with 2000 jobs
#~ echo "Chunk:"
#~ echo $1
#~ python ${PFDIR}/IndexStrains.py $1 $2
