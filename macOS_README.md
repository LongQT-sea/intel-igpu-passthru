## Note for using iGPU passthrough with a macOS VM
> [!Important]
> * Make sure you have a supported iGPU. See [Dortania Intel iGPU Guide](https://dortania.github.io/GPU-Buyers-Guide/modern-gpus/intel-gpu.html).  
> * This is a reference document — you may need to adapt it based on your iGPU device ID.
> * Follow this document only if you already have macOS installed and OpenCore EFI copied to the EFI partition on your macOS disk.

> [!Tip]
> * Installing the macOS VM using the [OpenCore-ISO](https://github.com/LongQT-sea/OpenCore-ISO) project is recommended.

---

### 1. Check your iGPU device ID
- Open Proxmox VE shell and run:
   ```bash
   lspci -nn -s 00:02.0
   ````

- Example output:
   ```
   00:02.0 VGA compatible controller [0300]: Intel Corporation Coffee Lake-S GT2 [UHD Graphics P630] [8086:3e94]
   ```
   In this example, the Coffee Lake iGPU has a device ID of **`0x3e94`**

---

### 2. Check WhateverGreen documentation
Go to the Coffee Lake (or whatever generation you have) section in [WhateverGreen/Manual/FAQ.IntelHD.en.md](https://github.com/acidanthera/WhateverGreen/blob/master/Manual/FAQ.IntelHD.en.md) and look for your device ID:

* If your iGPU device ID appears under ***Native supported DevIDs*** **and** under `Desktop` or `Laptop` in ***Recommended framebuffers***, great — continue to the [**CPU Models**](#4-cpu-models) section.
* If it's **not** listed, you'll need to spoof your iGPU's device ID to a natively supported device ID from the `Desktop` or `Laptop` category in ***Recommended framebuffers***.

---

### 3. Spoofing iGPU device ID
* For example, if you have a `0x3e94`, you need to spoof it to something like `0x3e9b`, which is a Coffee Lake `Desktop` recommended framebuffer.
  - **Proxmox VE:**
     ```
     qm set [VMID] -hostpci0 0000:00:02.0,legacy-igd=1,romfile=igd.rom,device-id=0x3e9b
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
> [!Tip]
> In legacy mode passthrough, the default DVMT Pre-Allocated value is 128MB, so `framebuffer-stolenmem` may not be needed.
- Example for Coffee Lake:
<img width="1191" height="639" alt="image" src="https://github.com/user-attachments/assets/e555da65-c3b3-45c4-bc10-1fd35172a956" />
