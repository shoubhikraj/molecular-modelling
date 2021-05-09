# MRCC compile script for Windows: S R Maiti, 4th May 2021
# Tested on Windows 10 with Intel oneAPI C++ and Fortran compilers version 2021.1
# (Also uses Intel MKL of the same version)
# 
# How to use script:
# 
# From powershell: .\compile.ps1 <options>
# 
# for example: .\compile.ps1 -dbg true -mkltype thread
#
# From command prompt: powershell.exe ".\compile.ps1 <options>"
# 
# When you run the command you might get an error saying the "script cannot be loaded
# because the execution of scripts is disabled on this system."
# In that case, use the following:
# 
# From command prompt: powershell.exe -ExecutionPolicy bypass .\compile.ps1 <options>
# 
# From powershell: Set-ExecutionPolicy -ExecutionPolicy bypass -Scope Process
# then run the compile script as usual.
#
# Command line options and their explanations:
# 
# .\compile.ps1 
#               -dbg <false|true>
# Option true turns on debugging mode so that the program is compiled with /Od and 
# /debug:full which turns off all optimizations and enables linking of debug information.
# Default is false, i.e. the program is compiled with /O3
#
#               -par <omp|serial>
# Option omp turns on OpenMP based parallelism. Option serial compiles the serial version
# of the program. Note that the program originally also contained an option to use MPI
# based parallelism. However, I have not tested that option on Windows, so this script
# does not contain the option to use MPI based parallelism
# Default is omp i.e. OpenMP parallelism is used.
#
#               -useipo <false|true>
# Option true turns on IPO (inter-procedural optimization) using the /Qipo flag on Intel
# compilers. There are supposed to be gains in the program efficiency and speed, but
# turning on this option will result in a *huge* link time. Use it only if you are sure.
# Default is false.
#
#               -mkltype <serial|thread>
# Option thread means the threaded version of Intel MKL is used. Option serial means the
# the sequential version of Intel MKL is used. If you are compiling for use on a system
# with a large number of CPU cores (>8) then the threaded version of MKL might be
# beneficial along with OpenMP threading for the main program. If you are compiling on a
# small machine (~4 core) then do not use -mkltype thread with -par omp. Because both the
# program and the MKL will attempt to use all cores at once, which doesn't give any
# benefit. Use either -mkltype thread with -par serial, or use -mkltype serial with
# -par omp.
#
#
# About the changes made:
#
# MRCC calls multiple commands like "cp", "mv", "rm", "cat" etc. to manipulate files.
# Unfortunately, those are all commands that are only available on the bash shell on Linux
# or other POSIX systems. On Windows, there are alternatives to those commands like "copy"
# or "move" etc. However, there are nearly 400 shell command calls in the whole program.
# It is possible to modify all of them. However, I tried to make sure that the source code
# is usable for all systems, i.e. the changed I have made are all guarded by #ifdef WINTEL
# so that the program can be compiled on Windows with /DWINTEL flag, and when the flag is
# not used, it gives the unchanged source code which can be compiled on Linux. This means
# the changes made to the source code are minimal.
# 
# I have only changed lines containing crucial commands like "echo" which behave 
# differently on Windows. I have also replaced the use of the "test -e" command with the
# Fortran inquire() statement. The ishell subroutine is used in this program as a wrapper
# for the system() call. I have replaced system() with execute_command_line which is
# defined in the Fortran 2008 standard and implemented in Intel Fortran v16 and later, 
# because there were reports of the system() call malfunctioning when the redirection
# operators ">" or ">>" were used, with some versions of Intel compilers.
# 
# There are only two files which need to be changed completely. First is "intio.c", this
# contains file open, close etc. C routines. Intel Fortran on windows exports all symbols
# in uppercase, without any trailing underscore (as opposed to gfortran which export
# lowercase symbols with underscore). So, the linker will look for those symbols in the C
# code. To fix this, the names of all C functions has to made uppercase and the underscore
# has to be removed. However, this changes "intio.c" so much, that there is no point in
# guarding the change with #ifdef's. So, I have modified the intio.c file completely and
# the modified version is only usable on windows with Intel compilers.
# 
# The other file is "xalloc.c". This is a C wrapper of the malloc() function. However, on
# Windows for some reason, this specific C-Fortran interface does not work (maybe because
# it uses the FC_FUNC() macro to bind C to Fortran). The solution is to use Fortran's own
# malloc() function, which is already provided in the archived source package as the file
# "xalloc.f90" which can act as a replacement on "xalloc.c". So, instead of compiling
# xalloc.c, "xalloc.f90" has to be compiled, and the object file linked to the packages.
#
# After compile:
# The shell commands need to be available from the Windows command prompt. The solution is
# to use GNUwin32 or Git-for-Windows. I have tested with Git-for-Windows, but GNUwin32 
# should work as well. The commands that are needed are cp, mv, cat, diff, grep, rm, sed
# and wc.
#
# Git-for-Windows- Download and install Git from https://git-scm.com/download/ . You can 
# also download the portable version. Then go to the directory where Git was installed, or
# extracted. In that directory, look for usr/bin/. From that directory copy cp.exe, mv.exe
# cat.exe, diff.exe, grep.exe, rm.exe, sed.exe and wc.exe into the directory where the
# MRCC executables are kept. Also copy from usr/bin/ the files msys-2.0.dll, 
# msys-iconv-2.dll, msys-intl-8.dll, msys-pcre-1.dll. These dll files are required to run
# the linux shell commands on command prompt. (Try double clicking each copied exe once to
# check if they run; if there is an error message saying that a dll file is missing, copy
# that from usr/bin/)
#
# GNUwin32- I have not personally tested this, but it should work. The executables for
# the shell commands should be put in the MRCC folder similar to what is mentioned above.
#
# Then, put the folder containing the MRCC executables (and the cp, mv etc. executables) 
# in PATH. You must be very careful about this, as messing up the path variable may cause
# Windows to stop working. Google how to do it if you are not sure.
# 
param (
  [string]$dbg = "false",
  [string]$par = "omp",
  [string]$useipo = "false",
  [string]$mkltype = "serial"
)
if (("$dbg" -ne "true") -and ("$dbg" -ne "false")) {
  echo "Please input only true or false with -dbg flag"
  exit
}
if (("par" -ne "serial") -and ("$par" -ne "omp")) {
  echo "Please input only serial or omp with -par flag"
  exit
}
if (("$useipo" -ne "true") -and ("$useipo" -ne "false")) {
  echo "Please input only true or false with -useipo flag"
  exit
}
if (("$mkltype" -ne "serial") -and ("$mkltype" -ne "thread")) {
  echo "Please input only serial or thread with -mkltype flag"
  exit
}
$opt1 = "/O3"
$opt2 = "/QxHost"
$ipo = "/Qipo-"
$ompopt1 = "/Qopenmp"
$ompopt2 = "/DOMP"
if ("$dbg" -eq "true") {$opt1, $opt2 = "/Od", "/debug:full"}
if ("$dbg" -eq "false") {$opt1, $opt2 = "/O3", "/QxHost"}
if ("$par" -eq "serial") {$ompopt1, $ompopt2 = "", ""}
if ("$par" -eq "omp") {$ompopt1, $ompopt2 = "/Qopenmp", "/DOMP"}
if ("$useipo" -eq "true") {$ipo = "/Qipo"}
if ("$useipo" -eq "false") {$ipo = "/Qipo-"}
if ("$mkltype" -eq "thread") {$mkl1, $mkl2, $mkl3 = "/Qmkl:parallel", "mkl_intel_thread.lib", "libiomp5md.lib"}
if ("$mkltype" -eq "serial") {$mkl1, $mkl2, $mkl3 = "/Qmkl:sequential", "mkl_sequential.lib", ""}
#
#
echo " "
echo "-----------------Compiling xalloc.f90-------------------"
echo " "
ifort /fpp /DWINTEL /DIntel /DINT64 /4I8 /assume:byterecl /c xalloc.f90
#
$mrccstuff = "counter counter_main mrcc goldstone lambda sacc pert combin mem qsorti xmrcc xlambda xpert xmem dcommunicate3 dmrcc flush integ ecp teint dfint df3int dfintloc df2intsubs dfint_triplets brasub intsub hrrspher dfint_triplets_rangesep intsub_rangesep df2intsubs_rangesep ellip orbloc mulli hessgrad scf diis ccsd uccsd minp ovirt prop propcore denschol pml bopu drpa ldrpa loccis drpagrad dft calcorb calcorbd calcorbh func pssp semint_shc laplace qmmod optim basopt cis geomopt compmod z2c freqdrv assembly oneint oneint_sh oneint_shc nucint nucint_shc onein1 onein1_sh onein1_shc nuceq1 nuceq1_shc nucat1 nucat1_shc mulint_shc intsub_ader hrrsub_ader intsub_bder hrrsub_bder intsub_cder hrrsub_cder brasub_1der ketsub_1der rearrsubs sphersubs dfintder1c dprscr dprscrsubs dfint_triplets_3der intsub_3der hrrsub_3der brasub_3der derspher_3der ccsdmain local"
$mrccstuff = -split $mrccstuff
# 
$mrccexe = "dmrcc mrcc xmrcc goldstone integ scf orbloc ccsd uccsd ovirt minp prop drpa cis mulli qmmod dirac_mointegral_export"
$mrccexe = -split $mrccexe
# 
$fortfilelist = $mrccstuff + $mrccexe
#
echo "----------Compiling Fortran Objects-------------"
echo " "
foreach ($f in $fortfilelist){
  $extf = ".\$f.f"
  $extf90 = ".\$f.f90"
  $fout = ".\$f.obj"
  if (Test-Path $extf) {$srcfile = $extf}
  if (Test-Path $extf90) {$srcfile = $extf90}
  if (("$f" -eq "dmrcc") -or ("$f" -eq "ovirt") -or ("$f" -eq "optim") -or ("$f" -eq "basopt") -or ("$f" -eq "geomopt") -or ("$f" -eq "compmod")) {
    if (!(Test-Path $fout)) {
      echo "Compiling $f with options /fpp /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL"
      ifort.exe /fpp /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL /c $srcfile
    }
  }
  else {
    if (!(Test-Path $fout)) {
      echo "Compiling $f with options /fpp /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2"
      ifort /fpp /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /c $srcfile
    }
  }
}
echo " "
echo "------------Done with Fortran Files------------"
$cfilelist ="intio signal cfunc"
$cfilelist = -split $cfilelist
echo " "
echo "-------------Compiling C Objects---------------"
echo " "
#
# adding /DINT64 causes problems with header files on Intel C++ v2021, maybe INT64 macro 
# is defined somewhere else internally
#
foreach ($f in $cfilelist){
  $srcfile = "$f.c"
  $fout = ".\$f.obj"
  if (!(Test-Path $fout)) {
    icl.exe /DIntel /DWINTEL $opt2 /c $srcfile
  }
}
echo "--------------Done with C files--------------"
$done = "true"
echo " "
echo "--------------Linking Goldstone----------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:goldstone.exe goldstone.obj mem.obj xalloc.obj combin.obj signal.obj qsorti.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\goldstone.exe)) {$done = "false"}
echo " "
echo "----------------Linking mrcc------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:mrcc.exe mrcc.obj lambda.obj pert.obj mem.obj xalloc.obj combin.obj signal.obj flush.obj sacc.obj dcommunicate3.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\mrcc.exe)) {$done = "false"}
echo " "
echo "----------------Linking integ-----------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:integ.exe integ.obj teint.obj ecp.obj dfint.obj df3int.obj dfintloc.obj df2intsubs.obj hrrspher.obj dfint_triplets.obj brasub.obj intsub.obj intsub_ader.obj hrrsub_ader.obj intsub_bder.obj hrrsub_bder.obj intsub_cder.obj hrrsub_cder.obj brasub_1der.obj ketsub_1der.obj rearrsubs.obj sphersubs.obj dfintder1c.obj dprscr.obj dprscrsubs.obj dfint_triplets_3der.obj intsub_3der.obj hrrsub_3der.obj brasub_3der.obj derspher_3der.obj dfint_triplets_rangesep.obj intsub_rangesep.obj df2intsubs_rangesep.obj ellip.obj calcorb.obj mem.obj xalloc.obj combin.obj signal.obj intio.obj z2c.obj oneint.obj oneint_sh.obj oneint_shc.obj nucint.obj nucint_shc.obj onein1.obj onein1_sh.obj onein1_shc.obj nuceq1.obj nuceq1_shc.obj nucat1.obj nucat1_shc.obj mulint_shc.obj cfunc.obj flush.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\integ.exe)) {$done = "false"}
echo " "
echo "-----------------Linking scf------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:scf.exe scf.obj hessgrad.obj diis.obj teint.obj ecp.obj dfint.obj df3int.obj dfintloc.obj df2intsubs.obj hrrspher.obj dfint_triplets.obj brasub.obj intsub.obj intsub_ader.obj hrrsub_ader.obj intsub_bder.obj hrrsub_bder.obj intsub_cder.obj hrrsub_cder.obj brasub_1der.obj ketsub_1der.obj rearrsubs.obj sphersubs.obj dfintder1c.obj dprscr.obj dprscrsubs.obj dfint_triplets_3der.obj intsub_3der.obj hrrsub_3der.obj brasub_3der.obj derspher_3der.obj dfint_triplets_rangesep.obj intsub_rangesep.obj df2intsubs_rangesep.obj ellip.obj dft.obj calcorb.obj calcorbd.obj calcorbh.obj func.obj pssp.obj semint_shc.obj mem.obj xalloc.obj combin.obj signal.obj intio.obj denschol.obj pml.obj bopu.obj nucint.obj nucint_shc.obj oneint_sh.obj onein1.obj onein1_sh.obj onein1_shc.obj nuceq1.obj nuceq1_shc.obj nucat1.obj nucat1_shc.obj mulint_shc.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\scf.exe)) {$done = "false"}
echo " "
echo "-----------------Linking ovirt------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:ovirt.exe ovirt.obj intio.obj combin.obj signal.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\ovirt.exe)) {$done = "false"}
echo " "
echo "-----------------Linking orbloc------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:orbloc.exe orbloc.obj mem.obj xalloc.obj combin.obj signal.obj denschol.obj pml.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\orbloc.exe)) {$done = "false"}
echo " "
echo "-----------------Linking mulli------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:mulli.exe mulli.obj mem.obj xalloc.obj combin.obj signal.obj bopu.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\mulli.exe)) {$done = "false"}
echo " "
echo "-----------------Linking prop------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:prop.exe prop.obj propcore.obj denschol.obj diis.obj teint.obj ecp.obj dfint.obj df3int.obj dfintloc.obj df2intsubs.obj hrrspher.obj dfint_triplets.obj brasub.obj intsub.obj intsub_ader.obj hrrsub_ader.obj intsub_bder.obj hrrsub_bder.obj intsub_cder.obj hrrsub_cder.obj brasub_1der.obj ketsub_1der.obj rearrsubs.obj sphersubs.obj dfintder1c.obj dprscr.obj dprscrsubs.obj dfint_triplets_3der.obj intsub_3der.obj hrrsub_3der.obj brasub_3der.obj derspher_3der.obj dfint_triplets_rangesep.obj intsub_rangesep.obj df2intsubs_rangesep.obj ellip.obj dft.obj calcorb.obj calcorbd.obj calcorbh.obj func.obj pssp.obj semint_shc.obj pml.obj mem.obj xalloc.obj combin.obj signal.obj intio.obj nucint.obj nucint_shc.obj oneint_sh.obj onein1.obj onein1_sh.obj onein1_shc.obj nuceq1.obj nuceq1_shc.obj nucat1.obj nucat1_shc.obj mulint_shc.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\prop.exe)) {$done = "false"}
echo " "
echo "-----------------Linking ccsd------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:ccsd.exe ccsd.obj ccsdmain.obj diis.obj laplace.obj mem.obj xalloc.obj combin.obj signal.obj assembly.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\ccsd.exe)) {$done = "false"}
echo " "
echo "-----------------Linking uccsd------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:uccsd.exe uccsd.obj diis.obj mem.obj xalloc.obj combin.obj assembly.obj signal.obj laplace.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\uccsd.exe)) {$done = "false"}
echo " "
echo "-----------------Linking xmrcc------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:xmrcc.exe xmrcc.obj xlambda.obj xpert.obj xmem.obj combin.obj signal.obj xalloc.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\xmrcc.exe)) {$done = "false"}
echo " "
echo "-----------------Linking drpa------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:drpa.exe drpa.obj ldrpa.obj loccis.obj drpagrad.obj laplace.obj teint.obj ecp.obj dfint.obj df3int.obj dfintloc.obj df2intsubs.obj hrrspher.obj dfint_triplets.obj brasub.obj intsub.obj intsub_ader.obj hrrsub_ader.obj intsub_bder.obj hrrsub_bder.obj intsub_cder.obj hrrsub_cder.obj brasub_1der.obj ketsub_1der.obj rearrsubs.obj sphersubs.obj dfintder1c.obj dprscr.obj dprscrsubs.obj dfint_triplets_3der.obj intsub_3der.obj hrrsub_3der.obj brasub_3der.obj derspher_3der.obj dfint_triplets_rangesep.obj intsub_rangesep.obj df2intsubs_rangesep.obj ellip.obj calcorb.obj mem.obj xalloc.obj combin.obj signal.obj intio.obj bopu.obj assembly.obj oneint.obj oneint_sh.obj oneint_shc.obj onein1.obj onein1_sh.obj onein1_shc.obj nuceq1.obj nuceq1_shc.obj nucat1.obj nucat1_shc.obj mulint_shc.obj ccsd.obj diis.obj local.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\drpa.exe)) {$done = "false"}
echo " "
echo "-----------------Linking cis------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:cis.exe cis.obj diis.obj laplace.obj teint.obj bopu.obj ecp.obj dfint.obj df3int.obj dfintloc.obj df2intsubs.obj hrrspher.obj dfint_triplets.obj brasub.obj intsub.obj intsub_ader.obj hrrsub_ader.obj intsub_bder.obj hrrsub_bder.obj intsub_cder.obj hrrsub_cder.obj brasub_1der.obj ketsub_1der.obj rearrsubs.obj sphersubs.obj dfintder1c.obj dprscr.obj dprscrsubs.obj dfint_triplets_3der.obj intsub_3der.obj hrrsub_3der.obj brasub_3der.obj derspher_3der.obj dfint_triplets_rangesep.obj intsub_rangesep.obj df2intsubs_rangesep.obj ellip.obj calcorb.obj mem.obj xalloc.obj combin.obj signal.obj dft.obj calcorbd.obj calcorbh.obj func.obj pssp.obj semint_shc.obj intio.obj nucint.obj nucint_shc.obj oneint_sh.obj onein1.obj onein1_sh.obj onein1_shc.obj nuceq1.obj nuceq1_shc.obj nucat1.obj nucat1_shc.obj mulint_shc.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\cis.exe)) {$done = "false"}
echo " "
echo "-----------------Linking minp------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:minp.exe minp.obj combin.obj signal.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\minp.exe)) {$done = "false"}
echo " "
echo "-----------------Linking qmmod------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:qmmod.exe qmmod.obj combin.obj signal.obj mem.obj xalloc.obj bopu.obj cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\qmmod.exe)) {$done = "false"}
echo " "
echo "---------Linking dirac_mointegral_export-----------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:dirac_mointegral_export.exe dirac_mointegral_export.F90 cfunc.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\dirac_mointegral_export.exe)) {$done = "false"}
echo " "
echo "-----------------Linking dmrcc------------------"
ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:dmrcc.exe dmrcc.obj basopt.obj geomopt.obj optim.obj combin.obj signal.obj z2c.obj freqdrv.obj cfunc.obj compmod.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib
if (!(Test-Path .\dmrcc.exe)) {$done = "false"}
echo " "
# Counter is only needed for MPI parallel version of MRCC
# echo "-----------------Linking counter------------------"
# ifort.exe /4I8 /assume:byterecl $opt1 $opt2 $ipo /DIntel /DINT64 /DWINTEL $ompopt1 $ompopt2 /Fe:counter.exe counter_main.obj counter.obj cfunc_mpi.obj combin_mpi.obj signal.obj $mkl1 mkl_blas95_ilp64.lib mkl_lapack95_ilp64.lib mkl_intel_ilp64.lib $mkl2 $mkl3 mkl_core.lib

if ("$done" -eq "true") {
  echo "---------------Compilation finished!----------------"
  echo " "
  echo "Don't forget to put the folder containing the executables on PATH !"
  echo "The program also needs linux utilities: cp, mv, grep, sed, wc, cat, diff and rm"
  echo " "
} else {
  echo "---------------Compilation failed!------------------"
  echo " "
  echo "Check if the compile environment has been setup correctly,"
  echo "you may need to run the setvars.bat or psxevars.bat script."
  echo " "
  echo "Also check whether all parts of the oneAPI toolkit or the"
  echo "parallel studio were installed properly. For compiling the"
  echo "Intel Fortran and C++ compiler and Intel MKL are required."
}
exit