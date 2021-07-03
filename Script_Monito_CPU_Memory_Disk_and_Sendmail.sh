# This script is used to generate CPU, Memory, SWAP and Disk Usage statistic, process stats, established connections and send the stats via email. The aim is to make it easy for anyone to understand system performance. The output is saved in /tmp/ with todays date. For you to get the output for SWAP - swap shouldnt be zero if swap is zero you can commit swap line. Also for Ubuntu please used -A for sending the output of the script to your email. 
# While there might be room for improvement please feel free to contact me via email awsdevops1130@gmail.com.
#!/bin/bash
if which mailx > /dev/null
then
echo "mailx package exist" 

elif (( $(cat /etc/*-release | grep "Red Hat" | wc -l) > 0 ))
then
yum install sendmail mailx  net-tools dstat -y > /dev/null
else
apt install mailutils net-tools dstat -y > /dev/null
date >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
fi
echo "-----------------------------------------------------------------------" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo " ServerIP CPU(%)   Memory(%)   Swap(%)    Disk Usage(%)                " >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "-----------------------------------------------------------------------" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
hostname -I | cut -d' ' -f1 > host_IP
for server in `cat host_IP`
do
scpu=$(cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1)
smem=$( free | awk '/Mem/{printf("%.2f%"), $3/$2*100}')
sswap=$(free | awk '/Swap/{printf("%.2f%"), $3/$2*100}')
sdisk=$( df -h | awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}')
echo "$server   $scpu   $smem   $sswap $sdisk" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
done | column -t
echo "-----------------------------------------------------------------------" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "File System Usage" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "-----------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "-----------------------------------------------------------------------" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "Disk IO Utilization" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "-------------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
dstat --time --cpu --mem --load --io 1 5 >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "----------------------------------------------------------------------" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "Top Process utilizing resources"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "-------------------------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "----------------------------------------------------------------------" >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "Top Process Utilization with more details"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "-----------------------------------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
ps -eo pmem,pcpu,rss,vsize,args,user,euser,ruser,suser,fuser,f,comm,label,pid | sort -k 1 -r | head  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "Top Established connections for webapp"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "--------------------------------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
netstat -tanp  | grep ESTABLISHED |sort | uniq -c | sort -n|head  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "---------------------------------------------------------------"  >> /tmp/cpu-mem-swap-disk.`date +%h%d%y`
echo "CPU and Memory Report for `date +"%B %Y"`" | mailx -s "CPU Memory Swap & Disk Report on `date`" -a /tmp/cpu-mem-swap-disk.`date +%h%d%y` awsdevops1130@gmail.com
