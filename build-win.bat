set BASE_DIR=%CD%

:DEPS
cd %BASE_DIR%
mkdir pdfium_deps
cd pdfium_deps
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
git clone https://chromium.googlesource.com/external/gyp.git
set PATH=%BASE_DIR%\pdfium_deps\depot_tools;%PATH%

cd gyp
python setup.py install

:PDFIUM
cd %BASE_DIR%
git clone https://github.com/rouault/pdfium
cd pdfium
git checkout win_gdal_build
cd ..

:BUILD
xcopy /E /I pdfium pdfium-x64
ren pdfium pdfium-x86

REM Building x64
cd %BASE_DIR%\pdfium-x64
python build\gyp_pdfium.py
echo call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86_amd64 > build_x64.bat
echo msbuild build\all.sln /p:Configuration=Release /p:Platform=x64 /m >> build_x64.bat
cmd /c build_x64.bat

REM Building x86
cd %BASE_DIR%\pdfium-x86
python build\gyp_pdfium.py
echo call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86 > build_x86.bat
echo msbuild build\all.sln /p:Configuration=Release /p:Platform=Win32 /m >> build_x86.bat
cmd /c build_x86.bat

