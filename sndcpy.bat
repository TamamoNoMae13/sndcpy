@echo off
if not defined ADB set ADB=adb
if not defined FFPLAY set FFPLAY="ffplay.exe"
if not defined SNDCPY_APK set SNDCPY_APK=sndcpy.apk
if not defined SNDCPY_PORT set SNDCPY_PORT=28200

if not "%1"=="" (
    set serial=-s %1
    echo Waiting for device %1...
) else (
    echo Waiting for device...
)

%ADB% %serial% wait-for-device || goto :error
%ADB% %serial% install -t -r -g %SNDCPY_APK% || (
    echo Uninstalling existing version first...
    %ADB% %serial% uninstall com.rom1v.sndcpy || goto :error
    %ADB% %serial% install -t -g %SNDCPY_APK% || goto :error
)
%ADB% %serial% shell appops set com.rom1v.sndcpy PROJECT_MEDIA allow
%ADB% %serial% forward tcp:%SNDCPY_PORT% localabstract:sndcpy || goto :error
%ADB% %serial% shell am start com.rom1v.sndcpy/.MainActivity || goto :error

timeout 2

echo Playing audio...
%FFPLAY% -hide_banner -loglevel fatal -nodisp -f s16le -probesize 32 -ac 2 -ar 48000 -acodec pcm_s16le tcp://localhost:%SNDCPY_PORT%
goto :EOF

:error
echo Failed with error #%errorlevel%.
pause
exit /b %errorlevel%
