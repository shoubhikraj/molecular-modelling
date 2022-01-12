# PSF-reader

This is a stub program that reads the psf files written by molecular dynamics softwares (NAMD, CHARMM, XPLOR) etc. The program itself does not output anything on its own, it is intended to be used as a part of other programs. The PSF reading function is encapsulated in the function `bool read_PSF(string infile_name)`. The function takes the name of the input PSF file as it's input and returns true or false depending on whether reading was successful or not. If using it in a program, the function has to be modified to obtain whatever information is required (perhaps by passing a new variable as reference or by pointer).


Feel free to use it in your code, but please acknowledge. If you have any questions on using the code or any errors, open an issue.
