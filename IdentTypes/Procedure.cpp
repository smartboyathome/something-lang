// Procedure.cpp
#include "Procedure.h"


// Constructor
Procedure::Procedure(const string name) : MetaType(name, PROCEDURE)
{
    return_data = new Variable("nil");
    return_data->SetVarType(new NilType());
    return_data->ToggleConst();
    var_num_args = false;
}

// Destructor
// Clears out the vector's contents
Procedure::~Procedure() {
    parameters.clear();
}

// Inserting a new parameter
bool Procedure::InsertParameter(Variable* param) {
    if (HasDuplicateParameter(param)) {
        // This parameter already seems to exist. Print out a error message
        cout << "Parameter inserted already exists: " << param->ToString ();
        return false;
    } else {
        parameters.push_back(param);    // Add onto the end to maintain order
        return true;
    }
    
}

// Returns whether or not the parameters vector contains a variable with
// an identical name
bool Procedure::HasDuplicateParameter(const Variable* checkedParam) {
    // Loop through vector "parameters"
    for (int x = 0; x < parameters.size(); x++) {
        if (*parameters[x] == *checkedParam)
            return true;    // A duplicate was found!
    }
    return false;            // No duplicate was found.
}

Variable* Procedure::GetReturnType()
{
    return return_data;
}

void Procedure::SetReturnType(Variable* data)
{
    return_data = data;
}

// Return a string representation of this object
string Procedure::ToString() const {
    
                    // I am not sure that this is the way we SHOULD do this...
    /*string s = "\n";
    for (int x = 0; x < parameters.size(); x++) {
        s += ( "xxx" + parameters[x]->GetName() + " " + parameters[x]->ToString() + "\n");
    }*/
    return "";
}

// Return a C-formatted string representation of this object
string Procedure::CString() const {
    return "";
}
