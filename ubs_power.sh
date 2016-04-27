#!/bin/bash
###############################################################
# It will power on/off a usb device based in its serial number
###############################################################
if [[ $2 == "" ]]; then
	echo "Usage: $0 [on|off] SERIAL_NUMBER"
	exit;
fi
USB_DEV=$(dmesg | grep -o "usb .*: SerialNumber: $2" | tail -n 1 | awk '{print $2}' | sed 's/://')
if [[ $USB_DEV == "" ]]; then
	echo "Device not found";
	exit;
fi
if [[ $1 == "on" ]]; then
	echo "2000" > /sys/bus/usb/devices/$USB_DEV/power/autosuspend_delay_ms 
	echo "on" > /sys/bus/usb/devices/$USB_DEV/power/control 
elif [[ $1 == "off" ]]; then
	echo "0" > /sys/bus/usb/devices/$USB_DEV/power/autosuspend_delay_ms 
	echo "auto" > /sys/bus/usb/devices/$USB_DEV/power/control 
else
	echo "Unknown action: $1"
	exit;
fi
