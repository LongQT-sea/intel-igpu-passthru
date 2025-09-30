# Intel iGPU Full Passthrough guide for Proxmox/QEMU/KVM
## 🎯 Overview

This repository provides ROM/VBIOS images for QEMU/KVM use. It enables full Intel iGPU passthrough to a guest VM using the legacy‑mode Intel Graphics Device (IGD) assignment via vfio‑pci. In effect, it gives a single VM complete, dedicated iGPU access, with direct UEFI output over HDMI, eDP, and DisplayPort monitor output support.

It can also be used with SR-IOV on 11th gen+ Intel iGPUs to fix error code 43.

## 📋 Requirements

- Intel CPU with integrated graphics (3rd gen and newer)
- Mobo with VT-d/IOMMU support
- **Proxmox VE**: 8.0+
- **Linux Distros**: 2022+ Debian, Fedora, Arch based Linux distro with QEMU/KVM
- **Host kernel** IOMMU and VFIO enabled

## 🛠️ Setup Instructions

### ROM File Selection

Choose the appropriate ROM file for your Intel CPU and download/copy in to `/usr/share/kvm/`:
```
scp rom_file_name.rom root@proxmox-IP:/usr/share/kvm/
or:
curl -L https://rom_url -o /usr/share/kvm/rom_file_name.rom
```

| Intel Generation | ROM File | GOP Version | Supported CPUs |
|------------------|----------|-------------|----------------|
| Sandy Bridge (2nd gen) | [`SNB_GOPv2_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/SNB_GOPv2_igd.rom) | v2 | Core i3/i5/i7 2xxx |
| Ivy Bridge (3rd gen) | [`IVB_GOPv3_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/IVB_GOPv3_igd.rom) | v3 | Core i3/i5/i7 3xxx |
| Haswell/Broadwell (4th/5th gen) | [`HSW_BDW_GOPv5_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/HSW_BDW_GOPv5_igd.rom) | v5 | Core i3/i5/i7 4xxx-5xxx |
| Skylake to Comet Lake (6/7/8/9/10th gen) | [`SKL_CML_GOPv9_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/SKL_CML_GOPv9_igd.rom) | v9 | Core i3/i5/i7/i9 6xxx-10xxx |
| Coffee/Comet Lake (8/9/10th gen) | [`CFL_CML_GOPv9.1_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/CFL_CML_GOPv9.1_igd.rom) | v9.1 | Core i3/i5/i7/i9 8xxx-10xxx |
| Gemini Lake (Low-end Pentium/Celeron) | [`GLK_GOPv13_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/GLK_GOPv13_igd.rom) | v13 | Pentium/Celeron J/N 4xxx/5xxx |
| Ice Lake (10th gen mobile) | [`ICL_GOPv14_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ICL_GOPv14_igd.rom) | v14 | Core i3/i5/i7 10xxG1/4/7 |
| Rocket/Tiger/Alder/Raptor Lake (11/12/13/14th gen) | [`RKL_TGL_ADL_RPL_GOPv17_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/RKL_TGL_ADL_RPL_GOPv17_igd.rom) | v17 | Core i3/i5/i7/i9 11xx-14xxx |
| Rocket/Tiger/Alder/Raptor Lake (11/12/13/14th gen) | [`RKL_TGL_ADL_RPL_GOPv17.1_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/RKL_TGL_ADL_RPL_GOPv17.1_igd.rom) | v17.1 | Core i3/i5/i7/i9 11xx-14xxx |
| Alder/Twin Lake N-series processors | [`ADL-N_TWL_GOPv21_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ADL-N_TWL_GOPv21_igd.rom) | v21 |  N97/N1xx/N2xx/N3xx |
| Arrow/Meteor Lake | [`ARL_MTL_GOPv22_igd.rom`](https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/ARL_MTL_GOPv22_igd.rom) | v22 | Core Ultra series |
| Lunar Lake | `(unknown)` | (unknown) | Core Ultra series |

#### sha256sum: [Release page](https://github.com/LongQT-sea/intel-igpu-passthru/releases)

## 🖥️ Proxmox VE

### VM Configuration Requirements

**VM Settings:**
- **Machine Type**: `i440fx` (REQUIRED for legacy mode, Q35 could work, but there's no UEFI GOP display output)
- **Display**: `none` (REQUIRED for legacy mode)
- **BIOS**: UEFI/OVMF
- **PCI device**: open Proxmox VE Shell and run:
```
qm set VMID -hostpci0 0000:00:02.0,legacy-igd=1,romfile=rom_file_name.rom
```

#### Example Configuration for Skylake to Comet Lake:
Edit `/etc/pve/qemu-server/[VMID].conf`:

```
machine: pc
vga: none
bios: ovmf
hostpci0: 0000:00:02.0,legacy-igd=1,romfile=SKL_CML_GOPv9_igd.rom
```

## 🐧 Other Linux Distributions (QEMU/KVM)

### QEMU Command Line args
- **Machine Type**: `-machine pc`
- **Display**: `-vga none `
- **Firmware**: `-bios /path/to/ovmf` or `-pflash /path/to/ovmf`
- **iGPU PCI device**: 
```
-device vfio-pci,host=0000:00:02.0,id=hostpci0,bus=pci.0,addr=0x2,romfile=/path/to/rom/file
```

### Supported Guest Operating Systems
- ✅ Windows
- ✅ Linux
- ✅ macOS

## 📚 Additional Resource and Documentation

- [DXE drivers supporting VFIO IGD passthrough](https://github.com/tomitamoeko/VfioIgdPkg)
- [QEMU igd-assign.txt](https://github.com/qemu/qemu/blob/master/docs/igd-assign.txt)
- [Proxmox VE GPU Passthrough Guide](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [Intel GVT-d Documentation](https://github.com/intel/gvt-linux/wiki)

## 🤝 Contributing

Contributions are welcome! Please:
1. Test configurations thoroughly
2. Add new ROM files with proper documentation
3. Report issues with detailed system information

## ⚠️ Disclaimer

This project is provided “as‑is”, without any warranty, for educational and research purposes. In no event shall the authors or contributors be liable for any direct, indirect, incidental, special, or consequential damages arising from use of the project, even if advised of the possibility of such damages.

All product names, trademarks, and registered trademarks are property of their respective owners. All company, product, and service names used in this repository are for identification purposes only.
