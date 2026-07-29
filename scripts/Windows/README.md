# Compiling Kathara for Windows

## On Windows

1. Download and Install Inno Setup ([Quick link](http://www.jrsoftware.org/download.php/is.exe) or `winget install -e --id JRSoftware.InnoSetup --accept-source-agreements --accept-package-agreements --scope machine`)
2. Download and Install Python 3.13 ([Quick link](https://www.python.org/downloads/release/python-31311/) or `winget install -e --id Python.Python.3.13 --accept-source-agreements --accept-package-agreements`)
3. Add Inno Setup and Python 3.13 to the PATH environment variable (`SET PATH=%PATH%;%programfiles(x86)%\Inno Setup 6\`)
4. Change the Kathara version number in both `src/Kathara/version.py` and `installer.iss` files.
5. Create binary package running `WindowsBuild.bat`
6. Share the `Kathara-setup.exe` in output folder :)

## On Linux and MacOS

1. Change the Kathara version number in the following files:
    1. `src/Kathara/version.py`
    2. `Makefile`
3. Run `make all`. This will:
    1. Run a Docker container with pyinstaller over wine.
    2. Compile Kathara into a binary.
    3. Run a Docker container with InnoSetup over wine.
    4. Compile an installer for the binary above. 
    5. Automatically remove the containers.
4. Output file is located in the `Output` directory
