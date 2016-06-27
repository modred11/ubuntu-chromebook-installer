#!/bin/bash
#ChromeOS - Ubuntu install script for Chromebooks

#Variables definition
#Script variables
current_dir="$(dirname $BASH_SOURCE)"
verbose=0
kubuntu_toggle=0
xubuntu_toggle=0

unsquash_bin="/tmp/ramdir/unsquashfs"
unsquash_source="./bin/unsquashfs"

#Script global directory variables
log_file="ubuntu-install.log"
log_dir="$current_dir/logs/"
tmp_dir="$current_dir/tmp/"
conf_dir="$current_dir/conf.d/"
profiles_dir="$current_dir/profiles/"
devices_dir="$profiles_dir/devices/"
scripts_dir="$current_dir/scripts/"
web_dl_dir="$tmp_dir/web_dl/"

#Default profile
default_profile_file="default.profile"
default_profile_dir="$profiles_dir/default/"
default_sys_dir="$default_profile_dir/system/"
default_scripts_dir="$default_profile_dir/scripts/"

#User profile
user_profile_file="user.profile"
user_profile_dir="$profiles_dir/user/"
user_sys_dir="$user_profile_dir/user/system/"
user_scripts_dir="$user_profile_dir/scripts/"

#Device specific variables
device_profile="none"
dev_profile_file="device.profile"

#External depenencies variables
#ChrUbuntu configuration file
chrubuntu_script="$scripts_dir/chrubuntu-chromeeos.sh"
chrubuntu_runonce="$tmp_dir/chrubuntu_runonce"
system_chroot="/tmp/urfs/"

#distro specific requirements
eos_sys_archive_url="http://cdimage.ubuntu.com/releases/trusty/release/ubuntu-14.04.1-desktop-amd64+mac.iso"
eos_sys_archive="$tmp_dir/ubuntu-14.04.1-desktop-amd64+mac.iso"
eos_sys_archive_md5="08a56c68e3681a6f4ae128810f6359d7"

#kubuntu disto
kub_sys_archive_url="http://cdimage.ubuntu.com/kubuntu/releases/14.04/release/kubuntu-14.04.1-desktop-amd64.iso"
kub_sys_archive="$tmp_dir/kubuntu-14.04.1-desktop-amd64.iso"
kub_sys_archive_md5="d1eabbb0060ad45c1172877c726f0a5a"

#xubuntu disto
xub_sys_archive_url="http://cdimage.ubuntu.com/xubuntu/releases/14.04/release/xubuntu-14.04.1-desktop-amd64.iso"
xub_sys_archive="$tmp_dir/xubuntu-14.04.1-desktop-amd64.iso"
xub_sys_archive_md5="8b06ac9d76186721312c17a851801e2e"

#Functions definition
usage(){
cat << EOF
usage: $0 [ OPTIONS ] [ DEVICE_PROFILE | ACTION ]

ChromeOS - Ubuntu installation script for Chromebooks

    OPTIONS:
    -h      Show help
    -v      Enable verbose mode
    -k	    Use Kubuntu instead of Ubuntu
    -x	    Use Xubuntu instead of Ubuntu

    DEVICE_PROFILE:
        The device profile to load for your Chromebook

    ACTIONS:
        list    List all the elements for this option (ex: List all devices profile supported)
        search  Search for your critera in all devices profile
EOF
}

debug_msg(){
    debug_level="$1"
    msg="$2"
    case $debug_level in
        INFO)
            echo -e "\E[1;32m$msg"
            echo -e '\e[0m'
            ;;
        WARNING)
            echo -e "\E[1;33m$msg"
            echo -e '\e[0m'
            ;;
        ERROR)
            echo -e "\E[1;31m$msg"
            echo -e '\e[0m'
            ;;
        *)
            echo "$msg"
            echo -e '\e[0m'
            ;;
    esac
}

log_msg(){
    if [ -e "$log_dir" ];then
        debug_level="$1"
        msg="$2"
        log_format="$(date +%Y-%m-%dT%H:%M:%S) $debug_level $msg"
        echo "$log_format" >> "$log_dir/$log_file"
        if [ "$debug_level" != "COMMAND" ];then
          debug_msg "$debug_level" "$msg"
        fi
    else
        debug_msg "ERROR" "Log directory $log_dir does not exist...exiting"
        exit 1
    fi
}

run_command(){
    command="$1"
    log_msg "COMMAND" "$command"
    cmd_output=$($command 2>&1)
    if [ "$cmd_output" != "" ];then
        log_msg "COMMAND" "output: $cmd_output"
    fi
}

run_command_chroot(){
  command="$1"
  log_msg "COMMAND" "$command"
  cmd_output=$(sudo chroot $system_chroot /bin/bash -c "$command" 2>&1)
  if [ "$cmd_output" != "" ];then
    log_msg "COMMAND" "output: $cmd_output"
  fi
}

#Get command line arguments
#Required arguments

#Optional arguments
while getopts "hvkx" option; do
    case $option in
        h)
            usage
            exit 1
            ;;
        v)
            verbose=1
            ;;
        k)
            kubuntu_toggle=1
            ;;
        x)
            xubuntu_toggle=1
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done

device_model="${BASH_ARGV[0]}"
device_search="${BASH_ARGV[1]}"

if [ "$device_model" == "search" ];then
    debug_msg "WARNING" "No search critera entered for device profile search...exiting"
    usage
    exit 1
fi

if [ "$device_search" == "search" ];then
    search_result=$(/bin/bash $0 list | tail -n +3 | grep -i "$device_model")
    if [ -z "$search_result" ] || [ "$search_result" == "" ];then
        debug_msg "WARNING" "No device profile found with search critera \"$device_model\""
    else
        debug_msg "INFO" "List of device profile matching search critera \"$device_model\""
        echo $search_result
    fi
    exit 1
fi

#Validate device model
case "$device_model" in
    list)
        debug_msg "INFO" "List of device profiles for supported devices..."
        for i in $(cd $devices_dir; ls -d */); do echo "- ${i%%/}"; done
        exit 0
        ;;
    *)
        device_profile="$devices_dir/$device_model/$dev_profile_file"
        device_profile_dir="$devices_dir/$device_model/"
        device_scripts_dir="$device_profile_dir/scripts/"
        device_sys_dir="$device_profile_dir/system/"
        if [ -z "$device_model" ]; then
            debug_msg "WARNING" "Device not specified...exiting"
            usage
            exit 1
        elif [ ! -e "$device_profile" ];then
            debug_msg "WARNING" "Device '$device_model' profile does not exist...exiting"
            usage
            exit 1
        fi
        ;;
esac

debug_msg "INFO" "ChromeOS - (k)ubuntu installation script for Chromebooks by eyecreate on github. Derived from Setsuna666/elementaryos-chromebook"
#Creating log files directory before using the log_msg function
if [ ! -e "$log_dir" ]; then
    mkdir $log_dir
fi

device_hwid=$(crossystem hwid)
log_msg "INFO" "Device model is $device_model"
log_msg "INFO" "Device hardware ID is $device_hwid"

if [ ! -e "$tmp_dir" ]; then
    log_msg "INFO" "Creating and downloading dependencies..."
    run_command "mkdir $tmp_dir"
fi

if [ ! -e "$chrubuntu_runonce" ]; then
    log_msg "INFO" "Running ChrUbuntu to setup partitioning..."
    sudo bash $chrubuntu_script
    log_msg "INFO" "ChrUbuntu execution complete..."
    log_msg "INFO" "System will reboot in 10 seconds..."
    touch $chrubuntu_runonce
    sleep 10
    sudo reboot
    exit 0
else
    log_msg "INFO" "ChrUbuntu partitioning already done...skipping"
    log_msg "INFO" "Running ChrUbuntu to finish the formating process..."
    sudo bash $chrubuntu_script
fi

log_msg "INFO" "Importing device $device_model profile..."
. $device_profile

#Validating that required variables are defined in the device profile
if [ -z "$system_drive" ];then
    log_msg "ERROR" "System drive (system_drive) variable not defined in device profile $device_profile...exiting"
    exit 1
fi

if [ -z "$system_partition" ];then
    log_msg "ERROR" "System partition (system_partition) variable not defined in device profile $device_profile...exiting"
    exit 1
fi

#Verify if the swap file option in specified in the device profile
if [ -z "$swap_file_size" ];then
    log_msg "ERROR" "Swap file size (swap_file_size) variable is not defined in device profile $device_profile...exiting"
    exit 1
fi

if [ ! -e "$system_drive" ];then
    log_msg "ERROR" "System drive $system_drive does not exist...exiting"
    exit 1
fi

if [ ! -e "$system_partition" ];then
    log_msg "ERROR" "System drive $system_partition does not exist...exiting"
    exit 1
fi
run_command "mkdir /tmp/isomnt"
run_command "mkdir /tmp/ramdir"
#make a new mount point that is not tainted by noexec
run_command "sudo mount -t tmpfs -o size=50M tmpfs /tmp/ramdir"
run_command "cp $unsquash_source $unsquash_bin"
run_command "chmod +x $unsquash_bin"
