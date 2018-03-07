#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

function get-set-forall() {
    for f in $1 ; do
        cat $f
        write $f $2
    done
}

# Read adj series and set adj threshold for PPR and ALMK.
# This is required since adj values change from framework to framework.
adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
adj_1="${adj_series#*,}"
set_almk_ppr_adj="${adj_1%%,*}"

# PPR and ALMK should not act on HOME adj and below.
# Normalized ADJ for HOME is 6. Hence multiply by 6
# ADJ score represented as INT in LMK params, actual score can be in decimal
# Hence add 6 considering a worst case of 0.9 conversion to INT (0.9*6).
set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift
echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj

# Memory
MemTotalStr=`cat /proc/meminfo | grep MemTotal`
MemTotal=${MemTotalStr:16:8}

if [ $MemTotal -gt 2000000 ]; then
    write /dev/kmsg "Memory 3GB"
    echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
    echo 10 > /sys/module/process_reclaim/parameters/pressure_min
    echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
    echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
    echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
else
    write /dev/kmsg "Memory 2GB"
    echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
    echo 10 > /sys/module/process_reclaim/parameters/pressure_min
    echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
    echo "14746,18432,22118,25805,40000,55000" > /sys/module/lowmemorykiller/parameters/minfree
    echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
fi
