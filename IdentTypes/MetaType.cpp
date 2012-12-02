// MetaType.cpp
// Abstract superclass that other identMetaTypes 
#include "MetaType.h"

string MetaTypeTypeToString(MetaTypeType type)
{
    switch(type)
    {
        case CONSTANT:
            return "constant";
        case PROCEDURE:
            return "procedure";
        case RANGE:
            return "range";
        case VARIABLE:
            return "variable";
        case VARIABLE_TYPE:
            return "variable type";
        case POINTER:
            return "pointer";
        case RECORD:
            return "record";
    }
}

// Constructor with a name
MetaType::MetaType(const string name, MetaTypeType metatype) {
    identifier = name;
    this->metatype = metatype;
}

// Destructor
MetaType::~MetaType() { } // Not sure if it'll need anything.

// Compare
// Takes an MetaType to be compared again and uses string == and > operators
// to return 1 for rhs > this, 0 for rhs == this, and -1 for else (rhs < this)
int MetaType::Compare(const MetaType& rhs) const {
    if (identifier < rhs.identifier)
        return 1;
    else if (identifier == rhs.identifier)
        return 0;
    else
        return -1;
}
// operator==
bool MetaType::operator==(const MetaType &rhs) {
    return this->Compare(rhs) == 0;
}

// operator !=
bool MetaType::operator!=(const MetaType &rhs) {
    return !(*this == rhs);
}

// gets string name
string MetaType::GetName() {
    return identifier;
}

MetaTypeType MetaType::GetType()
{
    return metatype;
}

void MetaType::SetName(string name)
{
    identifier = name;
}
