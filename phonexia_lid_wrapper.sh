#!/bin/bash - 
#===============================================================================
#
#          FILE: phonexia_lid_wrapper.sh
# 
#         USAGE: ./phonexia_lid_wrapper.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: This script requires the LID application to work!
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Jakub Bortlik, jakub.bortlik@protonmail.com 
#  ORGANIZATION: 
#       CREATED: 09/16/21 13:58
#      REVISION: 12/02/21 22:53
#===============================================================================

set -o nounset                              # Treat unset variables as an error

LID_DIR="~/LID-L4-cmd-3.42.1-lin64"

if [[ $# = 0 ]] ; then
  echo "Usage: $0 model (e.g. $0 o)"
  exit 1
fi

if [[ ! -f "$LID_DIR/settings/lpextract_$1.bs" ]]; then
  echo "Model $1 does not exist"
  exit 1
fi

WAV_DIR="~/samples"
LP_DIR="~/languageprints_$1"
SCORE_FILE="$LP_DIR/phonexia_lid_$1.sco"
LENGTH_FILE="$LP_DIR/lid_$1_speech_length.csv"

# Extract the "language prints"
echo "Running lpextract on directory $WAV_DIR"
echo $LID_DIR/lpextract -c $LID_DIR/settings/lpextract_$1.bs -d $WAV_DIR -D $LP_DIR -v -j 2
$LID_DIR/lpextract -c $LID_DIR/settings/lpextract_$1.bs -d $WAV_DIR -D $LP_DIR -v -j 2
echo "Languageprints saved to $LP_DIR"

# Specify the subset of languages which can be recognized
ACTIVE_LANGS="arb,cs-CZ,cv-RU,de,el-GR,en-GB,en-US,es-ES,es-XA,fa-IR,fr,id-ID,it,ja-JP,ka-GE,kk-KZ,lt-LT,nan-CN,nl,pl-PL,pt,rn-BI,ro-RO,ru-RU,sl-SI,sv-SE,ta,tr-TR,uk-UA,uz-UZ,zh-CN,zh-HK,am-ET,as-IN,az-AZ,be-BY,bg-BG,bn-BD,bo,ceb-PH,fa-AF,gn,ha,hi-IN,ht-HT,hu-HU"

# Perform language identification on the "language prints"
echo "Running lid on directory $LP_DIR"
echo $LID_DIR/lid -c $LID_DIR/settings/lid_$1.bs -d $LP_DIR -e lp -active-langs $ACTIVE_LANGS -get-all-scores -o $SCORE_FILE
$LID_DIR/lid -c $LID_DIR/settings/lid_$1.bs -d $LP_DIR -e lp -active-langs $ACTIVE_LANGS -get-all-scores -o $SCORE_FILE
echo "Scores saved as $SCORE_FILE"

# # Alternatively run the lid directly on the WAVE files
# echo "Running lid on directory $WAV_DIR"
# SCORE_FILE="phonexia_lid_$1_from_wav.sco"
# $LID_DIR/lid -c $LID_DIR/settings/lid_$1.bs -d $WAV_DIR -active-langs $ACTIVE_LANGS -get-all-scores -o $SCORE_FILE
# echo "Saved scores to file $SCORE_FILE"

# Run the `lpinfo` application to get amount of speech in individual files
echo "Running lpinfo on directory $LP_DIR"
for i in $LP_DIR/*lp; do
	echo ${i##*/} $($LID_DIR/lpinfo $i | grep "Speech" | sed 's/ \+/ /g' | cut -d' ' -f3) >> $LENGTH_FILE
done
echo "Speech lengths saved to file $LENGTH_FILE"

exit
