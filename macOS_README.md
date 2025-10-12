## Note for use iGPU passthrough with macOS VM
> [!Important]
> Make sure you have a supported iGPU, see [Dortania Intel iGPU](https://dortania.github.io/GPU-Buyers-Guide/modern-gpus/intel-gpu.html)

### 1. Check your iGPU device ID

Run:

```bash
lspci -nn -s 00:02.0
```

Example output:

```
00:02.0 VGA compatible controller [0300]: Intel Corporation CoffeeLake-H GT2 [UHD Graphics 630] [8086:3e9b] (rev 02)
```

In this case, your Coffee Lake iGPU device ID is `0x3e9b`.

---

### 2. Check WhateverGreen documentation
Go to the Coffee Lake (or whatever Lake you have) section in [WhateverGreen/Manual/FAQ.IntelHD.en.md](https://github.com/acidanthera/WhateverGreen/blob/master/Manual/FAQ.IntelHD.en.md) and look for your device ID (`0x3e9b`).

* If your iGPU device ID appears under **Native supported DevIDs** and **Recommended framebuffers**, great — continue to the [**CPU Models**](#4-cpu-models) section.
* If it's **not** listed, you'll need to spoof your iGPU's device ID to a natively supported one.

---

### 3. Example spoofing iGPU device ID

**Proxmox VE:**

```
hostpci0: 0000:00:02.0,legacy-igd=1,romfile=SKL_CML_GOPv9_igd.rom,device-id=0x3e9b
```

**QEMU:**

```
-device vfio-pci,host=0000:00:02.0,id=hostpci0,bus=pci.0,addr=0x2,romfile=/path/to/rom/file,x-pci-device-id=0x3e9b
```

---

### 4. CPU Models
macOS will now detect the native iGPU, but for macOS to load it properly, you must emulate a compatible CPUID model.

For Coffee Lake, the CPUID model is `158`.

You have two options:
1. Use the `host` CPU model (not recommended)
2. Override CPUID model in your QEMU args:
   ```
   -cpu Skylake-Client-v4,vendor=GenuineIntel,+invtsc,model=158
   ```

> [!Note]
> CPUID models table:

| Generation | CPUID Model |
|------------|-------------|
| Kaby Lake / Coffee Lake | `158` |
| Comet Lake | `165` |

### 5. Device Properties
After configuring the CPUID, it should work if you have a natively supported iGPU. If you don't, you must modify **DeviceProperties** in `config.plist`. For details, see the [Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/config.plist/).