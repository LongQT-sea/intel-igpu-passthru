## Overview
- OpROM/VBIOS for use with GVT-d iGPU passthrough on Proxmox/QEMU/KVM.
- Support direct UEFI display output over HDMI, eDP, DVI, and DisplayPort.
- Provides perfect display without screen distortion.
- Supports Windows, Linux, and even **macOS** guests.
- Fixes Code 43 errors in Windows guests with iGPU passthrough.
- Also compatible with SR-IOV virtual functions to fix Code 43 errors.[^1]

---

## Table of Contents
- [Requirements](#requirements)
- [Setup Instructions](#setup-instructions)
  - [1. ROM File Selection](#1-rom-file-selection)
  - [2. VM Configuration](#2-vm-configuration)
    - [Proxmox VE](#proxmox-ve)
      - [Legacy Mode](#legacy-mode)
      - [UPT Mode](#upt-mode)
    - [Other Linux Distributions (QEMU/KVM)](#other-linux-distributions-qemukvm)
- [Additional Resources & Documentation](#additional-resource-and-documentation)
- [Credits & Acknowledgments](#credits--acknowledgments)
- [Contributing](#contributing)
- [Attribution & License](#attribution--license)
- [Disclaimer](#disclaimer)

---

## Requirements
- Intel CPU with integrated graphics *(2nd gen and newer)*
- Mainboard with VT-d / IOMMU support *(must be enabled in BIOS)*
- **UEFI only boot mode** *(disable Legacy/CSM in BIOS/UEFI settings)*
- **Proxmox VE:**
  - Intel 2nd-10th Gen: Proxmox VE 7.4 or newer
  - Intel 11th Gen and newer: Proxmox VE 9.0 or newer
- **Linux Distros:** Modern Linux distributions with QEMU/KVM support
- **Host kernel:** with IOMMU enabled *(enabled by default on Proxmox VE 8.2 and newer)*

> [!IMPORTANT]
> Make sure **`disable_vga=1`** is not set anywhere in **`/etc/modprobe.d/vfio.conf`** or in your kernel parameters (**`/etc/default/grub`**) . If it is, remove it, then run `update-grub`, `update-initramfs -u` and reboot.

> [!IMPORTANT]
> **Meteor Lake**, **Arrow Lake**, **Lunar Lake** and future Intel iGPU require **QEMU 10.1.0** or newer (`kvm --version`)[^3]. As of October 2025, this requires Proxmox VE 9 [`Test` repository](https://pve.proxmox.com/wiki/Package_Repositories#sysadmin_test_repo).

> [!TIP]
> With **Proxmox VE 8.2** and newer, this works without following PCI passthrough guides such as [Proxmox PCI Passthrough](https://pve.proxmox.com/wiki/PCI_Passthrough).

> [!NOTE]
> **macOS** requires additional configuration: [macOS_README.md](https://github.com/LongQT-sea/intel-igpu-passthru/blob/main/macOS_README.md)

---

## Setup Instructions

### 1. ROM File Selection

Choose the appropriate ROM file for your Intel CPU and download/copy it to `/usr/share/kvm/`
* For example, if you have an i7-8700K (Coffee Lake CPU), right-click [`CFL_CML_GOPv9.1_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/CFL_CML_GOPv9.1_igd.rom) and select **“Copy link address”**
* Then, open the Proxmox VE shell and run the following command to save it as `igd.rom` in `/usr/share/kvm/`:
> Replace <ROM_URL> with the link you just copied
```bash
curl -L <ROM_URL> -o /usr/share/kvm/igd.rom
```

| Intel Generation | ROM File | GOP Version | Supported CPUs |
|------------------|----------|-------------|----------------|
| Sandy Bridge (2nd gen) | [`SNB_GOPv2_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/SNB_GOPv2_igd.rom) | v2 | Core i3/i5/i7 2xxx |
| Ivy Bridge (3rd gen) | [`IVB_GOPv3_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/IVB_GOPv3_igd.rom) | v3 | Core i3/i5/i7 3xxx |
| Haswell/Broadwell (4th/5th gen) | [`HSW_BDW_GOPv5_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/HSW_BDW_GOPv5_igd.rom) | v5 | Core i3/i5/i7 4xxx-5xxx |
| Skylake to Comet Lake (6/7/8/9/10th gen) | [`SKL_CML_GOPv9_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/SKL_CML_GOPv9_igd.rom) | v9 | Core i3/i5/i7/i9 6xxx-10xxx |
| Coffee/Comet Lake (8/9/10th gen) | [`CFL_CML_GOPv9.1_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/CFL_CML_GOPv9.1_igd.rom) | v9.1 | Core i3/i5/i7/i9 8xxx-10xxx |
| Gemini Lake (Low-end Pentium/Celeron) | [`GLK_GOPv13_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/GLK_GOPv13_igd.rom) | v13 | Pentium/Celeron J/N 4xxx/5xxx |
| Ice Lake (10th gen mobile) | [`ICL_GOPv14_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ICL_GOPv14_igd.rom) | v14 | Core i3/i5/i7 10xxG1/G4/G7 |
| Rocket/Tiger/Alder/Raptor Lake (11/12/13/14th gen) | [`RKL_TGL_ADL_RPL_GOPv17_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/RKL_TGL_ADL_RPL_GOPv17_igd.rom) | v17 | Core i3/i5/i7/i9 11xxx-14xxx |
| Rocket/Tiger/Alder/Raptor Lake (11/12/13/14th gen) | [`RKL_TGL_ADL_RPL_GOPv17.1_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/RKL_TGL_ADL_RPL_GOPv17.1_igd.rom) | v17.1 | Core i3/i5/i7/i9 11xxx-14xxx |
| Jasper Lake (Low-end Pentium/Celeron) | [`JSL_GOPv18_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/JSL_GOPv18_igd.rom) | v18 | Pentium/Celeron N 4xxx/5xxx/6xxx |
| Alder Lake-H/P/U / Raptor Lake-H/P/U (12/13/14th gen mobile) | [`ADL-H_RPL-H_GOPv21_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ADL-H_RPL-H_GOPv21_igd.rom) | v21 |  Core i3/i5/i7/i9 12xxx-14xxx H/P/U |
| Alder Lake-N / Twin Lake (N-series) | [`ADL-N_TWL_GOPv21_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ADL-N_TWL_GOPv21_igd.rom) | v21 |  N95/N97/N1xx/N2xx/N3xx |
| Arrow Lake / Meteor Lake | [`ARL_MTL_GOPv22_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ARL_MTL_GOPv22_igd.rom) | v22 | Core Ultra series |
| Lunar Lake | [`LNL_GOPv2X_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/LNL_GOPv2X_igd.rom) | (unknown) | Core Ultra series |
| All Gens - No UEFI GOP | [`Universal_noGOP_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/Universal_noGOP_igd.rom) | (none) | All Intel CPUs with iGPU[^2] |

> [!Note]
> Use [`Universal_noGOP_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/Universal_noGOP_igd.rom) as a last resort if other ROMs cause issues. This `Universal` ROM does not include the Intel GOP driver (UEFI Graphics Output Protocol), display output will only work after the guest VM drivers are fully loaded.

#### sha256sum: [Release page](https://github.com/LongQT-sea/intel-igpu-passthru/releases)

---

### 2. VM Configuration
### Proxmox VE

**Choose a mode:** This determines how display outputs (HDMI, eDP, DVI, DisplayPort) behave.

* **Legacy Mode:** Display output becomes active as soon as the VM starts.
* **UPT Mode:** Display output becomes active only after the guest OS drivers have loaded.

---

#### **Legacy Mode**

* Open Proxmox VE Shell and run:
> Replace `[VMID]` with your real VM ID.
```bash
qm set [VMID] --machine pc \
              --vga none \
              --bios ovmf \
              --hostpci0 0000:00:02.0,legacy-igd=1,romfile=igd.rom
```

> [!TIP]
> In legacy mode passthrough, these custom args are not needed:
>
> `-set device.hostpci0.bus=pci.0 -set device.hostpci0.addr=2.0 -set device.hostpci0.x-igd-gms=0x2 -set device.hostpci0.x-igd-opregion=on -set device.hostpci0.x-vga=on`

---

#### **UPT Mode**

* Open Proxmox VE Shell and run:
> Replace `[VMID]` with your real VM ID.
```bash
qm set [VMID] --machine q35 \
              --bios ovmf \
              --hostpci0 0000:00:02.0,romfile=igd.rom \
              --args "-set device.hostpci0.bus=pci.0 -set device.hostpci0.addr=2.0 -set device.hostpci0.x-igd-opregion=on"
```
> [!TIP]
> You should use [`Universal_noGOP_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/Universal_noGOP_igd.rom) in UPT mode.

---

### Other Linux Distributions (QEMU/KVM)

**QEMU Command Line args**:
- **Machine Type**: `-machine pc`
- **Display**: `-vga none`
- **Firmware**: `-bios /path/to/ovmf` or `-pflash /path/to/ovmf`
- **iGPU PCI device**: 
```
-device vfio-pci,host=0000:00:02.0,id=hostpci0,bus=pci.0,addr=0x2,romfile=/path/to/rom/file
```

---

## Additional Resource and Documentation

- [QEMU IGD assignment documentation](https://github.com/qemu/qemu/blob/master/docs/igd-assign.txt)
- [Intel EDK2 GVT-d patchset (from eci.intel.com)](https://eci.intel.com/docs/3.3/components/kvm-hypervisor.html#build-ovmf-fd-for-kvm)
- [Intel GVT-d Documentation](https://github.com/intel/gvt-linux/wiki)

## Credits & Acknowledgments

### Source Code Authors
Based on [EDK2 patches](https://eci.intel.com/docs/3.3/components/kvm-hypervisor.html#build-ovmf-fd-for-kvm) authored by:
* **Colin Xu** (colin.xu@intel.com) & **Laszlo Ersek** (lersek@redhat.com) — *IgdAssignmentDxe implementation*
* **Colin Xu** (colin.xu@intel.com) — *Platform GOP Policy, OpRegion 2.1 support*
* **Xiong Zhang** (xiong.y.zhang@intel.com) — *VBT data handling*

### Special Thanks
- [Tomita Moeko](https://github.com/tomitamoeko) for [DXE drivers supporting VFIO IGD passthrough](https://github.com/tomitamoeko/VfioIgdPkg)
- [Alex Williamson](https://github.com/awilliam) for [IGD assignment support in QEMU](https://github.com/qemu/qemu/blob/master/hw/vfio/igd.c)
- The **QEMU/KVM Community** for [IGD assignment documentation](https://github.com/qemu/qemu/blob/master/docs/igd-assign.txt)
- All community members who tested and provided feedback

## Contributing

Contributions are welcome! Please:
1. Test configurations thoroughly
2. Report issues with detailed system information

## Attribution & License

This project is licensed under the BSD 2-Clause License (see [LICENSE](LICENSE) file).

**If you create content using this project** (videos, blog posts, tutorials, articles):
- Please link back to this repository: `https://github.com/LongQT-sea/intel-igpu-passthru`
- Mention that detailed **requirements** and **instructions** are in this GitHub repo.

Thank you for respecting the work that went into this project!

## Disclaimer

This project is provided “as‑is”, without any warranty, for educational and research purposes. In no event shall the authors or contributors be liable for any direct, indirect, incidental, special, or consequential damages arising from use of the project, even if advised of the possibility of such damages.

All product names, trademarks, and registered trademarks are property of their respective owners. All company, product, and service names used in this repository are for identification purposes only.

[^1]: When using Intel iGPU SR-IOV virtual functions, some driver versions may cause a Code 43 error on Windows guests. To ensure compatibility across all driver versions, an OpROM is required.
[^2]: Sandy Bridge and newer. Use `Universal_noGOP_igd.rom` as a last resort if other ROMs cause issues. This `Universal` ROM does not include the Intel GOP driver (UEFI Graphics Output Protocol), so display output will only work after the guest VM drivers are loaded.
[^3]: You will get this error message on Meteor Lake and newer: `IGD device 0000:00:02.0 is unsupported in legacy mode, try SandyBridge or newer`. This is fixed in QEMU 10.1.x ([git commit](https://github.com/qemu/qemu/commit/7969cf4639794e0af84862a269daac72adcfb554)).
