# MRCC compile script for Windows #
This is a compile script that I wrote for the program MRCC (www.mrcc.hu/) to serve as a replacement of the default shell script that is used to compile the program on POSIX systems.

To compile, you need to access the source code from www.mrcc.hu and change some of the source files (as mentioned [here](https://mrcc.hu/index.php/forum/users-corner/250-native-compile-of-mrcc-on-windows) )

The command line options and instructions for running are in the script (open with notepad).

To run the script on Windows—

From Powershell: `.\compile.ps1 <options>`

From command prompt: `powershell .\compile.ps1 <options>`
  
If execution is disallowed by policy, then try from command prompt: `powershell -ExecutionPolicy bypass .\compile.ps1 <options>`

If execution is disallowed, and bypassing of execution policy is also disallowed then you can do the following:

1) First, open the script file (compile.ps1) with Notepad or other text editors. Find the part where the actual script begins with `param(  [String]$dbg `...
2) Then change the default values of the parameters to those you want, because you would not be able to use command line arguments
3) Then open powershell and type `Get-Content .\compile.ps1 | powershell -noprofile -`

Run `.\compile.ps1 -help` for a brief overview of the compile options. Detailed information is present inside the compile script as comments, open it with a text editor to read them.
