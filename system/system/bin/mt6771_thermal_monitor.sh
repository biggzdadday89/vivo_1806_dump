#!/system/bin/sh

max_temp=95000
min_temp=75000
max_count=100000

function temperature_monitor()
{
	tj_node=/proc/mtktz/mtktscpu
	tj_high_threshold=$max_temp
	tj_low_threshold=$min_temp
	total_count=0
	#default set OPP0
	echo "0 0" > /proc/ppm/policy/ut_fix_freq_idx
	
	while [ $total_count -lt $max_count ]
	do
		read temp<$tj_node
		if [ $temp -gt $tj_high_threshold ]; then
			echo "15 15" > /proc/ppm/policy/ut_fix_freq_idx
		elif [ $temp -lt $tj_low_threshold ]; then
			echo "0 0" > /proc/ppm/policy/ut_fix_freq_idx
		fi
		
		sleep 0.5
		let total_count=total_count+1
	done
}

echo "thermal monitor start."
echo "thermal monitor start." >> /cache/test_log.txt

temperature_monitor

echo "thermal monitor end."
echo "thermal monitor end." >> /cache/test_log.txt
