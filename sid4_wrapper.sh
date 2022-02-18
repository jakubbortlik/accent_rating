#!/bin/bash - 
#===============================================================================
#
#          FILE: sid4_wrapper.sh
# 
#         USAGE: ./sid4_wrapper.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Jakub Bortlik, jakub.bortlik@protonmail.com
#  ORGANIZATION: 
#       CREATED: 09/16/21 13:58
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

SID_DIR="./05_SID_experiments/SID4-XL4-cmd-3.42.1-lin64"

if [[ $# = 0 ]] ; then
  echo "Usage: $0 model (e.g. $0 xl4)"
  exit 1
fi

if [[ ! -f "$SID_DIR/settings/vpextract4_${1}.bs" ]]; then
  echo "Model ${1} does not exist"
  exit 1
fi

WAV_DIR="./05_SID_experiments/samples"
VP_DIR="./05_SID_experiments/voiceprints_${1}"
SCORE_FILE="$VP_DIR/sid4_${1}_scores.sco"
LENGTH_FILE="$VP_DIR/sid4_${1}_speech_length.csv"

echo "Running vpextract4 on directory $WAV_DIR"
$SID_DIR/vpextract4 -c $SID_DIR/settings/vpextract4_${1}.bs -d $WAV_DIR -D $VP_DIR -v -j 2
echo "voiceprints saved in $VP_DIR"

echo "Running vpcompare4 on directory $VP_DIR"
$SID_DIR/vpcompare4 -c $SID_DIR/settings/vpcompare4_${1}.bs -d $VP_DIR $VP_DIR -o $SCORE_FILE -get-file-names -out-fmt s
echo "Scores saved as $SCORE_FILE"

echo "Running vpinfo4 on directory $VP_DIR"
for i in $VP_DIR/*vp; do
	echo ${i##*/} $($SID_DIR/vpinfo4 $i | grep "Speech" | sed 's/ \+/ /g' | cut -d' ' -f3) >> $LENGTH_FILE
done
echo "speech lengths saved as $LENGTH_FILE"

exit
