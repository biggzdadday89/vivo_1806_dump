#!/system/bin/sh

function setleakType(){
    echo "setleakType"
    socket=`ls -l /proc/$pid/fd | grep socket | wc -l`
    pipe=`ls -l /proc/$pid/fd | grep pipe | wc -l`
    ashmem=`ls -l /proc/$pid/fd | grep ashmem | wc -l`
    anon_inode=`ls -l /proc/$pid/fd | grep anon_inode | wc -l`
    other=`expr $fdsum - $socket - $pipe - $ashmem - $anon_inode`
    echo "socket:"$socket"===pipe:"$pipe"===ashmem:"$ashmem"===anon_inode:"$anon_inode"===other:"$other
    types=($socket $pipe $ashmem $anon_inode $other);
    echo "setleakType"
    for I in ${!types[@]};do
        if [[ ${MAX} -le ${types[${I}]} ]];then
            MAX=${types[${I}]}
        fi
    done
    echo "setleakType"
    echo ${MAX}
    if [ "$socket" -eq "$MAX" ];then
        echo "type socket"
        `setprop epm.fd.leak.type 2`
    elif [ "$pipe" -eq "$MAX" ];then
        echo "type pipe"
        `setprop epm.fd.leak.type 3`
    elif [ "$ashmem" -eq "$MAX" ];then
        echo "type ashmem"
        `setprop epm.fd.leak.type 5`
    elif [ "$anon_inode" -eq "$MAX" ];then
        echo "type anon_inode"
        `setprop epm.fd.leak.type 6`
    elif [ "$other" -eq "$MAX" ];then
        echo "type other"
        `setprop epm.fd.leak.type 1`
    fi
}

`setprop epm.fd.leak 3`
pid=`getprop epm.fd.leak.pid`
#echo "pid:"$pid
leaklimit=`getprop epm.fd.leak.limit`
if [ $leaklimit -le "600" ];then
  leaklimit=1024
fi
#echo "limit:"$leaklimit
fdsum=`ls /proc/$pid/fd | wc -l`
#echo "fdsum:"$fdsum

if [ "$fdsum" -ge "$leaklimit" ]; then
#    echo "pid:"$pid" fdleak!!!"
    #setleakType
    `setprop epm.fd.leak 1`
else
#    echo "pid:"$pid" run normal"
    `setprop epm.fd.leak 0`
fi

