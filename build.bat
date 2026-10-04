@echo off
setlocal
echo ===================================================
echo   Music Downloader - One-click Build Script
echo ===================================================

if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
)

if not defined CMAKE_PREFIX_PATH (
    if exist "D:\Qt\6.8.3\msvc2022_64" (
        set "CMAKE_PREFIX_PATH=D:\Qt\6.8.3\msvc2022_64"
    ) else if exist "C:\Qt\6.8.3\msvc2022_64" (
        set "CMAKE_PREFIX_PATH=C:\Qt\6.8.3\msvc2022_64"
    )
)

echo Configuring CMake...
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 goto error

echo Compiling...
ninja -C build
if errorlevel 1 goto error

echo.
echo Build succeeded: build\MusicDownloader.exe
goto end

:error
echo.
echo Build failed! Please check environment configuration.

:end
endlocal
