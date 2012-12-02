// Record.cpp
#include "Record.h"


// This object is built almost identically to a procedure object

// Constructor
Record::Record(const string name) : VariableType(name, VarTypes::RECORD) {

}

// Destructor
// Clears out the vector's contents
Record::~Record() {
    members.clear();
}

// Inserts a new member into this record
bool Record::InsertMember(Variable* member) {

    if (HasDuplicateMember(member)) {
        // This member already seems to exist. Print out a error message
        cout << "Member inserted already exists: " << member->ToString ();
        return false;
    } else {
        members.push_back(member);    // Add onto the end to maintain order
        return true;
    }
}

// Checks if there is a duplicate member in the vector members
bool Record::HasDuplicateMember(const Variable* checkedMember) {
    // Loop through vector "members"
    for (int x = 0; x < members.size(); x++) {
        if (*members[x] == *checkedMember)
            return true;    // A duplicate was found!
    }
    return false;            // No duplicate was found.
}

bool Record::HasMember(string name)
{
    for(int i = 0; i < members.size(); ++i)
    {
        if(members[i]->GetName() == name)
            return true;
    }
    return false;
}

Variable* Record::GetMember(string name)
{
    for(int i = 0; i < members.size(); ++i)
    {
        if(members[i]->GetName() == name)
            return members[i];
    }
    Variable* var = new Variable("nil");
    var->SetVarType(new NilType());
    return var;
}

// Return a string representation of this object
string Record::ToString() const {
    
    // I am not sure that this is the way we SHOULD do this...
    string s = "\n";
    for (int x = 0; x < members.size(); x++) {
        s += ( "   " + members[x]->GetName() + " " + members[x]->ToString() + "\n");
    }
    return s;
}

// Return a C-formatted string representation of this object
string Record::CString() const {
    return "";
}    
