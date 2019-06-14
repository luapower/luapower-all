!include x64.nsh
Name "libjpeg-turbo SDK for GCC 64-bit"
OutFile "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}libjpeg-turbo-2.0.2-gcc64.exe"
InstallDir "c:\libjpeg-turbo-gcc64"

SetCompressor bzip2

Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "libjpeg-turbo SDK for GCC 64-bit (required)"
!ifdef WIN64
	${If} ${RunningX64}
	${DisableX64FSRedirection}
	${Endif}
!endif
	SectionIn RO
!ifdef GCC
	IfFileExists $SYSDIR/libturbojpeg.dll exists 0
!else
	IfFileExists $SYSDIR/turbojpeg.dll exists 0
!endif
	goto notexists
	exists:
!ifdef GCC
	MessageBox MB_OK "An existing version of the libjpeg-turbo SDK for GCC 64-bit is already installed.  Please uninstall it first."
!else
	MessageBox MB_OK "An existing version of the libjpeg-turbo SDK for GCC 64-bit or the TurboJPEG SDK is already installed.  Please uninstall it first."
!endif
	quit

	notexists:
	SetOutPath $SYSDIR
!ifdef GCC
	File "X:/tools/luapower-full/csrc/libjpeg/src\libturbojpeg.dll"
!else
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}turbojpeg.dll"
!endif
	SetOutPath $INSTDIR\bin
!ifdef GCC
	File "X:/tools/luapower-full/csrc/libjpeg/src\libturbojpeg.dll"
!else
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}turbojpeg.dll"
!endif
!ifdef GCC
	File "X:/tools/luapower-full/csrc/libjpeg/src\libjpeg-62.dll"
!else
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}jpeg62.dll"
!endif
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}cjpeg.exe"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}djpeg.exe"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}jpegtran.exe"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}tjbench.exe"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}rdjpgcom.exe"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}wrjpgcom.exe"
	SetOutPath $INSTDIR\lib
!ifdef GCC
	File "X:/tools/luapower-full/csrc/libjpeg/src\libturbojpeg.dll.a"
	File "X:/tools/luapower-full/csrc/libjpeg/src\libturbojpeg.a"
	File "X:/tools/luapower-full/csrc/libjpeg/src\libjpeg.dll.a"
	File "X:/tools/luapower-full/csrc/libjpeg/src\libjpeg.a"
!else
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}turbojpeg.lib"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}turbojpeg-static.lib"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}jpeg.lib"
	File "X:/tools/luapower-full/csrc/libjpeg/src\${BUILDDIR}jpeg-static.lib"
!endif
	SetOutPath $INSTDIR\lib\pkgconfig
	File "X:/tools/luapower-full/csrc/libjpeg/src\pkgscripts\libjpeg.pc"
	File "X:/tools/luapower-full/csrc/libjpeg/src\pkgscripts\libturbojpeg.pc"
!ifdef JAVA
	SetOutPath $INSTDIR\classes
	File "X:/tools/luapower-full/csrc/libjpeg/src\java\turbojpeg.jar"
!endif
	SetOutPath $INSTDIR\include
	File "X:/tools/luapower-full/csrc/libjpeg/src\jconfig.h"
	File "X:/tools/luapower-full/csrc/libjpeg/src\jerror.h"
	File "X:/tools/luapower-full/csrc/libjpeg/src\jmorecfg.h"
	File "X:/tools/luapower-full/csrc/libjpeg/src\jpeglib.h"
	File "X:/tools/luapower-full/csrc/libjpeg/src\turbojpeg.h"
	SetOutPath $INSTDIR\doc
	File "X:/tools/luapower-full/csrc/libjpeg/src\README.ijg"
	File "X:/tools/luapower-full/csrc/libjpeg/src\README.md"
	File "X:/tools/luapower-full/csrc/libjpeg/src\LICENSE.md"
	File "X:/tools/luapower-full/csrc/libjpeg/src\example.txt"
	File "X:/tools/luapower-full/csrc/libjpeg/src\libjpeg.txt"
	File "X:/tools/luapower-full/csrc/libjpeg/src\structure.txt"
	File "X:/tools/luapower-full/csrc/libjpeg/src\usage.txt"
	File "X:/tools/luapower-full/csrc/libjpeg/src\wizard.txt"
	File "X:/tools/luapower-full/csrc/libjpeg/src\tjexample.c"
	File "X:/tools/luapower-full/csrc/libjpeg/src\java\TJExample.java"
!ifdef GCC
	SetOutPath $INSTDIR\man\man1
	File "X:/tools/luapower-full/csrc/libjpeg/src\cjpeg.1"
	File "X:/tools/luapower-full/csrc/libjpeg/src\djpeg.1"
	File "X:/tools/luapower-full/csrc/libjpeg/src\jpegtran.1"
	File "X:/tools/luapower-full/csrc/libjpeg/src\rdjpgcom.1"
	File "X:/tools/luapower-full/csrc/libjpeg/src\wrjpgcom.1"
!endif

	WriteRegStr HKLM "SOFTWARE\64 2.0.2" "Install_Dir" "$INSTDIR"

	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\64 2.0.2" "DisplayName" "libjpeg-turbo SDK v2.0.2 for GCC 64-bit"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\64 2.0.2" "UninstallString" '"$INSTDIR\uninstall_2.0.2.exe"'
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\64 2.0.2" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\64 2.0.2" "NoRepair" 1
	WriteUninstaller "uninstall_2.0.2.exe"
SectionEnd

Section "Uninstall"
!ifdef WIN64
	${If} ${RunningX64}
	${DisableX64FSRedirection}
	${Endif}
!endif

	SetShellVarContext all

	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\64 2.0.2"
	DeleteRegKey HKLM "SOFTWARE\64 2.0.2"

!ifdef GCC
	Delete $INSTDIR\bin\libjpeg-62.dll
	Delete $INSTDIR\bin\libturbojpeg.dll
	Delete $SYSDIR\libturbojpeg.dll
	Delete $INSTDIR\lib\libturbojpeg.dll.a
	Delete $INSTDIR\lib\libturbojpeg.a
	Delete $INSTDIR\lib\libjpeg.dll.a
	Delete $INSTDIR\lib\libjpeg.a
!else
	Delete $INSTDIR\bin\jpeg62.dll
	Delete $INSTDIR\bin\turbojpeg.dll
	Delete $SYSDIR\turbojpeg.dll
	Delete $INSTDIR\lib\jpeg.lib
	Delete $INSTDIR\lib\jpeg-static.lib
	Delete $INSTDIR\lib\turbojpeg.lib
	Delete $INSTDIR\lib\turbojpeg-static.lib
!endif
	Delete $INSTDIR\lib\pkgconfig\libjpeg.pc
	Delete $INSTDIR\lib\pkgconfig\libturbojpeg.pc
!ifdef JAVA
	Delete $INSTDIR\classes\turbojpeg.jar
!endif
	Delete $INSTDIR\bin\cjpeg.exe
	Delete $INSTDIR\bin\djpeg.exe
	Delete $INSTDIR\bin\jpegtran.exe
	Delete $INSTDIR\bin\tjbench.exe
	Delete $INSTDIR\bin\rdjpgcom.exe
	Delete $INSTDIR\bin\wrjpgcom.exe
	Delete $INSTDIR\include\jconfig.h
	Delete $INSTDIR\include\jerror.h
	Delete $INSTDIR\include\jmorecfg.h
	Delete $INSTDIR\include\jpeglib.h
	Delete $INSTDIR\include\turbojpeg.h
	Delete $INSTDIR\uninstall_2.0.2.exe
	Delete $INSTDIR\doc\README.ijg
	Delete $INSTDIR\doc\README.md
	Delete $INSTDIR\doc\LICENSE.md
	Delete $INSTDIR\doc\example.txt
	Delete $INSTDIR\doc\libjpeg.txt
	Delete $INSTDIR\doc\structure.txt
	Delete $INSTDIR\doc\usage.txt
	Delete $INSTDIR\doc\wizard.txt
	Delete $INSTDIR\doc\tjexample.c
	Delete $INSTDIR\doc\TJExample.java
!ifdef GCC
	Delete $INSTDIR\man\man1\cjpeg.1
	Delete $INSTDIR\man\man1\djpeg.1
	Delete $INSTDIR\man\man1\jpegtran.1
	Delete $INSTDIR\man\man1\rdjpgcom.1
	Delete $INSTDIR\man\man1\wrjpgcom.1
!endif

	RMDir "$INSTDIR\include"
	RMDir "$INSTDIR\lib\pkgconfig"
	RMDir "$INSTDIR\lib"
	RMDir "$INSTDIR\doc"
!ifdef GCC
	RMDir "$INSTDIR\man\man1"
	RMDir "$INSTDIR\man"
!endif
!ifdef JAVA
	RMDir "$INSTDIR\classes"
!endif
	RMDir "$INSTDIR\bin"
	RMDir "$INSTDIR"

SectionEnd
