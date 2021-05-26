import os
import sys

# list of density functionals
dft_list = ["wB97X-D", "M06-2X", "MN15", "REVM11","TPSS"]

# optionally, read this in from a text file where the functionals
# are separated by space
#with open("dft_list.txt", "r") as dft_file_hnd:
#    dft_list=dft_file_hnd.read().replace("\n","").replace("\r","").split(" ")

# Iterate through dft_list
if os.path.isfile("template.inp")==False:
    print("Unable to find template file template.inp")
    print("Template file template.inp is required!")
    print("Exiting...")
    sys.exit()
for functional in dft_list:
    # write the new input files as input_M06-2X.inp etc.
    # Warning! the name of the functional must not contain unusual
    # characters which cannot be used as file names
    new_file_name = "input_" + functional + ".inp"
    if os.path.isfile(new_file_name):
        print("File:",new_file_name," already exists!")
        print("Please delete it before proceeding")
        print("Exiting...")
        break
    new_file_hnd = open(new_file_name,"a")
    with open("template.inp", "r") as temp_file_hnd:
        for line in temp_file_hnd:
            # search and replace B3LYP with new functional
            line = line.replace("B3LYP",functional)
            # write line into new input file
            new_file_hnd.write(line)
    new_file_hnd.close()
    # optionally, run the input files with a QM program
    #output files are named output_M06-2X.log etc.
    print("")
    print("Written ",new_file_name)
    out_file_name = "output_" + functional + ".log"
    print("Running input file:",new_file_name)
    command_string="rungms " + new_file_name + " 00 1 >" + out_file_name
    os.system(command_string)
    # This runs input files with gamess.00.exe with 1 processes (uses rungms)
