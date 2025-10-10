#!/bin/bash
# Copyright (c) 2024-2025, LongQT-sea

#####################################################
# Purpose: Automatically unbind vfio driver and rebind host driver on the iGPU and USB PCI device
# Location: /var/lib/vz/snippets/pve_rebind_pci.sh
# Usage: qm set [VMID] --hookscript local:snippets/pve_rebind_pci.sh
#####################################################

#set -x  # Uncomment to enable debugging output

#####################################################
# Start Configuration Section
#####################################################

# PCI device addresses (use 'lspci -nn' to find your devices)
IGPU_ADDR="0000:00:02.0"    # Intel iGPU
USB_ADDR="0000:00:14.0"     # Intel USB3 controller

# Set to "true" to enable SR-IOV Virtual Functions on iGPU after rebind it to i915 driver
# Set to "false" to disable SR-IOV
ENABLE_SRIOV="false"

# Number of SR-IOV Virtual Functions to create (typically 1-7 for Intel iGPU)
SRIOV_VF_COUNT="7"

#####################################################
# End Configuration Section
#####################################################



#####################################################
# Script Parameters (passed by Proxmox)
#####################################################

VMID="$1"           # Virtual Machine ID
shift
PHASE="$1"          # Lifecycle phase (pre-start, post-start, pre-stop, post-stop)

# Timeout for each driver binding/unbinding operation (in seconds)
TIMEOUT=5

#####################################################
# Post-Stop Phase: Return devices to host
#####################################################
# This runs after the VM has been stopped, returning
# PCI devices from vfio-pci back to their host drivers

if [ "$PHASE" = "post-stop" ]; then
    # Brief delay to ensure VM has fully released devices
    sleep 2

    #################################################
    # iGPU Management
    #################################################
    
    # Unbind iGPU from vfio-pci (VM passthrough driver)
    counter=0
    while [ -d /sys/bus/pci/drivers/vfio-pci/${IGPU_ADDR} ] && [ $counter -lt $TIMEOUT ]; do
        echo ${IGPU_ADDR} > /sys/bus/pci/drivers/vfio-pci/unbind 2>&1
        sleep 1
        counter=$((counter + 1))
    done

    # Bind iGPU to i915 (Intel host graphics driver)
    counter=0
    while [ ! -d /sys/bus/pci/drivers/i915/${IGPU_ADDR} ] && [ $counter -lt $TIMEOUT ]; do
        echo ${IGPU_ADDR} > /sys/bus/pci/drivers/i915/bind 2>&1
        sleep 1
        counter=$((counter + 1))
    done

    # Enable SR-IOV Virtual Functions (if configured)
    # SR-IOV allows splitting one physical GPU into multiple virtual GPUs
    if [ "$ENABLE_SRIOV" = "true" ]; then
        counter=0
        while [ -d /sys/bus/pci/drivers/i915/${IGPU_ADDR} ] && [ $counter -lt $TIMEOUT ]; do
            echo "${SRIOV_VF_COUNT}" > /sys/bus/pci/devices/${IGPU_ADDR}/sriov_numvfs 2>&1
            sleep 1
            counter=$((counter + 1))
        done
    fi

    #################################################
    # USB Controller Management
    #################################################
    
    # Unbind USB controller from vfio-pci (VM passthrough driver)
    counter=0
    while [ -d /sys/bus/pci/drivers/vfio-pci/${USB_ADDR} ] && [ $counter -lt $TIMEOUT ]; do
        echo ${USB_ADDR} > /sys/bus/pci/drivers/vfio-pci/unbind 2>&1
        sleep 1
        counter=$((counter + 1))
    done

    # Bind USB controller to xhci_hcd (USB 3.0 host driver)
    counter=0
    while [ ! -d /sys/bus/pci/drivers/xhci_hcd/${USB_ADDR} ] && [ $counter -lt $TIMEOUT ]; do
        echo ${USB_ADDR} > /sys/bus/pci/drivers/xhci_hcd/bind 2>&1
        sleep 1
        counter=$((counter + 1))
    done
fi

#####################################################
# Exit Status
#####################################################
# Return success to Proxmox
exit 0