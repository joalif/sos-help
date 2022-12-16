#!/bin/bash

# path for sos_commands/process
process_path="sos_commands/process"
proc="proc"

# find mtail - pids
mtail_pids=`cat $process_path/ps_alxwww | grep mtail | awk '{print $3}'`
apache_pids=`cat $process_path/ps_alxwww | grep apache_exporter | awk '{print $3}'`


print_VmRSS () {
  for i in "$@" 
  do
    echo $i 
    cat $proc/$i/status | grep "VmRSS"
  done | xargs -n4 | sort -r -n -k3
        
        
}

# sometime status file is not in sosreport so get the RSS from smaps
print_RSS_from_smaps_single() {
  pid=$1
  cat $proc/$1/smaps | grep "Anonymous" | grep -v "Anonymous:             0 kB" | awk -v awkvar=$pid '{sum+=$2;}END{print awkvar " " sum;}'

}

print_RSS_from_smaps_all() {
  for i in "$@" 
  do 
    echo $i; 
    cat $proc/$i/smaps | grep "Anonymous" | grep -v "Anonymous:             0 kB" | awk '{sum+=$2;}END{print sum;}' ; 
  done | xargs -n2 | sort -r -n -k2
}

return_highest_anonymous() {
  for i in "$@" 
  do 
    echo $i; 
    cat $proc/$i/smaps | grep "Anonymous" | grep -v "Anonymous:             0 kB" | awk '{sum+=$2;}END{print sum;}' ; 
  done | xargs -n2 | sort -r -n -k2 | head -1
}

Lazyfree() {
  pid=$1
  cat $proc/$pid/smaps | grep "LazyFree" | grep -v "LazyFree:              0 kB" | awk '{sum+=$2;}END{print sum;}'
}

Trans_huge() {
  pid=$1
  cat $proc/$pid/smaps | grep "AnonHuge" | grep -v "AnonHugePages:         0 kB" | awk '{sum+=$2;}END{print sum;}'
}

Dirty() {
  pid=$1
  cat $proc/$pid/smaps | grep "Dirty" | grep -v "Shared_Dirty:          0 kB" | grep -v "Private_Dirty:         0 kB" | awk '{sum+=$2;}END{print sum;}'
  
}

for j in "mtail" "apache_exporter" ; do
if [[ "$j" == "mtail" ]] ; then 
show="MTAIL"
pids=$mtail_pids
else
show="APACHE_EXPORTER"
pids=$apache_pids
fi

echo "###################START OF $show REPORT###################"
#echo "*****Anonymous mtail*****"
#echo "Pid Anonymous"
print_RSS_from_smaps_all $pids
#echo "*****Anonymus mtail END*****"
echo ""
echo ""
highest_anon="$(return_highest_anonymous $pids)" 
#echo $highest_anon
pid=`echo $highest_anon | cut -d" " -f1`
anon=`echo $highest_anon | cut -d" " -f2`
#echo $pid
#echo $anon

threshold=102400 # in KB, 100MB
#mem=202400

if (( anon > threshold )) ; then
  echo "****************************************************"
  echo "WARNING MTAIL ANON HIGHER THAN THRESHOLD"
  echo "PID: $pid"
  echo "ANON: $anon"
  echo "****************************************************"

  # will check for Lazyfree,dirty and thp for this one
  lazy="$(Lazyfree $pid)"
  thp="$(Trans_huge $pid)"
  dirty="$(Dirty $pid)"
  echo ""
  echo "Summary for 1734161 (in KB)"
  echo "Anon: $anon"
  echo "Dirty: $dirty"
  echo "Lazy: $lazy"
  echo "THP: $thp"
fi

echo "####################END OF $show REPORT####################"
done
#echo "*****RSS mtail*****"
#print_VmRSS $mtail_pids
#echo "*****RSS mtail END*****"
#echo ""
#echo ""

#echo "*****RSS apache*****"
#print_VmRSS $apache_pids
#echo "*****RSS apache END*****"

#for i in $mtail_pids
#do
#print_RSS_from_smaps_single $i
#done
