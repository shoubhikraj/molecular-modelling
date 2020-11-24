# POV-ray-hbond

The python script adds hydrogen bonds to a .pov file. Intended to be used directly from Avoagadro. Tested only with Avogadro 1.2.0 and Python 3.7. However, it can be used directly from command line, without needing Avogadro.

**Usage:**

From Avogadro:

In File>Export>POV-ray, change the path to ```python <path-to-py-file>```. Then pressing Render should work.

Note that if the <path-to-py-file> contains spaces, it must be enclosed with double quotes (" ").

From command line:

Use ```python <path-to-py-file> <POV-ray-options>```

The python script automatically intercepts the arguments and passes them onto POV-ray

*Note:* The python script assumes that the POV-ray executable is in the PATH. If it's not then add it to the PATH. Otherwise, you can edit the script and add the full path of the executable (Usually this is named pvengine64.exe in Windows x64). In the script the executable path is determined by the variable ```POVpath``` (which is right at the beginning)
