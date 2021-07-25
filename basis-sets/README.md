# basis-sets

These files contain basis sets for GAMESS(US), that are not provided with the program by default. A lot of basis sets such as def2, calendar basis sets etc. are omitted in the program, so I put them together.

**Usage**:

You have to edit the rungms file and edit the environment variable EXTBAS (for basis sets) and EXTCAB (for RI-fitting basis sets). I usually put both files in the folder auxdata, and then edit the rungms file to ```EXTBAS=%AUXDATADIR%\EXTBASIS.txt```, and ```EXTCAB=%AUXDATADIR%\RIBAS.txt``` (for Windows x64, it can be different for other systems)

Due to the constraint that the basis set name in the external file cannot have more than 8 characters, and cannot match any of the internal basis sets, I had to shorten the names. The shortened names are explained below.

All basis set data I extracted from the psi4 code (https://github.com/psi4/psi4/tree/master/psi4/share/psi4/basis), and converted with basis_set_exchange python module. For a guide on which basis set and which RI-fitting basis set to be used together, go to http://www.psicode.org/psi4manual/master/basissets_byfamily.html. As GAMESS does not have a JK or J fitting method, so those basis sets have not been added to these files.

## Basis sets and their names

### Dunning type basis sets: (n=D,T,Q,5,6)

cc-PVnZ (original)- ccnor  
cc-PV(n+1)Z (newer) - ccnp   (p for +)  
cc-PCVnZ - cccn  
cc-PwCVnZ - ccwn  
cc-PVnZ-DK (relativistic) - ccndk  
cc-PVnZ-F12 - ccnf12  

etc.

Basically, the name is made by cc + c/w (c for PCVnZ, w for PwCVnZ)+ D/T/Q/5/6 + p (if n+1) + DK/F12


aug-cc-PVnZ (original) - augn  
aug-cc-PV(n+1)Z - augnp  
jun-cc-PV(n+1)Z - junnp  

etc.

The name is made by aug/jun/mar/feb + c/w + D/T/Q/5/6 + p + DK/F12

d-aug-PVnZ - daugn  
heavy-aug-PVnZ -haugn  

etc.

The name is made by h/d (h for heavy, d for d) + aug + D/T/Q/5/6 + p + DK/F12

Not all combinations are available in the file.

For Dunning basis sets, use spherical coordinates (ISPHER=1)

### Ahlrichs type basis sets:

def2-SVP - d2svp  
def2-SVPD - d2svpd  
def2-TZVP - d2tzvp  
def2-TZVPD - d2tzvpd  
def2-TZVPP - d2tzvpp  
def2-TZVPPD - d2tzvppd  

(If ECP is required, it has to be supplied manually)

Use spherical coordinates.

### Jensen type basis sets: (n=0,1,2,3,4)

pcSseg-n - pcssegn

Use spherical coordinates.

### Other basis sets:

psi3-dzp - p3dzp  
psi3-tz2p - p3tz2p  
psi3-tz2pf - p3tz2pf  

Use cartesian coordinates with these.

2zapa-nr - 2zapanr  
3zapa-nr - 3zapanr  
...  
6zapa-nr - 6zapanr

Use spherical coordinates with these.

ANO0 - ano0  

## RI-fitting basis sets

These are needed for RI-MP2 calculations. They have the same names as the main basis sets, but they are in the RIBAS.txt file.

----

If there are any problems, feel free to open an issue.
