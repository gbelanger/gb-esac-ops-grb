#!/bin/bash

if [ $# != 1 ]
then
    echo "Usage: ./processGRB.sh gcn.txt"
    exit -1
fi

# Update the revno file
#./getrevno

# Define a rounding function
round()
{
echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
};
echo

# Define AO number, GRB proposals and PIs, and the note on data rights
ao="14"
grbProposals="1440016, 1440018, 1440023"
grbProposalsAndPIs="1440016 (Savchenko), 1440018 (Gotz), 1440023 (Martin-Carrillo)" 
note="Note that 1440018 (Gotz) and _no other proposal_ is granted access to all GRB events but _only_ for polarization studies with IBIS; and 1440016 (Savchenko) gets all IBIS Compton-mode data to study GRBs _outside_ the IBIS PCFOV (the PI is responsible for identifying the appropriate GRBs and informing ISOC). In the case of any coincident GW or high-energy neutrino event, the details concerning data access are handled by the INTEGRAL Project Scientist."

#  Extract the date and time of the GRB from the GCN circular
gcnNo=`egrep NUMBER $1 | cut -d":" -f2 | awk '{print $1}'`
gcn_dateAndTime=`egrep DATE $1 | cut -d":" -f2,3`
gcn_date=`echo $gcn_dateAndTime | cut -d" " -f1`

year="20`echo $gcn_date | cut -d"/" -f1`"
month=`echo $gcn_date | cut -d"/" -f2`
gcn_day=`echo $gcn_date | cut -d"/" -f3`

echo "Processing GRB from GCN $gcnNo ..."

grb_name=`egrep SUBJECT $1 | cut -d":" -f2 | awk '{print $1,$2}'`
grb_h=`egrep UT $1 | cut -d":" -f1 | cut -d" " -f4`
grb_m=`egrep UT $1 | cut -d":" -f2`
grb_s=`egrep UT $1 | cut -d":" -f3 | cut -d" " -f1`
grb_day=`egrep UT $1 | cut -d":" -f3 | cut -d" " -f5 | cut -d"," -f1` 

grb_ra=`egrep 'R.A.' $1 | cut -d"=" -f2 | awk '{print $1}'`
grb_dec=`egrep 'DEC' $1 | cut -d"=" -f2 | awk '{print $1}'`
flux_val=`egrep 'counts/cm2/s' $1 | cut -d" " -f1`
if [[ ${flux_val} == "" ]] ; then
    flux_val=`egrep 'photons/cmsq/s' $1 | cut -d" " -f1`
fi
    
if [[ $grb_day -lt 10 ]] ; then grb_day="0"$grb_day ; fi
grb_fullDate="${year}-${month}-${grb_day}T${grb_h}:${grb_m}:${grb_s}"
grb_dateAndTime="${year}-${month}-${grb_day} at ${grb_h}:${grb_m}:${grb_s}"

echo "$grb_name:"
echo "    Date and Time: ${year}-${month}-${grb_day} ${grb_h}:${grb_m}:${grb_s}"
echo "    RA: $grb_ra"
echo "    Dec: $grb_dec"
echo "    Flux: $flux_val"

#  Get the revolution
rev=`./whatrev.sh $grb_fullDate | cut -d" " -f2`
if [[ $rev == "" ]] ; then
    ./getrevno
    rev=`./whatrev.sh $grb_fullDate | cut -d" " -f2`
fi
echo "    Rev: $rev"

#  Query the scheduling webpage to get the observations during that revolution
echo "Getting scheduling information ... "
url="http://intweb.esac.esa.int/isocweb/schedule.html?action=schedule&startRevno=${rev}&endRevno=${rev}&reverseSort=&format=csv"
wget -q -O obs.csv "${url}"

# Drop the "" everywhere and lose the header line
sed s/\"//g obs.csv | sed s/"^ *"// | egrep '^[0-9]' > obs_dataOnly.csv
echo "    Written to obs.cvs (and obs_dataOnly.cvs)"


# Go throung the observations until the end time is greater than the GRB time
nObs=`wc -l obs_dataOnly.csv | awk '{print $1}'`
i=1  # observation number
dateDiff=1

while [[ $dateDiff > 0 ]] && [[ $i -le $nObs ]]
do
  obs=`head -$i obs_dataOnly.csv | tail -1`
  obsEnd=`echo $obs | cut -d"," -f3`
  obsEnd_date=`echo $obsEnd | cut -d" " -f1`
  obsEnd_time=`echo $obsEnd | cut -d" " -f2`
  
  obsEnd_day=`echo $obsEnd_date | cut -d"-" -f3`
  obsEnd_h=`echo $obsEnd_time | cut -d":" -f1`
  obsEnd_m=`echo $obsEnd_time | cut -d":" -f2`
  obsEnd_s=`echo $obsEnd_time | cut -d":" -f3`
  echo "    End of obs $i: $year-$month-$obsEnd_day $obsEnd_h:$obsEnd_m:$obsEnd_s"

  # The scripts datediff.pl subtracts the second date from the first
  dateDiff=`datediff.pl $year $month $obsEnd_day $obsEnd_h $obsEnd_m $obsEnd_s $year $month $grb_day $grb_h $grb_m $grb_s`
  i=$((i+1))
done

#  Once we get out of the while, we have found the observation in which the GRB occurred
obsNo=$((i-1))
echo "    GBR occurred during obs $obsNo"
echo "Getting observation details ..."
source=`echo $obs | cut -d"," -f5`
echo "    Source: $source"
pattern=`echo $obs | cut -d"," -f8 | awk '{print $1}'`
pi=`echo $obs | cut -d"," -f9`
proposalNo=`echo $obs | cut -d"," -f10`
if [ "$pi" = "HEX" ] || [ "$pi" = "5x5" ] ;
then
    pattern=`echo $obs | cut -d"," -f9 | awk '{print $1}'`
    pi=`echo $obs | cut -d"," -f10`
    proposalNo=`echo $obs | cut -d"," -f11`
fi    
echo "    PI: $pi"
echo "    Proposal: $proposalNo"
echo "    Pattern: $pattern"
if [ "$pattern" == "5x5" ] ; then
    patternID="27271"
elif [ "$pattern" == "HEX" ] ; then
    patternID="93"
elif [ "$pattern" == "GPS" ] ; then
    patternID="94"
elif [ "$pattern" == "Staring" ] ; then
    patternID="96"
elif [ "$pattern" == "Norma" ] ; then
    patternID="94135"
elif [ "$pattern" == "Perseus" ] ; then
    patternID="96266"
fi
echo "    Pattern ID: $patternID"
wget -q -O out "http://integral.esac.esa.int/isocweb/schedule.html?action=lastpos&revno=$rev"
posVersion=`egrep '^[0-9]' out | awk '{print $1}'`
echo "    POS Version: $posVersion"

j=$((obsNo-1))
wget -q -O out "http://integral.esac.esa.int/isocweb/schedule.html?action=eventno&revno=$rev&posVersion=$posVersion"
events=`egrep '^[0-9]' out`
eventNo=`echo $events | cut -d";" -f$obsNo | awk '{print $1}'`
#./calc.pl 4+3*$j`
echo "    Event No: $eventNo"
rm out

#  Get the pointings details for this observation
urlObsDetails="http://intweb.esac.esa.int/isocweb/schedule.html?action=pattern&id=${patternID}&revno=${rev}&posVersion=${posVersion}&eventNo=${eventNo}&eventListNo=1&ao=${ao}"
#echo $urlObsDetails
wget -q -O pointings.html "${urlObsDetails}"
nLines=`wc -l pointings.html | awk '{print $1}'`

#  Drop the first header
n=`cat -n pointings.html | egrep 'Pointing id' | awk '{print $1}'`
nHeaderLines=`calc.pl $n + 8` 
nDataLines=`./calc.pl ${nLines}-${nHeaderLines}`
# Drop 4 lines of footer info to get only the table data
nGood=`./calc.pl $nDataLines-4`
tail -$nDataLines pointings.html | head -$nGood > pointings_dataOnly.txt
echo "    Details written to pointings.html (and pointings_dataOnly.txt)"

#  Go through the list of pointings to identify the one in which the GRB occurred
nPointings=`egrep "</tr>" pointings_dataOnly.txt | wc -l`
k=1  # pointing number
m=$((k-1))
dateDiff=1
while [[ $dateDiff > 0 ]] && [ $k -le $nPointings ]
do

  lineNo_ID=`./calc.pl 2+10*$m`
  lineNo_startPoint=`./calc.pl 3+10*$m`
  lineNo_endPoint=`./calc.pl 4+10*$m`
  lineNo_ra_hms=`./calc.pl 5+10*$m`
  lineNo_dec_hms=`./calc.pl 6+10*$m`
  pointingID=`head -$lineNo_ID pointings_dataOnly.txt | tail -1 | cut -d">" -f2 | cut -d"<" -f1`
  pointingRA_hms=`head -$lineNo_ra_hms pointings_dataOnly.txt | tail -1 | cut -d">" -f2 | cut -d"<" -f1`
  pointingDec_hms=`head -$lineNo_dec_hms pointings_dataOnly.txt | tail -1 | cut -d">" -f2 | cut -d"<" -f1`

  pointingRaDec=`java -jar Hms2deg.jar $pointingRA_hms $pointingDec_hms`
  pointingRA=`echo $pointingRaDec | cut -d" " -f1`
  pointingDec=`echo $pointingRaDec | cut -d" " -f2`
  pointingEnd=`head -$lineNo_endPoint pointings_dataOnly.txt | tail -1 | cut -d">" -f2 | cut -d"<" -f1`
  pointingEnd_date=`echo $pointingEnd | cut -d" " -f1`
  pointingEnd_time=`echo $pointingEnd | cut -d" " -f2`
  
  pointingEnd_day=`echo $pointingEnd_date | cut -d"-" -f3`
  pointingEnd_h=`echo $pointingEnd_time | cut -d":" -f1`
  pointingEnd_m=`echo $pointingEnd_time | cut -d":" -f2`
  pointingEnd_s=`echo $pointingEnd_time | cut -d":" -f3`

  echo "    End of pointing $k ($pointingID): ${year}-${month}-${pointingEnd_day} ${pointingEnd_h}:${pointingEnd_m}:${pointingEnd_s}"

  dateDiff=`datediff.pl $year $month $pointingEnd_day $pointingEnd_h $pointingEnd_m $pointingEnd_s $year $month $grb_day $grb_h $grb_m $grb_s`
  k=$((k+1))
  m=$((k-1))
done

# Once we get out, we have found the pointing during which the GRB occurred
pointingNo=$((k-1))

#  Calcualte the angular separation from the GRB and pointing axis
angDist=`java -jar GetAngularDist.jar $grb_ra $grb_dec $pointingRA $pointingDec`
intPart=`echo $angDist | cut -d"." -f1`
decPart=`echo $angDist | cut -d"." -f2 | awk '{print substr($1,0,2)}'`
angDist="${intPart}.${decPart}"

echo "GBR occurred during pointing number $pointingNo:"
echo "    ID: $pointingID"
echo "    RA: $pointingRA"
echo "    Dec: $pointingDec"
echo "    Angular dist to GRB: $angDist"
echo "Generating email to PIs"

#touch previousGRBCount.dat
#cp brightGRBCounter.dat previousGRBCount.dat
#grbCount=`cat brightGRBCounter.dat`
d=`calc.pl nint\($angDist\)`
f=`calc.pl nint\($flux_val\)`

#if [[ $d -le 6 ]] || [[ $f -lt 1 ]] ; then
#    dataRights="1440023 (Martin-Carrillo) is granted data rights on all instruments."
#else
    #else
#    if [[ $f -ge 1 ]] ; then
#	if [[ `calc.pl $grbCount%2` -eq 1 ]] ; then
#	    dataRights="1340007 (Pozanenko) is granted data rights on all instruments."
#	else
#	    dataRights="1340030 (Martin-Carrillo) is granted data rights on all instruments."
#	fi
#	count=`calc.pl $grbCount+1`
#	echo $count > brightGRBCounter.dat
#    fi	
#fi
#    dataRights=" ... fill in ... 1340030 (Martin-Carrillo) OR 1340007 (Pozanenko) is granted data rights on all instruments. ..."
#fi
dataRights="1440023 (Martin-Carrillo) is granted data rights on all instruments."

    
src=`echo $source | sed s/"\/"/"-"/g`
sed s/"{source}"/"$src"/g email_template.txt | sed s/"{ao}"/"$ao"/g | sed s/"{grbProposals}"/"$grbProposals"/g | sed s/"{grbProposalsAndPIs}"/"$grbProposalsAndPIs"/g | sed s/"{grb_name}"/"$grb_name"/g | sed s/"{gcnNo}"/"$gcnNo"/g | sed s/"{proposalNo}"/"$proposalNo"/g | sed s/"{pi}"/"$pi"/g | sed s/"{rev}"/"$rev"/g | sed s/"{grb_dateAndTime}"/"$grb_dateAndTime"/g | sed s/"{grb_ra}"/"$grb_ra"/g | sed s/"{grb_dec}"/"$grb_dec"/g | sed s/"{angDist}"/"$angDist"/g | sed s/"{pointingID}"/"$pointingID"/g | sed s/"{pointingRa}"/"$pointingRA"/g | sed s/"{pointingDec}"/"$pointingDec"/g | sed s/"{flux_val}"/"$flux_val"/g | sed s/"{dataRights}"/"$dataRights"/g | sed s/"{note}"/"$note"/g > email_$1

if [[ $proposalNo =~ "886" ]] || [[ $pi =~ "Public" ]] ; then
    nLines=`wc email_$1 | awk '{print $1}'`
    n=`calc.pl $nLines - 2`
    head -1 email_$1 > tmp
    tail -$n email_$1 > tmp2
    cat tmp tmp2 > email_$1
    rm tmp tmp2
fi

echo "GRB Processing Complete"
echo "Email to PIs written to file email_$1"
echo

/bin/rm obs.csv obs_dataOnly.csv pointings.html pointings_dataOnly.txt
