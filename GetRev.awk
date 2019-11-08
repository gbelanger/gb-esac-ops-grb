#-------------------------------------------------------------------------------
#
# @(#)/home/xmmsw/scripts/ahf/util/SCCS/s.GetRev.awk	1.2	02/11/12	XMM_AHF_FDD
#
# Awk command file to get the current revolution number and
# revolution start and stop times for a given time
#
# Usage: awk -f GetRev.awk time=YYYY-MM-DDThh:mm:ssZ ~/data/revno
#
# Input: time
# Output: rev "start_time" "stop_time" (note the double quotes!)
#
# (all times in format YYYY-MM-DDThh:mm:ssZ)
#
# A. Munoz Oliva (GMV)		 2000/03/15
# Updated			 2002/11/12 - JBP
#
#-------------------------------------------------------------------------------
#
BEGIN {found=0;start=0;line=0}
{
   if(0 == found && line > 5){
      if($4 > time){
         found=1;printf "%s (%s - %s)",$7-1,start,$4;
      } else {
         start = $4;
      }
   }
   line++;
}
