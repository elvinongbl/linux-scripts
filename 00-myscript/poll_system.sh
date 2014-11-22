#!/bin/bash

set -e

usage () {
cat << EOF
`basename $0` --help|-h
 - display usage of this script
`basename $0` -p <#polls>
 - poll the system for # of times (each poll is 1s lapse)
EOF
}

if [ $# -ne 2 -o "$1" != "-p" ]; then
	usage
	exit 0
fi

if [ "$1" == "--help" -o "$1" == "-h" ]; then
	usage
	exit 0
fi

if [ "$1" == "-p" ]; then
	poll_count=$2
fi

report () {
cat << EOF

========
CPU INFO
========

Cpu Count:   CPUCOUNT
model name:  MODELNAME
cpu MHz:     CPUMHZ

===============
interrupt count
===============
usb1: USBINT
eth0: ETHINT

===============
System Memory
==============
MemTotal(kB): TOTALCOUNT
MemFree (kB): FREECOUNT
Active  (kB): ACTIVECOUNT

Created at `date` for POLLCOUNT poll

EOF
}

cpu_count=`cat /proc/cpuinfo | grep processor | wc -l`
model_name=`cat /proc/cpuinfo | grep "model name" -m 1 | cut -d":" -f2`
cpu_mhz=`cat /proc/cpuinfo | grep "cpu MHz" -m 1 | cut -d":" -f2`

get_dev_intr () {
	snap=`cat /proc/interrupts | grep $1 | cut -c6-`
	total_count=0
	for cpu in `seq 1 $cpu_count`
	do
		int_count=`echo $snap | cut -d' ' -f${cpu}`
		total_count=$(($total_count+$int_count))
	done
	echo ${total_count}
}

get_dev_mem () {
	snap=`cat /proc/meminfo | grep "$1:" | cut -d':' -f2 | sed -e "s# kB##g"`
	echo $snap
}

for i in `seq 1 $poll_count`
do
	usb1_int[$i]=`get_dev_intr "usb1"`
	eth0_int[$i]=`get_dev_intr "eth0"`
	mem_total[$i]=`get_dev_mem "MemTotal"`
	mem_free[$i]=`get_dev_mem "MemFree"`
	mem_active[$i]=`get_dev_mem "Active"`
	sleep 1
done

report | sed -e "s#CPUCOUNT#$cpu_count#g" \
	-e "s#MODELNAME#$model_name#g" \
	-e "s#CPUMHZ#$cpu_mhz#g" \
	-e "s#USBINT#${usb1_int[*]}#g" \
	-e "s#ETHINT#${eth0_int[*]}#g" \
	-e "s#TOTALCOUNT#${mem_total[*]}#g" \
	-e "s#FREECOUNT#${mem_free[*]}#g" \
	-e "s#ACTIVECOUNT#${mem_active[*]}#g" \
	-e "s#POLLCOUNT#$poll_count#g" > system_summary.txt

exit 0
