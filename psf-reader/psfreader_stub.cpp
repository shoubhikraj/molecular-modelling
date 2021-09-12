#include <iostream>
#include <cstdio>
#include <fstream>
#include <string>
#include <map>
#include <utility>
#include <tuple>
#include <vector>
#include <array>
#include <cerrno>
#include <sstream>
#include <algorithm>
#include <stdexcept>

// C++11 required

using std::cout;
using std::cerr;
using std::getline;
using std::string;

bool read_header(const string& line, std::map<string,bool>& properties);
bool read_ATOM_field(std::ifstream& infile,size_t start_line,std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double> >& data,const std::map<string, bool>& header_properties);
bool read_ATOM_line_NAMD(const string& line, std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double> >& data,bool is_cheq);
bool read_ATOM_line_CHARMM(const string& line, std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double> >& data,bool is_cheq,bool is_ext);
string string_trim_and_check(string s);
bool read_BOND_field(std::ifstream& infile, size_t start_line, std::vector<std::array<size_t,2>>& data);
bool read_THETA_field(std::ifstream& infile, size_t start_line, std::vector<std::array<size_t,3>>& data);
bool read_PHI_IMPHI_field(std::ifstream& infile,size_t start_line,std::vector<std::array<size_t,4>>& data,const string& dihed_type);
bool read_PSF(string infile_name);

int main() {
    bool done;
    try {
        done = read_PSF("testfile.psf");
    }
    catch (const ifstream::failure& ifstr_fail) {
        perror(("Error while reading file "+infile_name+"\n").c_str());
        exit(1);
    }
    if (done) {
        cout << "psf-reader> Successfully read PSF file\n";
    }
    else {
        cout << "psf-reader> Failure in reading PSF file\n";
    }
    return 0;
}

bool read_PSF(string infile_name) {
    
    string line;
    size_t counter = 0; // stores the line number
    std::map<string, bool> header_properties = {{"CMAP",false}, {"EXT",false}, {"XPLOR",false}, {"CHEQ",false}, {"NAMD",false}};
    bool got_header=false;
    std::map<string, bool> is_present_field = {
        {"NATOM",false}, {"NBOND",false}, {"NTHETA",false}, {"NPHI",false}, {"NIMPHI",false}, {"NCRTERM",false}, {"NDON",false}, {"NACC",false}, {"NNB",false}, {"NGRP",false}, {"NUMLP",false},{"MOLNT",false}
    }; // are there any other fields?
    std::map<string, size_t> field_line_num;
    // open input file
    std::ifstream input_file;
    input_file.exceptions(std::ifstream::badbit);
    
    input_file.open(infile_name.c_str());
    if (!input_file.is_open()) {
        cout << "psf-reader> Input file " << infile_name << " does not exist is or cannot be opened\n";
    }
    
    while(getline(input_file, line)) {
        counter++;
        if (!got_header) {
            got_header = read_header(line,header_properties);
        }
        else {
            for (auto& field : is_present_field) {
                if (!field.second) { // if that field has not been found
                    if (line.find(field.first) != string::npos) {
                        field_line_num[field.first] = counter;
                        field.second = true; // set field to found
                    }
                }
            }
        }
    }
    bool psf_read_success = false;
    // ATOM field:
    // atID,segName,resID,resName,atName,atType,charge,mass,selection,*polarizability,TholeScaleFactor
    // II,LSEGID,LRESID,LRES,TYPE(I),IAC(I),CG(I),AMASS(I),IMOVE(I),ECH(I),ECA(I)
    // int, str,   str, str,  str,    str,  float,  float,   int,   float, float
    std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double>> ATOM_data;
    if (is_present_field.at("NATOM")) {
        auto is_atom_read = read_ATOM_field(input_file,field_line_num.at("NATOM"),ATOM_data,header_properties);
        if (is_atom_read) {
            // do something
            psf_read_success = true; // NATOMS must be present in psf!!
        }
 
    }
    // BOND field: space separated
    std::vector<std::array<size_t,2>> BOND_data;
    if (is_present_field.at("NBOND")) {
        auto is_bond_read = read_BOND_field(input_file,field_line_num.at("NBOND"),
        BOND_data);
        if (is_bond_read) {
            // do something
        }
        else {
            psf_read_success = false;
        }
    }
    // THETA field: space separated (angles)
    std::vector<std::array<size_t,3>> THETA_data;
    if (is_present_field.at("NTHETA")) {
        auto is_theta_read = read_THETA_field(input_file,field_line_num.at("NTHETA"),THETA_data);
        if (is_theta_read) {
            // do something
        }
        else {
            psf_read_success = false;
        }

    }
    // PHI field: space separated (proper dihedrals)
    std::vector <std::array<size_t,4>> PHI_data;
    if (is_present_field.at("NPHI")) {
        auto is_phi_read = read_PHI_IMPHI_field(input_file,field_line_num.at("NPHI"),PHI_data,"NPHI");
        if (is_phi_read) {
            // do something
        }
        else {
            psf_read_success = false;
        }
    }
    // IMPHI field: space separated (improper dihedrals)
    std::vector <std::array<size_t,4>> IMPHI_data;
    if (is_present_field.at("NIMPHI")) {
        auto is_imphi_read = read_PHI_IMPHI_field(input_file,field_line_num.at("NIMPHI"),IMPHI_data,"NIMPHI");
        if (is_imphi_read) {
            // do something
        }
        else {
            psf_read_success = false;
        }
    }

    input_file.close();
    return psf_read_success;
}

bool read_PHI_IMPHI_field(std::ifstream& infile,size_t start_line,std::vector<std::array<size_t,4>>& data,const string& dihed_type) {
    infile.clear();
    infile.seekg(0);
    
    size_t counter = 0;
    string line;
    while(getline(infile,line)) {
        counter++;
        if (counter >= start_line) {
            break; // goto line containing NPHI/NIMPHI
        }
    }
    
    size_t ndiheds;
    if (line.find("!") != string::npos) {
        auto ndiheds_str = line.substr(0,line.find("!"));
        ndiheds = std::stoull(ndiheds_str); // have to handle exceptions cerr
    }
    else {
        cerr << "Error in reading number of dihedrals/impropers\n";
        exit(1);
    }
    //size_t counter_old = counter;
    std::array<size_t,4> dihed1, dihed2; // holds the two dihedrals for each line
    while(getline(infile,line)) {
        counter++;
        if (line.empty()) {
            break;
        }
        if (data.size() == ndiheds) {
            break;
        }
        try {
            std::istringstream iss(line);
            iss.exceptions(std::ios::failbit|std::ios::badbit);
            // 2 dihedrals in one line
            size_t atom1, atom2, atom3, atom4, atom5, atom6, atom7, atom8;
            iss >> atom1 >> atom2 >> atom3 >> atom4 ;
            dihed1 = {{atom1,atom2,atom3,atom4}};
            data.push_back(dihed1); // put into data vector
            iss >> atom5 >> atom6 >> atom7 >> atom8;
            dihed2 = {{atom5,atom6,atom7,atom8}};
            data.push_back(dihed2);
        }
        catch (std::ios::failure& issfail) {
            break;
        }
    }
    if (data.size() != ndiheds) {
    cerr << "psf-reader> Unable to read " << ndiheds << " dihedrals/impropers as declared before " << "!" << dihed_type << "\n";
    cerr << "psf-reader> Error in line number " << counter<<"\n";
    return false;
    }
    return true;
}

bool read_THETA_field(std::ifstream& infile, size_t start_line, std::vector<std::array<size_t,3>>& data) {
    infile.clear();
    infile.seekg(0);
    
    size_t counter = 0;
    string line;
    while(getline(infile,line)) {
        counter++;
        if (counter >= start_line) {
            break; // goto line containing NTHETA
        }
    }
    
    size_t nangles;
    if (line.find("!") != string::npos) {
        auto nangles_str = line.substr(0,line.find("!"));
        nangles = std::stoull(nangles_str); // have to handle exceptions cerr
    }
    else {
        cerr << "Error in reading number of angles\n";
        exit(1);
    }
    //size_t counter_old = counter;
    std::array<size_t,3> angle1, angle2, angle3;
    while(getline(infile,line)) {
        counter++;
        if (line.empty()) {
            break;
        }
        if (data.size() == nangles) {
            break;
        }
        try {
            std::istringstream iss(line);
            iss.exceptions(std::ios::failbit|std::ios::badbit);
            // 3 bonds in one line
            size_t atom1, atom2, atom3, atom4, atom5, atom6, atom7, atom8,atom9;
            iss >> atom1 >> atom2 >> atom3;
            angle1 = {{atom1,atom2,atom3}};
            data.push_back(angle1); // put into data vector
            iss >> atom4 >> atom5 >> atom6;
            angle2 = {{atom4,atom5,atom6}};
            data.push_back(angle2);
            iss >> atom7 >> atom8 >> atom9;
            angle3 = {{atom7,atom8,atom9}};
            data.push_back(angle3);            
        }
        catch (std::ios::failure& issfail) {
            break;
        }
    }
    if (data.size() != nangles) {
    cerr << "psf-reader> Unable to read " << nangles << " angles as declared before !NTHETA\n";
    cerr << "psf-reader> Error in line number " << counter<<"\n";
    return false;
    }
    return true;
}

/* This section reads the !NBOND section */
bool read_BOND_field(std::ifstream& infile, size_t start_line, std::vector<std::array<size_t,2>>& data) {
    // rewind ifstream
    infile.clear();
    infile.seekg(0);
    
    size_t counter = 0;
    string line;
    while(getline(infile,line)) {
        counter++;
        if (counter >= start_line) {
            break; // goto line containing NBOND
        }
    }
    
    size_t nbonds;
    if (line.find("!") != string::npos) {
        auto nbonds_str = line.substr(0,line.find("!"));
        nbonds = std::stoull(nbonds_str); // have to handle exceptions cerr
    }
    else {
        cerr << "Error in reading number of bonds\n";
        exit(1);
    }
    size_t counter_old = counter;
    std::array<size_t,2> bond1, bond2, bond3,bond4;
    while(getline(infile,line)) {
        counter++;
        try {
            std::istringstream iss(line);
            iss.exceptions(std::ios::failbit|std::ios::badbit);
            // Four pairs of atom indices in one line
            size_t atom1, atom2, atom3, atom4, atom5, atom6, atom7, atom8;
            iss >> atom1 >> atom2 >> atom3 >> atom4 >> atom5 >> atom6 >> atom7 >> atom8;
            bond1 = {{atom1,atom2}};
            bond2 = {{atom3,atom4}};
            bond3 = {{atom5,atom6}};
            bond4 = {{atom7,atom8}};
            data.push_back(bond1); // put into data vector
            data.push_back(bond2);
            data.push_back(bond3);
            data.push_back(bond4);
        }
        catch (std::ios::failure& issfail) {
            break;
        }
        if ((counter - counter_old) == nbonds) {
            break;
        }
    }
    if (data.size() != nbonds) {
    cerr << "psf-reader> Unable to read " << nbonds << " bonds as declared before !NBONDS\n";
    cerr << "psf-reader> Error in line number " << counter<<"\n";
    return false;
    }
    return true;
    
}



/* This section reads the !NATOM section of the psf */
bool read_ATOM_field(std::ifstream& infile,size_t start_line,std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double> >& data,const std::map<string, bool>& header_properties) {
    // rewind ifstream
    infile.clear();
    infile.seekg(0);
    
    size_t counter = 0;
    string line;
    while(getline(infile,line)) {
        counter++;
        if (counter >= start_line) {
            break; // go to the line containing NATOM
        }
    }
    // The first line of ATOM filed is like this: "    34 !NATOM"
    size_t natoms;
    if (line.find("!") != string::npos) {
        auto natoms_str = line.substr(0,line.find("!"));
        natoms = std::stoull(natoms_str); // have to handle exceptions cerr
    }
    else {
        cerr << "Error in reading number of atoms\n";
        exit(1);
    }
    size_t counter_old = counter;
    // handle different flavours
    bool is_cheq = header_properties.at("CHEQ");
    bool is_ext = header_properties.at("EXT");
    bool is_namd = header_properties.at("NAMD");
    // read until all atoms are obtained
    bool success;
    if (is_namd) {
        while(getline(infile,line)) {
            counter++;
            success = read_ATOM_line_NAMD(line,data,is_cheq);
            if (!success) {
                break;
            }
            if ((counter - counter_old) == natoms) {
                break;
            }
        }
        if (data.size() != natoms) {
            cerr << "psf-reader> Unable to read " << natoms << " atoms as declared before !NATOMS\n";
            cerr << "psf-reader> Error in line number " << counter<<"\n";
            return false;
        }
        return true;
    }
    else {
        while(getline(infile,line)) {
            counter++;
            success = read_ATOM_line_CHARMM(line,data,is_cheq,is_ext);
            // throws invalid_argument exception from substr => caught
            if (!success) {
                break;
            }
            if ((counter - counter_old) == natoms) {
                break;
            }
        }
        if (data.size() != natoms) {
            cerr << "psf-reader> Unable to read " << natoms << " atoms as declared before !NATOMS\n";
            cerr << "psf-reader> Error in line number " << counter <<"\n";
            return false;
        }
        return true;
    }
}

bool read_ATOM_line_NAMD(const string& line, std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double> >& data,bool is_cheq) {
    if (line.empty()) return false;
    unsigned long long atID;
    string segName;
    string resID;
    string resName;
    string atomName;
    string atomType;
    double charge;
    double mass;
    int move; 
    double ECH;
    double ECA;
    if (!is_cheq) {
        ECH = 0.0;
        ECA = 0.0;
    }
    std::istringstream iss(line);
    iss.exceptions(std::ios::failbit|std::ios::badbit);
    try {
        if (is_cheq) {
            iss >> atID >> segName >> resID >> resName >> atomName >> atomType >> charge >> mass >> move >> ECH >> ECA;
        }
        else {
            iss >> atID >> segName >> resID >> resName >> atomName >> atomType >> charge >> mass >> move; 
        }
    }
    catch (std::ios::failure& issfail) {
        return false;
    }
    data.push_back(std::make_tuple(atID,segName,resID,resName,atomName,atomType,charge,mass,move,ECH,ECA));
    return true;
}
/* This function reads the standard column formatted files. Even though the name is
 CHARMM, it reads both XPLOR and CHARMM formatted files (also CHEQ and EXT). For 
 CHARMM format, the atomType is returned as a string however, i.e. in XPLOR format.*/
bool read_ATOM_line_CHARMM(const string& line, std::vector<std::tuple<unsigned long long,string,string,string,string,string,double,double,int,double,double> >& data,bool is_cheq,bool is_ext) {
    if (line.empty()) return false;
    // atID,segName,resID,resName,atName,atType,charge,mass,selection,*polarizability,TholeScaleFactor
    // II,LSEGID,LRESID,LRES,TYPE(I),IAC(I),CG(I),AMASS(I),IMOVE(I),ECH(I),ECA(I)
    // int, str,   str, str,  str,    str,  float,  float,   int,   float, float
    // (I10,1X,A8,1X,A8,1X,A8,1X,A8,1X,A4,1X,2G14.6,I8,2G14.6) for EXT
    // (I8,1X,A4,1X,A4,1X,A4,1X,A4,1X,A4,1X,2G14.6,I8,2G14.6) for standard
    unsigned long long atID;
    string segName;
    string resID;
    string resName;
    string atomName;
    string atomType;
    double charge;
    double mass;
    int move; 
    double ECH;
    double ECA;
    if (!is_cheq) {
        ECH = 0.0;
        ECA = 0.0;
    }
    try {
        if (is_ext) {
            atID = std::stoull(string_trim_and_check(line.substr(0,10))); // I10
            segName = string_trim_and_check(line.substr(11,8)); // 1X,A8
            resID = string_trim_and_check(line.substr(20,8)); // 1X,A8
            resName = string_trim_and_check(line.substr(29,8)); // 1X,A8
            atomName = string_trim_and_check(line.substr(38,8)); // 1X,A8
            atomType = string_trim_and_check(line.substr(47,4)); // 1X,A4
            charge = std::stod(string_trim_and_check(line.substr(52,14))); // 1X,G14.6
            mass = std::stod(string_trim_and_check(line.substr(66,14))); // G14.6
            move = std::stoi(string_trim_and_check(line.substr(80,8))); //I8
            if (is_cheq) {
                ECH = std::stod(string_trim_and_check(line.substr(88,14))); // G14.6
                ECA = std::stod(string_trim_and_check(line.substr(102,14))); // G14.6
            }
        }
        else {
            atID = std::stoull(string_trim_and_check(line.substr(0,8))); // I8
            segName = string_trim_and_check(line.substr(9,4)); // 1X,A4
            resID = string_trim_and_check(line.substr(14,4)); // 1X,A4
            resName = string_trim_and_check(line.substr(19,4)); // 1X,A4
            atomName = string_trim_and_check(line.substr(24,4)); // 1X,A4
            atomType = string_trim_and_check(line.substr(29,4)); // 1X,A4
            charge = std::stod(string_trim_and_check(line.substr(34,14))); // 1X,G14.6
            mass = std::stod(string_trim_and_check(line.substr(48,14))); // G14.6
            move = std::stoi(string_trim_and_check(line.substr(62,8))); //I8
            if (is_cheq) {
                ECH = std::stod(string_trim_and_check(line.substr(70,14))); // G14.6
                ECA = std::stod(string_trim_and_check(line.substr(84,14))); // G14.6
            }
        }

    }
    catch (std::invalid_argument& invarg) {
        return false;
    }
    data.push_back(std::make_tuple(atID,segName,resID,resName,atomName,atomType,charge,mass,move,ECH,ECA));
    return true;
}

bool read_header(const string& line, std::map<string,bool>& properties) {
    string props_string = "PSF"; // tmp for printing 
    if (line.find("PSF") != string::npos) {
        // process additional headers if found
        for (auto& prop_pair: properties) {
            if (line.find(prop_pair.first) != string::npos) {
                prop_pair.second = true;
                props_string = props_string + ", " + prop_pair.first;
            }
        }
        cout << "psf-reader> Detected PSF header (" << props_string << ")\n";
        return true;
    }
    else {
        cerr << "Unable to detect PSF header: The first line must start with PSF\n"; // replace with error handling
        exit(1);
        return false;
    }
}

string string_trim_and_check(string s) {
    /* trim and replace all \t, \n, \r , \f and \v with space */
    s.erase(s.find_last_not_of(" \t\n\r\f\v") + 1);
    s.erase(0, s.find_first_not_of(" \t\n\r\f\v"));
    std::replace(s.begin(),s.end(),'\t',' ');
    std::replace(s.begin(),s.end(),'\n',' ');
    std::replace(s.begin(),s.end(),'\r',' ');
    std::replace(s.begin(),s.end(),'\f',' ');
    std::replace(s.begin(),s.end(),'\v',' ');
    if (s.find(" ") != std::string::npos) {
        throw std::invalid_argument(" String contains space in between, cannot be converted to number ");
    }
    if (s.empty()) {
        throw std::invalid_argument(" String is empty ");
    }
    return s;
}
