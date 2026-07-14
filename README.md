# NetBeans delay when open project — Open Project dialog slow / freezes ~30 seconds (Windows fix)

**Fix for: NetBeans is slow or freezes when opening a project, especially when the Open Project dialog takes about 30 seconds to appear.**

If you searched for any of these, you are in the right place:

- **netbeans delay when open project**
- netbeans open project slow
- netbeans open project takes long time
- netbeans open project freezes / hangs / stuck
- netbeans file open project dialog slow
- netbeans 30 second delay open project
- netbeans waiting to open project
- netbeans freeze on open project windows
- apache netbeans open project lag
- netbeans project chooser slow oneDrive

---

## Quick answer (most common fix)

**Problem:** Click **File → Open Project** → NetBeans freezes ~**30 seconds** → then the folder chooser UI finally shows.

**Cause:** Module `org.netbeans.swing.dirchooser` uses Windows **ShellFolder** (Explorer/OneDrive). The UI thread blocks until that returns.

**Fix:** Disable the **dirchooser** module, restart NetBeans.

### 1-minute fix (PowerShell)

```powershell
git clone https://github.com/Vlantoy/netbeans-open-project-dialog-slow.git
cd netbeans-open-project-dialog-slow
.\scripts\disable-dirchooser.ps1
```

Then **File → Exit** NetBeans completely, start again, try **File → Open Project**.

### Manual fix (no clone)

Create this file (change `17` if your version is different):

`%APPDATA%\NetBeans\17\config\Modules\org-netbeans-swing-dirchooser.xml`

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

Restart NetBeans. The Open Project dialog should appear in **1–3 seconds**, not 30.

**Undo:** run `.\scripts\enable-dirchooser.ps1` or set `enabled` to `true` / delete the XML.

---

## Is this your bug? (symptom checklist)

| Symptom | This fix |
|--------|----------|
| Delay happens **before** the Open Project window appears | Yes |
| Delay is roughly **fixed ~20–40s** (often exactly ~30s) | Yes |
| Windows Explorer itself is normal speed | Yes |
| Still slow with Wi‑Fi / network **off** | Yes |
| IDE looks frozen; mouse works outside NetBeans | Yes |
| Slow **after** you already picked a project (indexing/Maven) | No → see [docs/other-causes.md](docs/other-causes.md) |

### What people usually say

- “NetBeans delay when I open project”
- “Open Project freezes NetBeans for half a minute”
- “Nothing happens when I click Open Project, then suddenly the dialog appears”
- “NetBeans hangs only on File → Open Project”
- “Works fine until I open the project chooser”

---

## Why NetBeans is slow to open the project dialog

```
File → Open Project
        │
        ▼
createProjectChooser()     ← runs on UI thread (EDT)
        │
        ▼
JFileChooser + dirchooser
        │
        ▼
Windows ShellFolder  ← Explorer / OneDrive / icon overlays
        │
        ▼
~30 second hang → dialog finally paints
```

Apache NetBeans ships a note in the dirchooser module (`MSG_SlownessNote`):

> Dialog seems to be slow, probably because of **JDK bug**.  
> Try upgrading JDK, remove zip files from Desktop, or run with  
> **`-J-Dnb.FileChooser.useShellFolder=false`**.

On many PCs (especially **Windows 10/11 + OneDrive Desktop/Documents**), that flag is **not enough**. Disabling **dirchooser** is the reliable fix.

### Triggers that make “open project delay” worse

- Desktop or Documents redirected to **OneDrive**
- Many shell **icon overlays** (OneDrive, backup tools, etc.)
- Older/buggy **JDK + ShellFolder** interaction
- Large/messy Desktop (NetBeans even mentions **zip files on Desktop**)

### What is usually NOT the cause (for this exact symptom)

- Slow HDD listing of `NetBeansProjects` (local list is often only a few ms)
- Proxy alone (hang often remains **offline**)
- Maven download (that is *after* you select a project)
- “Need to reinstall NetBeans” (reinstall rarely fixes ShellFolder hangs)

Full step-by-step debug: **[docs/debug-checklist.md](docs/debug-checklist.md)**

---

## Optional steps (if disable dirchooser is not enough)

1. **JVM flag** (Admin; may help, not always):

   ```text
   -J-Dnb.FileChooser.useShellFolder=false
   ```

   Add to `netbeans_default_options` in `netbeans\etc\netbeans.conf`  
   Helper: `.\scripts\add-shellfolder-flag.ps1`

2. **Measure disk vs dialog:** `.\scripts\measure-fs.ps1`

3. **Thread dump while frozen:** `.\scripts\thread-dump-hint.ps1`  
   Look for `AWT-EventQueue` + `ShellFolder` / `JFileChooser` / `dirchooser`

4. **Clean userdir test** (does not delete your real settings):

   ```powershell
   netbeans64.exe --userdir "$env:TEMP\nb-clean" --cachedir "$env:TEMP\nb-clean-cache"
   ```

5. Reinstall NetBeans **without** deleting `%APPDATA%\Roaming\NetBeans`  
   (settings live there; wiping it is optional factory reset)

---

## Side effects of the fix

| | Before | After disabling dirchooser |
|--|--------|----------------------------|
| Open Project speed | Often ~30s freeze | Usually instant |
| Dialog look | Explorer-like | Plain Swing chooser |
| Projects, build, debug, Tomcat, JDK | Unchanged | Unchanged |
| Keymaps / IDE settings | Unchanged | Unchanged |

You only change **how the file/folder dialog is drawn**, not your project code.

---

## Reinstall FAQ

| Question | Answer |
|----------|--------|
| Will reinstall fix open-project delay? | Often **no** (same ShellFolder path) |
| Will reinstall delete my projects? | **No** (projects are your folders) |
| Will reinstall delete IDE settings? | **No**, unless you delete `%APPDATA%\NetBeans` |

---

## Repo contents

| Path | Purpose |
|------|---------|
| `scripts/disable-dirchooser.ps1` | **Main fix** |
| `scripts/enable-dirchooser.ps1` | Revert |
| `scripts/measure-fs.ps1` | Prove disk is fast |
| `scripts/add-shellfolder-flag.ps1` | Optional conf flag |
| `scripts/thread-dump-hint.ps1` | Capture freeze stacks |
| `docs/debug-checklist.md` | Full debug order |
| `docs/other-causes.md` | Slow *after* open, Maven, index… |

---

## Keywords (for search / SEO)

`netbeans delay when open project`, `netbeans open project slow`, `netbeans open project freezes`, `netbeans open project hangs`, `netbeans open project takes 30 seconds`, `netbeans file open project dialog slow`, `apache netbeans project chooser lag`, `netbeans stuck opening project`, `netbeans freeze windows oneDrive`, `dirchooser ShellFolder`, `nb.FileChooser.useShellFolder`, `netbeans 17 open project delay`

---

## Verified on

- Windows 11  
- Apache NetBeans **17**  
- JDK **17**  
- OneDrive-backed Desktop/Documents  
- Local project tree on `D:\` listed in milliseconds; **dialog still delayed ~30s** until dirchooser disabled  

---

## Contributing / “me too”

Open an [Issue](https://github.com/Vlantoy/netbeans-open-project-dialog-slow/issues) with:

- NetBeans version, JDK, Windows version  
- OneDrive on Desktop/Documents? (yes/no)  
- Which step fixed it (`disable-dirchooser` / shell flag / other)  
- Optional: `AWT-EventQueue` lines from `jcmd Thread.print` during freeze  

---

## License

MIT — see [LICENSE](LICENSE).

---

## Tiếng Việt

**Lỗi:** NetBeans **chậm / đơ khi mở project** — bấm **File → Open Project** khoảng **30 giây** mới hiện cửa sổ chọn folder.

**Nguyên nhân:** Module `dirchooser` gọi Windows ShellFolder (Explorer/OneDrive), block luồng UI.

**Cách sửa:** Tắt module `org.netbeans.swing.dirchooser` bằng script `disable-dirchooser.ps1` hoặc file XML trong `%APPDATA%\NetBeans\17\config\Modules\`, rồi restart NetBeans.

**Không mất** project hay setting IDE. Dialog chọn folder chỉ đổi sang kiểu Swing đơn giản hơn.
