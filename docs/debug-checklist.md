# Debug checklist: Open Project dialog ~30s freeze

Use this when **File → Open Project** freezes before the chooser appears.

## 0. Pin the symptom

| Question | Matching this bug |
|----------|-------------------|
| Freeze **before** dialog paints? | Yes |
| Duration roughly **constant ~30s**? | Yes |
| After dialog is open, browsing folders is OK? | Often yes |
| Offline still freezes? | Often yes |

If freeze is **after** you select a project → see [other-causes.md](other-causes.md).

---

## 1. Rule out slow disk / OneDrive listing

```powershell
# From repo root
.\scripts\measure-fs.ps1
```

- Local project parent dir list **&lt; 100ms** but Open Project still 30s → UI/shell path, not disk.  
- Listing already multi‑second → fix storage, Defender, OneDrive first.

---

## 2. Optional: JVM shell-folder flag

NetBeans documents:

```text
-J-Dnb.FileChooser.useShellFolder=false
```

Add to `netbeans_default_options` in:

- `C:\Program Files\NetBeans-<ver>\netbeans\etc\netbeans.conf`  
  or your install path  

Requires Admin. Restart NetBeans.

```powershell
# optional helper (Admin UAC)
.\scripts\add-shellfolder-flag.ps1
```

On some PCs this is enough; on others **it is not** (ours still hung).

---

## 3. Main fix: disable dirchooser

```powershell
.\scripts\disable-dirchooser.ps1
```

Fully exit NetBeans → start → Open Project.

Expect: dialog in **&lt; 2–3 seconds**.

Revert:

```powershell
.\scripts\enable-dirchooser.ps1
```

---

## 4. Clean userdir test (settings isolation)

Keeps your real config untouched:

```powershell
& "C:\Program Files\NetBeans-17\netbeans\bin\netbeans64.exe" `
  --userdir "$env:TEMP\nb-clean-test" `
  --cachedir "$env:TEMP\nb-clean-cache"
```

Adjust path/version if needed.

| Result | Meaning |
|--------|---------|
| Clean userdir is **fast** | Something in `%APPDATA%\NetBeans\<ver>` contributes; still try dirchooser off on real userdir |
| Clean userdir still **30s** | Install/JDK/Windows shell environment |

---

## 5. Thread dump during freeze

1. Open Project (start the freeze).  
2. In another terminal:

```powershell
.\scripts\thread-dump-hint.ps1
# or manually:
jps -l
jcmd <PID> Thread.print > edt-dump.txt
```

Inspect **`AWT-EventQueue`**:

- `sun.awt.shell.ShellFolder`  
- `javax.swing.JFileChooser`  
- `org.netbeans.swing.dirchooser`  
- long `Native Method` under shell/COM  

That confirms the UI thread is stuck in the shell/file-chooser path.

---

## 6. Reinstall (last)

- Backup `%APPDATA%\Roaming\NetBeans\<ver>` if you want.  
- Uninstall / reinstall **application only**.  
- **Do not** delete AppData unless you want a factory IDE.  
- Prefer steps 3–5 before reinstall; reinstall alone often **does not** fix ShellFolder hangs.

---

## What we already ruled out (example machine)

| Hypothesis | Result |
|------------|--------|
| Slow local disk | List/read ms-level |
| System proxy / PAC | Offline still 30s |
| Hostname reverse DNS | Fixed hosts; still 30s |
| Network printers | None relevant |
| Opening many OneDrive projects | Dialog hang even about opening the chooser itself |
| `useShellFolder=false` only | Still ~30s |
| **Disable dirchooser** | Fixed |
