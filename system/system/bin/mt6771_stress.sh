#!/system/bin/sh
DEBUG=0

function get_mem_config()
{
	MEM_SIZE=4000000  #default 4GB DRAM
	MEM_CONF=1536
	MEM_SIZE=$(cat /proc/meminfo | grep MemTotal | cut -b 18-25)
	echo "MEM_SIZE=$MEM_SIZE" >> /cache/test_log.txt
	if [ $MEM_SIZE -gt 5000000 ];then
		MEM_CONF=2048  #for 6GB DRAM
	elif [ $MEM_SIZE -gt 3500000 ];then
		MEM_CONF=1536  #for 4GB DRAM
	elif [ $MEM_SIZE -gt 2500000 ];then
		MEM_CONF=1024  #for 3GB DRAM
	else
		MEM_CONF=512  #for 2GB DRAM
	fi
	echo "MEM_CONF=$MEM_CONF" >> /cache/test_log.txt
}

function kill_proc()
{
	proc_name=$1
    echo "to be killed proc_name: $proc_name" >> /cache/test_log.txt
	ps_line=$(ps -A | grep $proc_name)

	i=0
	for n in $ps_line; do
		if [ $i -eq 1 ];then 
			pid=$n
			break
		fi
		i=$i+1
	done
	if [ ! $i -eq 1 ];then
	   echo "process $proc_name is not exist!" >> /cache/test_log.txt
	else
		echo "kill process $proc_name" >> /cache/test_log.txt
		kill -9 $pid
	fi
}

function prepare_vcore_env()
{
	echo "Prepare vcore stress env start" >> /cache/test_log.txt
	kill_proc vcorefs_p60

	echo soidle 0 > /d/cpuidle/soidle_state
	echo soidle3 0 > /d/cpuidle/soidle3_state
	echo dpidle 0 > /d/cpuidle/dpidle_state
	echo test > /sys/power/wake_lock
	echo "#cat /d/cpuidle/idle_state | grep -e dpidle_switch:" >> /cache/test_log.txt
	cat /d/cpuidle/idle_state | grep -e dpidle_switch  >> /cache/test_log.txt

	#disable kicker log
	echo kr_log_mask 0xFFFFF > /sys/power/vcorefs/vcore_debug
	echo kr_log_mask 1048575 > /sys/power/vcorefs/vcore_debug

	echo kr_req_mask 65535 > /sys/power/vcorefs/vcore_debug
	echo skip 1 > /sys/class/devfreq/10012000.dvfsrc_top/device/helio-dvfsrc/dvfsrc_debug
	echo i_hwpath 1 > /sys/power/vcorefs/vcore_debug
	echo "#cat /sys/power/vcorefs/vcore_debug | grep -e kr_req -e uv -e khz -e FSX -e hwpath -e mask:" >> /cache/test_log.txt
	cat /sys/power/vcorefs/vcore_debug | grep -e kr_req -e uv -e khz -e FSX -e hwpath -e mask  >> /cache/test_log.txt
	echo "Prepare vcore stress env end" >> /cache/test_log.txt
}

function restore_vcore_env()
{
	echo "Restore default vcore env start" >> /cache/test_log.txt
	kill_proc vcorefs_p60
	echo KIR_SYSFSX -1 > /sys/power/vcorefs/vcore_debug
	echo kr_log_mask 6408  > /sys/power/vcorefs/vcore_debug
	echo kr_req_mask 131071 > /sys/power/vcorefs/vcore_debug
	echo skip 0 > /sys/class/devfreq/10012000.dvfsrc_top/device/helio-dvfsrc/dvfsrc_debug
	echo i_hwpath 0 > /sys/power/vcorefs/vcore_debug
	echo "#cat /sys/power/vcorefs/vcore_debug | grep -e kr_req -e uv -e khz -e FSX -e hwpath -e mask:" >> /cache/test_log.txt
	cat /sys/power/vcorefs/vcore_debug | grep -e kr_req -e uv -e khz -e FSX -e hwpath -e mask  >> /cache/test_log.txt
	echo "Restore default vcore env end" >> /cache/test_log.txt
}

#1 stage test CPU 8Core, CPU-DVFS Fix OPP0, DRAM Fix 3600, Stressapptest 10min
function stress_stage_1()
{
	if [ $DEBUG -eq 1 ];then
		s1=30
	else
		s1=900
	fi

	echo "#1 stage start" >> /cache/test_log.txt
	echo "#1 stage test CPU 8Core, CPU-DVFS Fix OPP0, DRAM Fix 3600, Stressapptest 10min"
	
	echo "#1 P70 donot set vcore & dvfs opp0" >> /cache/test_log.txt
	#echo "kr_req_mask 65535" > /sys/power/vcorefs/vcore_debug
	#echo "skip 1" > /sys/class/devfreq/10012000.dvfsrc_top/device/helio-dvfsrc/dvfsrc_debug
	#echo "KIR_SYSFSX 0" > /sys/power/vcorefs/vcore_debug

	echo "4 4" > /proc/ppm/policy/ut_fix_core_num
	
	/system/bin/mt6771_thermal_monitor.sh &
	thermal_mon_pid=$!
	echo "s1 thermal_mon_pid: $thermal_mon_pid" >> /cache/test_log.txt

	/system/bin/stressapptest -s $s1 -M $MEM_CONF -m 8 -W --cc_test >> /cache/stressapptest.txt
	kill -9 $thermal_mon_pid
	echo "#1 stage end" >> /cache/test_log.txt
}

#2 stage CPU DVFS OPP0-OPP15, VCORE-DVFS OPP0-OPP3, Stressapptest test sleep 3s, test 30s, start camera, loop 30 count.
function stress_stage_2()
{
	if [ $DEBUG -eq 1 ];then
		ntest=2
	else
		ntest=30
	fi

	echo "#2 stage CPU DVFS OPP0-OPP15, VCORE-DVFS OPP0-OPP3, Stressapptest test sleep 3s, test 30s, start camera, loop 30 count."
	echo "#2 stage start" >> /cache/test_log.txt
	am start -a android.media.action.IMAGE_CAPTURE
	/system/bin/cpudvfs_hilo_test_only_dvfs.sh &
	cpudvfs_pid=$!
	echo "s2 cpudvfs_pid: $cpudvfs_pid" >> /cache/test_log.txt
	prepare_vcore_env
	/system/bin/vcorefs_p60 -i 0.001 -o 0 -o 3 -m 4 -c KIR_SYSFSX /sys/power/vcorefs/vcore_debug &
	vcorefs_pid=$!
	echo "s2 vcorefs_pid: $vcorefs_pid" >> /cache/test_log.txt

	for i in $(seq 1 ${ntest})
	do
		echo "stressapptest count=${i}" >> /cache/test_log.txt
		am start -a android.media.action.IMAGE_CAPTURE
		/system/bin/stressapptest -s 30 -M $MEM_CONF -m 8 -W --cc_test >> /cache/stressapptest.txt

		sleep 3
	done

	kill -9 $cpudvfs_pid
	# To avoid vcore setting getting into unknown state after vcorefs_p60 is killed.
	echo kr_req_mask 131071 > /sys/power/vcorefs/vcore_debug
	sleep 0.1
	kill -9 $vcorefs_pid

	sleep 2
	restore_vcore_env
	echo "-1 -1" > /proc/ppm/policy/ut_fix_freq_idx
	setprop persist.keep.awake false
	echo "#2 stage end" >> /cache/test_log.txt
}

#3 stage play 4k video and stressapptest
function stress_stage_3()
{
	if [ $DEBUG -eq 1 ];then
		s3=30
	else
		s3=240
	fi

	echo "#3 stage play 4k video and stressapptest"
	echo "#3 stage start" >> /cache/test_log.txt
	/system/bin/cpudvfs_hilo_test_only_dvfs.sh &
	cpudvfs_pid=$!
	echo "s3 cpudvfs_pid: $cpudvfs_pid" >> /cache/test_log.txt
	prepare_vcore_env
	/system/bin/vcorefs_p60 -i 0.001 -o 0 -o 3 -m 4 -c KIR_SYSFSX /sys/power/vcorefs/vcore_debug &
	vcorefs_pid=$!
	echo "s3 vcorefs_pid: $vcorefs_pid" >> /cache/test_log.txt

	echo "3.1 play 4k"
	echo "3.1 play 4k" >> /cache/test_log.txt
	am start -a android.intent.action.VIEW -t video/* -d /sdcard/google3_demo.webm
	/system/bin/stressapptest -s $s3 -M $MEM_CONF -m 2 -W --cc_test >> /cache/stressapptest.txt

	echo "3.2 play 4k"
	echo "3.2 play 4k" >> /cache/test_log.txt
	am start -a android.intent.action.VIEW -t video/* -d /sdcard/google3_demo.webm
	/system/bin/stressapptest -s $s3 -M $MEM_CONF -m 2 -W --cc_test >> /cache/stressapptest.txt

	echo "3.3 play 4k"
	echo "3.3 play 4k" >> /cache/test_log.txt
	am start -a android.intent.action.VIEW -t video/* -d /sdcard/google3_demo.webm
	/system/bin/stressapptest -s $s3 -M $MEM_CONF -m 2 -W --cc_test >> /cache/stressapptest.txt


	kill -9 $cpudvfs_pid
	kill -9 $vcorefs_pid

	echo "#3 stage end" >> /cache/test_log.txt
}

echo "" > /cache/test_log.txt
echo "" > /cache/stressapptest.txt
chmod 755 /cache/test_log.txt
chmod 755 /cache/stressapptest.txt

echo "DEBUG: $DEBUG" >> /cache/test_log.txt
#if [ $DEBUG -eq 1 ];then
#	echo "FAIL" >> /cache/stressapptest.txt
#fi
# set flight mode enable
echo "set flight mode enable"
echo "set flight mode enable" >> /cache/test_log.txt
settings put global airplane_mode_on 1
am broadcast -a android.intent.action.AIRPLANE_MODE
sleep 5

# drop big-cluster 5 * 6.25mv
echo "drop big-cluster 5 * 6.25mv"
echo "drop big-cluster 5 * 6.25mv" >> /cache/test_log.txt
echo "5" > /proc/eem/EEM_DET_L/eem_offset

#rem screen all on.
echo "screen all on."
#echo "set screen all on" >> /cache/test_log.txt
#settings put system screen_off_timeout 259200000
get_mem_config

stress_stage_1
stress_stage_2
#stress_stage_3

# set flight mode disable
echo "set flight mode disable"
echo "set flight mode disable" >> /cache/test_log.txt
settings put global airplane_mode_on 0
am broadcast -a android.intent.action.AIRPLANE_MODE
sleep 5

echo "test-finish" >> /cache/test_log.txt
echo "test-finish"
