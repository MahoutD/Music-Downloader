@echo off
setlocal
echo ====================================================
echo  Building MusicDownloader with MSVC 2022 and CMake
echo ====================================================

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 (
    echo [ERROR] Failed to initialize MSVC vcvars64 environment.
    pause
    exit /b 1
)

cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="D:/Qt/6.8.3/msvc2022_64" -DCMAKE_MAKE_PROGRAM="D:/Qt/Tools/Ninja/ninja.exe"
if errorlevel 1 (
    echo [ERROR] CMake configuration failed.
    pause
    exit /b 1
)

cmake --build build --config Release
if errorlevel 1 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo Deploying Qt libraries and QML plugins...
"D:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe" --qmldir resources/qml --no-translations "build\MusicDownloader.exe"

echo ====================================================
echo  Build and deployment completed successfully!
echo  Run 'run.bat' or 'build\MusicDownloader.exe'
echo ====================================================
pause
