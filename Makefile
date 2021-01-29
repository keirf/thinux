
.PHONY: preqreq dnsmasq u-boot u-boot-sd u-boot-spi-flash
.PHONY: armbian-to-network-boot
.PHONY: clean mrproper

prereq:
	sudo apt install -y swig gcc-arm-linux-gnueabihf # U-Boot
	sudo apt install -y dnsmasq nfs-common nfs-server

# Brings up my USB-Ethernet adapter under control of dnsmasq
ifup:
	sudo ifconfig enx00e04c534458 10.0.0.1 netmask 255.255.255.0 up

# Refreshes DNSMasq and PXE configs
dnsmasq:
	sudo cp dnsmasq/test.conf /etc/dnsmasq.d/.
	sudo service dnsmasq restart
	mkdir -p ~/tftpd/pxelinux.cfg
	cp pxelinux.cfg/* ~/tftpd/pxelinux.cfg

# Pulls and builds U-Boot for Orange Pi Zero
# NB v2021.01 network is broken, so we check out v2020.10
u-boot:
	[ -d u-boot ] || git clone -b v2020.10 https://github.com/u-boot/u-boot
	make -C u-boot mrproper
	make -C u-boot orangepi_zero_defconfig
	make -C u-boot -j16 CROSS_COMPILE=arm-linux-gnueabihf-

# Do this after changing /etc/exports
# Example line in /etc/exports:
## /opt/nfs 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)
nfs-refresh:
	sudo exportfs -ra

# (Optional) Only if installing PXE loader on SD card
# Useful for testing the loader
u-boot-sd:
	sudo fdisk /dev/sdc # Create two partitions, first is mkfs.vfat
	sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sdc bs=1024 seek=8


# These steps run on the device on Armbian as root
# Add following lines to /boot/armbianEnv.txt
# More about overlays can be found in /boot/dtb/overlay/README.sun8i-h3-overlays
## overlays=spi-spidev
## param_spidev_spi_bus=0
u-boot-spi-flash:
	apt install -y flashrom
	dd if=/dev/zero count=2048 bs=1K | tr '\000' '\377' >spi.img
	dd if=u-boot-sunxi-with-spl.bin of=spi.img bs=1k conv=notrunc
	flashrom -p linux_spi:dev=/dev/spidev0.0 -c MX25L1605 -w spi.img

# Copies the Armbian SD install to NFS mount and TFTP dir for network boot.
# This is just an example, as this is hardly minimal.
armbian-to-network-boot:
	mkdir -p ~/tftpd
	cp -r /mnt/boot/* ~/tftpd/
	sudo mkdir -p /opt/nfs/OrangePiRoot
	sudo rsync -a /mnt/ /opt/nfs/OrangePiRoot/

clean:
	make -C u-boot mrproper

mrproper:
	$(RM) u-boot
