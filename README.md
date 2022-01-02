# About

[![Build status](https://github.com/rgl/SetWindowsDesktopWallpaper/workflows/Build/badge.svg)](https://github.com/rgl/SetWindowsDesktopWallpaper/actions?query=workflow%3ABuild)

This set the current display wallpaper (and update it when the display is resized).

# Usage

Install the .NET 6.0 SDK.

Execute the `Debug` version:

```pwsh
cd SetWindowsDesktopWallpaper
dotnet run
```

Execute the `Release` version:

```pwsh
dotnet publish --runtime win-x64 --self-contained --configuration Release
.\bin\Release\net6.0-windows10.0.17763\win-x64\publish\SetWindowsDesktopWallpaper.exe
```

You can also use vagrant to try this in a multiple display environment.

# COM Interop

This uses [IDesktopWallpaper.SetWallpaper](https://docs.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-idesktopwallpaper-setwallpaper) COM method to set a display wallpaper.

This uses the [Microsoft.Windows.CsWin32](https://github.com/microsoft/CsWin32) source code generator to automatically generate the required COM Interop code to call `IDesktopWallpaper.SetWallpaper`.

## Manual COM Interop

Instead of using the code generator, we could manually create the interop code with this powershell script:

```powershell
$vsInstallPath = 'C:\VisualStudio2019Community'
Import - Module $vsInstallPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll
  Enter-VsDevShell -VsInstallPath $vsInstallPath

# convert the COM interfaces to a dotnet assembly.
# e.g. C:\Program Files (x86)\Windows Kits\10\include\10.0.17763.0\um\ShObjIdl_core.idl
$idlPath = $env:INCLUDE - split ';' | ForEach - Object { "$_\ShObjIdl_core.idl" } | Where - Object { Test - Path $_ }
midl.exe / target NT62 /out $PWD / tlb ShObjCore.tlb / x64 $idlPath
tlbimp.exe ShObjCore.tlb /out:ShObjCore.dll /namespace:ShObjCore /machine:X64
```

Then use ILSpy to manually extract the relevant code (ShObjCore.IDesktopWallpaper interface et all).

Then convert all out parameters to return values.

Or better, use the [Vanara.Windows.Shell.WallpaperManager](https://github.com/dahall/Vanara/blob/v3.3.15/Windows.Shell/WallpaperManager.cs) wrapper.

# Reference

* [Microsoft.Windows.CsWin32 Code Generator](https://github.com/microsoft/CsWin32).
  * this generates the code from the common [win32metadata](https://github.com/microsoft/win32metadata).
* [Vanara Library](https://github.com/dahall/Vanara).
* [SkiaSharp Library](https://github.com/mono/SkiaSharp).
* [Docs: COM Interop in .NET](https://docs.microsoft.com/en-us/dotnet/standard/native-interop/cominterop).
