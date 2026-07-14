# Other causes (not the Open Project dialog hang)

If your delay is **not** “dialog appears after 30s”, you may have a different problem.

## A. Slow **after** choosing a project

Possible causes:

- First-time **indexing** of a large tree  
- **Maven/Gradle** resolving dependencies  
- Project on **network drive** or **OneDrive** with online-only files  
- Broken **platform / library** paths  

Check `messages.log`:

`%APPDATA%\NetBeans\<ver>\var\log\messages.log`

Look for `Indexing finished, indexing took …`.

## B. IDE startup is slow

- Too many projects reopened at startup  
- Antivirus scanning install/cache  
- Full disk on `%SystemDrive%`

## C. New Project wizard slow

- Different code path from Open Project  
- Still try dirchooser off if any file chooser is involved  
- Template/network modules less common offline

## D. Real network timeouts (~30s)

When **offline fixes the hang**, look at:

- Proxy / PAC  
- Maven central  
- Dead mapped drives (`net use`)  
- VPN

The **dirchooser / ShellFolder** issue often **persists offline**.
