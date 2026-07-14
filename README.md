# NetBeans: Open Project dialog freezes ~30 seconds

**Symptom:** Click **File → Open Project** → IDE freezes for **exactly ~30 seconds** → then the folder chooser UI finally appears.

- Outside NetBeans, Windows Explorer is fine  
- Disk I/O is fine (listing `D:\…` takes milliseconds)  
- Turning off Wi‑Fi does **not** fix it  
- The IDE looks dead, but it is usually the **UI thread (EDT)** blocked waiting on Windows Shell

This repo documents how we diagnosed and fixed it on **Apache NetBeans 17 + Windows 11 + OneDrive**, so others can debug the same class of bug.

---

## TL;DR fix (most common)

Disable the NetBeans **`dirchooser`** module (custom file dialog that uses Windows `ShellFolder`).

### Option A — script (Windows PowerShell)

```powershell
# From this repo
.\scripts\disable-dirchooser.ps1
```

Then **fully restart** NetBeans (File → Exit) and test **File → Open Project**.

### Option B — manual

Create / edit:

`%APPDATA%\NetBeans\<VERSION>\config\Modules\org-netbeans-swing-dirchooser.xml`

Example for NetBeans **17**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE module PUBLIC "-//NetBeans//DTD Module Status 1.0//EN"
                        "http://www.netbeans.org/dtds/module-status-1_0.dtd">
<module name="org.netbeans.swing.dirchooser">
    <param name="autoload">false</param>
    <param name="eager">false</param>
    <param name="enabled">false</param>
    <param name="jar">modules/org-netbeans-swing-dirchooser.jar</param>
    <param name="reloadable">false</param>
</module>
```

Restart NetBeans. Open Project should show the dialog almost immediately.

### Revert

```powershell
.\scripts\enable-dirchooser.ps1
```

Or delete that XML file and restart.

---

## Why does this happen?

```
Click Open Project
        │
        ▼
createProjectChooser()   (runs on EDT / UI thread)
        │
        ▼
JFileChooser + org.netbeans.swing.dirchooser
        │
        ▼
Windows ShellFolder API  ←── Explorer / OneDrive / icon overlays / shell extensions
        │
        ▼
~30s hang  →  dialog finally paints
```

NetBeans itself documents this in `org-netbeans-swing-dirchooser` (`MSG_SlownessNote`):

> Dialog seems to be slow, probably because of JDK bug.  
> Please try to upgrade JDK, remove zip files from Desktop folder or  
> run with **`-J-Dnb.FileChooser.useShellFolder=false`**.

On some machines the JVM flag is **not enough**; disabling the whole **dirchooser** module is.

### What makes a machine “vulnerable”?

| Factor | Why it hurts |
|--------|----------------|
| Desktop/Documents on **OneDrive** | Default `FileSystemView` home/default dirs go through shell + cloud reparse points |
| Many **Shell icon overlays** (OneDrive, etc.) | Shell asks overlays when building the dialog |
| JDK + Windows ShellFolder quirks | Known slow path; NetBeans even ships a “slowness note” |
| Exact **~30s** delay | Classic “blocked wait / timeout” feel on UI thread, not slow disk |

**Not** the usual culprits (we ruled them out while debugging):

- Maven/network download  
- Proxy PAC alone  
- Listing the project folder on a local drive  
- “Project open/index after you pick a folder” (different symptom)

---

## Confirm your symptom matches

Answer these:

1. Delay happens **before** the Open Project window appears (not after clicking Open)?  
2. Delay is roughly **fixed ~20–40s**, often **~30s**?  
3. Explorer browsing the same folders is fast?  
4. Airplane mode / offline still slow?

If **yes** → start with **disable dirchooser**.

If delay is **after** choosing a project (indexing, classpath, Maven) → this repo’s fix will **not** help; see [docs/other-causes.md](docs/other-causes.md).

---

## Debug checklist (do this in order)

Full walkthrough: [docs/debug-checklist.md](docs/debug-checklist.md)

Short version:

| Step | Action | If still slow… |
|------|--------|----------------|
| 1 | Measure raw folder list time | If list is already multi‑second, fix disk/AV/OneDrive first |
| 2 | Try `-J-Dnb.FileChooser.useShellFolder=false` in `netbeans.conf` | Next step |
| 3 | **Disable dirchooser module** (this repo’s main fix) | Next step |
| 4 | Fresh userdir test: `--userdir %TEMP%\nb-clean` | If clean is fast → corrupt/slow prefs in old userdir |
| 5 | Thread dump while frozen (`jcmd <pid> Thread.print`) | Look for EDT stuck in `ShellFolder` / `JFileChooser` / `dirchooser` |
| 6 | Reinstall NetBeans **without** deleting `%APPDATA%\NetBeans` | Last resort; settings live in AppData |

Scripts:

- `scripts/disable-dirchooser.ps1` / `enable-dirchooser.ps1`  
- `scripts/measure-fs.ps1` — quick local vs OneDrive list timing  
- `scripts/add-shellfolder-flag.ps1` — optional `netbeans.conf` flag (needs Admin)  
- `scripts/thread-dump-hint.ps1` — how to capture EDT stacks during the freeze  

---

## Side effects of disabling dirchooser

| | With dirchooser (default) | Without (fix) |
|--|---------------------------|-----------------|
| Open Project UI | Explorer-like, Shell icons | Standard Swing chooser (plainer) |
| Speed on affected PCs | Can freeze ~30s | Usually instant |
| Projects / build / Tomcat / JDK | Unchanged | Unchanged |
| Settings / keymaps | Unchanged | Unchanged |

You only change **how file/folder dialogs look and which Windows Shell path they use**.

---

## Does reinstall wipe my setup?

| Data | Location | Uninstall NetBeans app only |
|------|----------|-----------------------------|
| Your code | e.g. `D:\NetBeansProjects` | **Safe** |
| NetBeans UI settings, servers, recent projects | `%APPDATA%\Roaming\NetBeans\<ver>` | **Safe** if you do not delete it |
| Cache | `%LOCALAPPDATA%\NetBeans\Cache` | Regenerated |

**Only** wiping `AppData\Roaming\NetBeans` loses IDE setup. Reinstalling the program does not require that.

---

## Environment where this was verified

- Windows 11  
- Apache NetBeans **17**  
- JDK 17  
- OneDrive-backed Desktop/Documents  
- Project folders on local `D:\` were fast to list; dialog creation still hung  

---

## Contributing

If this fixed (or did **not** fix) your case, open an Issue with:

- NetBeans version, JDK version, OS  
- Whether OneDrive is on Desktop/Documents  
- Which step of the checklist fixed it (or failed)  
- Optional: snippet of `AWT-EventQueue` stack from `jcmd Thread.print` during the freeze  

---

## License

MIT — see [LICENSE](LICENSE).

## Tiếng Việt (tóm tắt)

**Triệu chứng:** Bấm Open Project → IDE đơ ~30s mới hiện dialog chọn folder.  

**Nguyên nhân:** Module `dirchooser` gọi Windows ShellFolder (Explorer/OneDrive) trên luồng UI.  

**Cách fix:** Tắt module `org.netbeans.swing.dirchooser` (script `disable-dirchooser.ps1` hoặc file XML trong `%APPDATA%\NetBeans\17\config\Modules\`). Restart NetBeans.  

**Ảnh hưởng:** Dialog hơi “cũ” hơn; không mất project/settings. Chi tiết trong README (English) và `docs/`.
