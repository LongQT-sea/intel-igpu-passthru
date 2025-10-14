## 🎯 Overview
- OpROM/VBIOS for use with GVT-d iGPU passthrough on Proxmox/QEMU/KVM.
- Support direct UEFI output over HDMI, eDP, and DisplayPort.
- Provides perfect display without screen distortion.
- Supports Windows, Linux, and even **macOS** guests.
- This ROM can also be used with SR-IOV virtual functions on compatible Intel iGPUs to fix Code 43.[^1]

## 📋 Requirements
- Intel CPU with integrated graphics (2nd gen and newer)
- Mainboard with VT-d/IOMMU support
- **Proxmox VE** 8.0 and newer
- **Linux Distros**: 2022+ Debian, Fedora, Arch based Linux distro with QEMU/KVM
- **Host kernel** with IOMMU enabled (IOMMU is enabled by default on Proxmox VE 8.2 and newer)

> [!IMPORTANT]
> Make sure **`disable_vga=1`** is not set anywhere in **`/etc/modprobe.d/vfio.conf`** or in your kernel parameters (**`/etc/default/grub`**) . If it is, remove it, update grub, initramfs and reboot.

> [!TIP]
> With Proxmox VE 8.2 and newer, this will work without going through PCI passthrough guides such as [Proxmox PCI Passthrough](https://pve.proxmox.com/wiki/PCI_Passthrough)

> [!NOTE]
> **macOS** requires additional configuration: [macOS_README.md](https://github.com/LongQT-sea/intel-igpu-passthru/blob/main/macOS_README.md)

---

## 🛠️ Setup Instructions

### 1. ROM File Selection

Choose the appropriate ROM file for your Intel CPU and download/copy it to `/usr/share/kvm/`
* For example, if you have an i7-8700K (Coffee Lake CPU), right-click `CFL_CML_GOPv9.1_igd.rom` and select **“Copy link address.”**
* Then, open the Proxmox VE shell and run this command to save it as `igd.rom` in `/usr/share/kvm/`:
> Replace <ROM_URL> with the link you just copy
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
| Alder/Twin Lake N-series processors | [`ADL-N_TWL_GOPv21_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ADL-N_TWL_GOPv21_igd.rom) | v21 |  N97/N1xx/N2xx/N3xx |
| Arrow/Meteor Lake | [`ARL_MTL_GOPv22_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ARL_MTL_GOPv22_igd.rom) | v22 | Core Ultra series |
| Lunar Lake | [`LNL_GOPv2X.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/LNL_GOPv2X.rom) | (unknown) | Core Ultra series |
| All Gens - No UEFI display output | [`Universal_noGOP_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/Universal_noGOP_igd.rom) | (none) | All Intel CPUs with iGPU[^2] |

> [!Note]
> `Universal_noGOP_igd.rom` does not include Intel GOP driver (UEFI Graphics Output Protocol), so the display output will only work after the guest VM drivers are properly loaded.

#### sha256sum: [Release page](https://github.com/LongQT-sea/intel-igpu-passthru/releases)

---

### 2. VM Configuration

### 🖥️ Proxmox VE
- **Machine Type**: `i440fx` (REQUIRED for legacy mode)
- **Display**: `none` (REQUIRED for legacy mode)
- **BIOS**: UEFI/OVMF
- **PCI device**: Open Proxmox VE Shell and run:
> Replace `[VMID]` with your real VM ID.
```
qm set [VMID] -hostpci0 0000:00:02.0,legacy-igd=1,romfile=igd.rom
```

Example Configuration for Skylake to Comet Lake:
- `/etc/pve/qemu-server/[VMID].conf`:
```
machine: pc
vga: none
bios: ovmf
hostpci0: 0000:00:02.0,legacy-igd=1,romfile=SKL_CML_GOPv9_igd.rom
```

> [!TIP]
> In legacy mode passthrough, these custom args are not needed:
>
> `-set device.hostpci0.bus=pci.0 -set device.hostpci0.addr=02.0 -set device.hostpci0.x-igd-gms=0x2 -set device.hostpci0.x-igd-opregion=on`

---

### 🐧 Other Linux Distributions (QEMU/KVM)

**QEMU Command Line args**:
- **Machine Type**: `-machine pc`
- **Display**: `-vga none`
- **Firmware**: `-bios /path/to/ovmf` or `-pflash /path/to/ovmf`
- **iGPU PCI device**: 
```
-device vfio-pci,host=0000:00:02.0,id=hostpci0,bus=pci.0,addr=0x2,romfile=/path/to/rom/file
```

---

## 📚 Additional Resource and Documentation

- [DXE drivers supporting VFIO IGD passthrough](https://github.com/tomitamoeko/VfioIgdPkg)
- [QEMU igd-assign.txt](https://github.com/qemu/qemu/blob/master/docs/igd-assign.txt)
- [Intel GVT-d Documentation](https://github.com/intel/gvt-linux/wiki)

## 🤝 Contributing

Contributions are welcome! Please:
1. Test configurations thoroughly
2. Add new ROM files with proper documentation
3. Report issues with detailed system information

## ⚠️ Disclaimer

This project is provided “as‑is”, without any warranty, for educational and research purposes. In no event shall the authors or contributors be liable for any direct, indirect, incidental, special, or consequential damages arising from use of the project, even if advised of the possibility of such damages.

All product names, trademarks, and registered trademarks are property of their respective owners. All company, product, and service names used in this repository are for identification purposes only.

[^1]: When using Intel iGPU SR-IOV virtual functions, some driver versions may cause a Code 43 error on Windows guests. To ensure compatibility across all driver versions, an OpROM is required.
[^2]: Sandy Bridge and newer, `Universal_noGOP_igd.rom` does not include Intel GOP driver (UEFI Graphics Output Protocol), so the display output will only work after the guest VM drivers are properly loaded.
