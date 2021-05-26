The benchmark-dft.py is a simple file that takes a `template.inp` input file, replaces `B3LYP` with names of other functionals, and then runs them with a QM code. This is mainly for the purposes of benchmarking various density functionals. Feel free to take the script and edit it to suit your purpose.

### Sample run with GAMESS: ###

1) Put the input file (template.inp) in the GAMESS folder where rungms is present. (The template runs energy of methane with 6-31G(d) basis)
2) Open the terminal or command prompt and run `python benchmark-dft.py`
3) The input files with wB97X-D, M06-2X, MN15, revM11 and TPSS functionals will be written and ran with GAMESS.
4) The output files will be written as output_wB97X-D.log etc.


The list of functionals can be edited in the .py file. There is also the option to read the list of functionals from a text file where the names are separated by a space. (That part of the code is commented out in the .py file).
