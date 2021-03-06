#!/bin/bash
#
# Usage:   ./makeRecexpt-tsunami snapfile.snp experiment stationID
#          ./makeRecexpt-tsunami demo.snp eur85 on
#
# Input:  SNAP file created with DRUDG from the schedule for your station
#
# Output: The 'recexpt_[stationID]-tsunami' file for recording the experiment 
#         via real-time Tsunami client
#         You may need to edit 'recpass-tsunami' for correct server name and 
#          data rate settings.
#
# ---code could be improved a LOT.....----


if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
   echo "Syntax: ./makeRecexpt-tsunami.sh snapfile.snp experiment stationID"
   echo "        ./makeRecexpt-tsunami.sh euro85on.snp EURO85 on"
   exit
fi

SNP=$1
EXPT=$2
STATION=$3

echo "Snap file: $SNP"

# get scan names, convert "," to space
sed -n -e '/scan_name=/s/scan_name=//p' $SNP | sed -n -e 's/,/ /gp' > ./scans

# get start times
# sed -n -e '/preob/,/!/p' $SNP | grep ! | sed -n -e 's/[!.]/ /gp' > ./starttimes
cat $SNP | grep disk_pos -1 | grep ! | sed -n -e 's/[!.]/ /gp' > ./starttimes

# merge the two files
I=1
LC=`wc -l scans | awk '{print $1}'`
rm -f ./merged
while [ $I -le $LC ]
do
   SCAN_CURR=`tail -n +$I scans | head -1`
   TIME_CURR=`tail -n +$I starttimes | head -1`
   #echo " sc=${SCAN_CURR} tc=${TIME_CURR} "
   echo "${SCAN_CURR} ${TIME_CURR}" >> merged
   I=$(($I+1))
done

# create recexpt
FOUT="recexptsunami_${EXPT}_${STATION}.sh"
cat recexpt-tsunami.head > $FOUT
cat merged | while read scan expt station dur1 dur2 year day clock; do

#   if [ "${dur1}" -ne "${dur2}" ]; then
#      clock=$day; day=$year; year=$dur2; dur2=$dur1;
#   fi

   # remove leading 0's from day, convert from day-of-year into date
   day=`echo ${day} | sed 's/^[0\t]*//'`;
   day=$(($day - 1))

   # Format: [expt_station_]No0001_yyyy-mm-ddThh:mm:ss
   datestr=`date -d "01/01/${year} + ${day} days" +"%Y-%m-%d"`
   # Format: [expt_station_]No0001_yyyydddhhmmss
   datestr2=`date -u -d "01/01/$year + $day days $clock" +"%04Y%03j%02H%02M%02S"`
   # Format: [expt_station_]No0001_yyyy'y'ddd'd'hh'h'mm'm'ss's'
   datestr3=`date -u -d "01/01/$year + $day days $clock" +"%04Yy%03jd%02Hh%02Mm%02Ss"`

   result=`echo -e "\t${scan}_${datestr3}\t$year\t$((day + 1))\t${clock}\t${dur1}"`
   echo -e "$result"
   echo -e "$result" >> $FOUT
done
echo ")"                 >> $FOUT
echo "SID=${STATION}"    >> $FOUT
echo "EXPT=${EXPT}"      >> $FOUT

cat recexpt-tsunami.tail >> $FOUT

chmod ug+x $FOUT

echo
echo "Script output written to: $FOUT "
echo

