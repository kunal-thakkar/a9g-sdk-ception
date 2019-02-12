
CSDTK 4 Instructions for use
================
CSDTK 4 is a compilation environment based on pure Windows applications and is no longer based on cygwin. Therefore, there will be better compatibility with different versions of Windows, and it can be easily integrated into various other development environments.
CSDTK 4 provides a compression package that can be decompressed for use anywhere (here C:\CSDTK4 is an example).
CSDTK 4 only contains tools needed for compilation, not including svn, gitversion management software.
CSDTK 4 and the path where the project is located should not contain special characters such as spaces and Chinese characters.
In the previous code could not be compiled under CSDTK 4, need to incorporate new code changes, as long as compilerules.mkwell as
 usrgen, resgenrelated changes.

Use CSDTK 4 under cmd.exe
---------------------
Example of compiling a BAT file:
```
call C:\CSDTK4\CSDTKvars.bat

set SOFT_WORKDIR=D:/projects/project/soft
set PATH=D:\projects\project\soft\env\utils;D:\projects\project\soft\env\win32;%PATH%
make -r -j4 CT_TARGET=target ......
```

`C:\CSDTK4\CSDTKvars.bat` The environment variables required for compilation will be set and then called make. Due to the work, ctmake
need for a bash environment, it is not available in the cmd.exe environment.

`SOFT_WORKDIR` Must be used /, cannot be used \.

Use CSDTK 4 under git-bash
----------------------

In $HOME/.bashrccase plus:
```
export PROJ_ROOT=$(cygpath -au d:/projects) # 或者其他任意路径
source $(cygpath -au c:/CSDTK4/CSDTKvars.sh)
```

Use the same as before:
```
$ work <project>
$ . env/launch.sh
$ ctmake ......
```

Since C:\CSDTK4\makesome of the applications below will conflict with git-bash, they will not be added to the PATH.
To use ctmaketo compile, don't use it make.
In addition to the git command itself, CSDTK 4 does not rely on other applications in git-bash, so upgrading git-bash does not affect compilation. It is recommended to install the latest version of git-bash.

Use CSDTK 4 under msys2
----------------------

Same as using under git-bash.

Use CSDTK 4 under cygwin
----------------------

In $HOME/.bashrccase plus:
```
export PROJ_ROOT=$(cygpath -au d:/projects) # 或者其他任意路径
source $(cygpath -au c:/CSDTK4/CSDTKvars.sh)
```

Use the same as before:
```
$ work <project>
$ . env/launch.sh
$ ctmake ......
```

Since `C:\CSDTK4\makesome` of the applications below will conflict with cygwin, they will not be added to the PATH.
To use `ctmaketo` compile, don't use it `make`. Cygwin comes with it that `make` doesn't compile properly.
In addition to the git, svn commands, CSDTK 4 does not depend on other applications in cygwin, so upgrading cygwin will not affect compilation. And can work under both cygwin and cygwin64. It is recommended to update cygwin regularly and use cygwin64 on 64-bit Windows operating systems.

Environmental variable description
----------

`CSDTKVER`: In order to be compatible with different versions of CSDTK, it should be set to under CSDTK 4 `4`.

`CSDTK4INSTALLDIR`: The path to CSDTK 4, for example `C:\CSDTK4`.