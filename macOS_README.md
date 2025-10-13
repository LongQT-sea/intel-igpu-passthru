## Note for using iGPU passthrough with a macOS VM
> [!Important]
> * Make sure you have a supported iGPU. See [Dortania Intel iGPU Guide](https://dortania.github.io/GPU-Buyers-Guide/modern-gpus/intel-gpu.html).  
> * This is a reference document — you may need to adapt it based on your iGPU device ID.

### 1. Check your iGPU device ID
- Open Proxmox VE shell and run:
   ```bash
   lspci -nn -s 00:02.0
   ````

- Example output:
   ```
   00:02.0 VGA compatible controller [0300]: Intel Corporation CoffeeLake-H GT2 [UHD Graphics 630] [8086:3e9b] (rev 02)
   ```
   In this example, the Coffee Lake iGPU has a device ID of **`0x3e9b`**

---

### 2. Check WhateverGreen documentation
Go to the Coffee Lake (or whatever Lake you have) section in [WhateverGreen/Manual/FAQ.IntelHD.en.md](https://github.com/acidanthera/WhateverGreen/blob/master/Manual/FAQ.IntelHD.en.md) and look for your device ID:

* If your iGPU device ID appears under ***Native supported DevIDs*** and ***Recommended framebuffers***, great — continue to the [**CPU Models**](#4-cpu-models) section.
* If it's **not** listed, you'll need to spoof your iGPU's device ID to a natively supported one.

---

### 3. Spoofing iGPU device ID

- **Proxmox VE:**
   ```
   qm set [VMID] -hostpci0 0000:00:02.0,legacy-igd=1,romfile=rom_file_name.rom,device-id=0x3e9b
   ```

- **QEMU:**
   ```
   -device vfio-pci,host=0000:00:02.0,id=hostpci0,bus=pci.0,addr=0x2,romfile=/path/to/rom/file,x-pci-device-id=0x3e9b
   ```

---

### 4. CPU Models
macOS will now detect the native iGPU, but for macOS to load it properly, you must emulate a compatible CPUID model.

You have two options:

1. Use the `host` CPU model (not recommended)
   ```bash
   qm set [VMID] --args "-cpu host,+invtsc"
   ```

2. Use named QEMU CPU models. For example, if you have Skylake, use `Skylake-Client-v4`. If you have Coffee Lake or Comet Lake and QEMU does not have a predefined CPU model for it, override the CPUID model with **`model=`** in the `-cpu` QEMU args:
   ```bash
   qm set [VMID] --args "-cpu Skylake-Client-v4,vendor=GenuineIntel,+invtsc,model=158"
   ```

> [!Note]
> CPUID models table:
> | Generation | CPUID Model |
> |------------|-------------|
> | Kaby Lake / Coffee Lake | `158` |
> | Comet Lake | `165` |

### 5. Device Properties
After configuring the CPUID, it should work if you have a natively supported iGPU. If you don't, you must modify **DeviceProperties** in `config.plist`. For details, see the [Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/config.plist/).