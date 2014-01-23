#elementary OS device profile for the Acer C720 Chromebook

#Devices hardware
system_drive="/dev/sda"
system_partition="${system_drive}7"

#Specify the swap file size in MB
swap_file_size="2048"

#Define additional PPA and packages to install

#Kernel package(s) to install
#Add kernel ppa for this device (Not available yet)
#additional_kernel_ppa=""
#Add kernel packages from a PPA (Not available yet)
#kernel_ppa_pkgs=""

#Add kernel packages from URL
kernel_url_pkgs="http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.12.5-trusty/linux-headers-3.12.5-031205-generic_3.12.5-031205.201312120254_amd64.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.12.5-trusty/linux-headers-3.12.5-031205_3.12.5-031205.201312120254_all.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.12.5-trusty/linux-image-3.12.5-031205-generic_3.12.5-031205.201312120254_amd64.deb"

#Additional repository(ies) and package(s) to install
#Add additional PPA (Not available yet)
#additional_ppa=""

#Add packages from a PPA
ppa_pkgs="xserver-xorg-lts-raring xbindkeys xdotool xbacklight"
