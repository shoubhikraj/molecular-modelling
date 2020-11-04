#POVray wrapper script to include H-bonds for Avogadro (only)
import sys
import os
import math
import re
#
#path to POVray
POVpath='"pvengine64.exe"'
# If POVRay is not in path then use (for example)
# POVPath='"C:/Program Files/POV-Ray/v3.7/bin/pvengine64.exe"' (replace with the path in your case)
# the slashes must be front slashes like shown, otherwise the wrapper script won't run
#
def isclose(a, b, rel_tol=1e-09, abs_tol=0.0):
    return abs(a-b) <= max(rel_tol * max(abs(a), abs(b)), abs_tol)
#extracts coordinate and colors
def coord_color(text,index):
    #search for the first set of {}
    allArgs=re.search("\{([^}]+)\}",text[index:]).group(0)
    #extract the coord and color in string form
    coordTxt=re.search("<([^>]+)>",allArgs).group(0)[1:-1]
    colorTxt=re.search("<([^>]+)>",allArgs[allArgs.find('rgbt'):]).group(0)[1:-1]
    #extract numbers out of texts
    coord=tuple([float(k) for k in coordTxt.replace(' ','').split(',')])
    color=tuple([float(k) for k in colorTxt.replace(' ','').split(',')])
    return coord,color
#define colors for elements
oxygen_color=(1.0,0.05,0.05)
fluorine_color=(0.5, 0.6999, 1.0)
nitrogen_color=(0.05, 0.05, 1.0)
hydrogen_color=(0.75, 0.75, 0.75)
#
#calculates distance between points
def calc_dist(point1,point2):
    x1,y1,z1=point1[0],point1[1],point1[2]
    x2,y2,z2=point2[0],point2[1],point2[2]
    return math.sqrt((x1-x2)**2+(y1-y2)**2+(z1-z2)**2)
#converts color to element info
def color_to_element(colortuple):
    oxygenMatch=(isclose(colortuple[j],oxygen_color[j],rel_tol=1e-5) for j in range(0,3))
    nitrogenMatch=(isclose(colortuple[j],nitrogen_color[j],rel_tol=1e-5) for j in range(0,3))
    fluorineMatch=(isclose(colortuple[j],fluorine_color[j],rel_tol=1e-5) for j in range(0,3))
    hydrogenMatch=(isclose(colortuple[j],hydrogen_color[j],rel_tol=1e-5) for j in range(0,3))
    if sum(oxygenMatch)==3:
        return 'O'
    elif sum(nitrogenMatch)==3:
        return 'N'
    elif sum(fluorineMatch)==3:
        return 'F'
    elif sum(hydrogenMatch)==3:
        return 'H'
    else:
        return 'X'
#
#read in the arguments
keywords=sys.argv[1:]
#find the input file argument
for kword in keywords:
    isInput=(kword[0:2]=='+I')
    if isInput:
        inpFile=kword[2:]
        break
#read in the file
with open(inpFile,'r') as fileh:
    file_text=fileh.read()
#
#start sphere search
lastSphere=0
sphereLoc=0
atomList={}
l=0
#create a list of atoms
while lastSphere!=-1:
    #duplicate break condition given just for safety
    sphereLoc=file_text.find('sphere', sphereLoc+1)
    if sphereLoc==-1:
        break
    coordI,colorI=coord_color(file_text,sphereLoc)
    atomList[l]=(coordI,colorI)
    l=l+1
    lastSphere=sphereLoc
elementList=[color_to_element(atomList[m][1]) for m in range(len(atomList))]
activeHBD=[]
activeHBA=[]
for q in range(len(elementList)):
    if elementList[q]!='X':
        if elementList[q]=='H':
            activeHBD.append(q)
        else:
            activeHBA.append(q)
#generate all combinations of HBD and HBA
allCombs=[(s,q) for s in activeHBA for q in activeHBD]
#check for distances between atoms, and generate H-bonds between them this is crude but works!
addString=[]
HbondListString=''
for p in allCombs:
    distance=calc_dist(atomList[p[0]][0],atomList[p[1]][0])
    if (distance<=2.0)&(distance>0.6):
        addString.append('\ndashedLineL(<'+str(atomList[p[0]][0])[1:-1]+'> , <'+str(atomList[p[1]][0])[1:-1]+'>)')
        HbondListString=''.join(addString)
#
#this is the macro string, it defines the H-bond visualisation by POV-ray.
#change dashlength to change the sizes of dashes
#change lineradius to change the thickness of H-bonds
#change pigment to change the color of H-bond
HbondMacroString='\n#macro dashedLineL(_point1,_point2)\n  #declare dashLength = 0.05;\n  #declare lineRadius = 0.03;\n\n  #declare currentDashEnd = _point1;\n  #declare currentDashStart = <0,0,0>;\n  #declare lineDirection = vnormalize(_point2 - _point1);\n  #while (vlength(currentDashEnd - _point1) < vlength(_point2 - _point1))\n    #declare currentDashStart = currentDashEnd + (lineDirection * dashLength);\n    #declare currentDashEnd = currentDashEnd + (lineDirection * (dashLength*2));\n    cylinder{currentDashStart, currentDashEnd, lineRadius\n      pigment { rgb <0.6,0.6,0.6> }\n      finish { ambient 0.7 }\n    }\n  #end\n#end\n'
#
#need a merge statement in the end
endMergeString='\nmerge {\n}\n'
#generate the final file text to be written
append_text='\n'+HbondMacroString+HbondListString+endMergeString
with open(inpFile,'a') as wrfile:
    wrfile.write(append_text)
#make the arguments into a string to be passed onto POVray
kwstring=" ".join(keywords)
POVexecute=POVpath+' '+kwstring
#
os.system(POVexecute)
