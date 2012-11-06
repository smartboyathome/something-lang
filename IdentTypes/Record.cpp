// Record.cpp
#include "Record.h"

// This object is built almost identically to a procedure object

// Constructor
Record::Record(const string name) : MetaType(name, RECORD) {

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
		members.push_back(member);	// Add onto the end to maintain order
		return true;
	}
}

// Checks if there is a duplicate member in the vector members
bool Record::HasDuplicateMember(const Variable* checkedMember) {
	// Loop through vector "members"
	for (int x = 0; x < members.size(); x++) {
		if (*members[x] == *checkedMember)
			return true;	// A duplicate was found!
	}
	return false;			// No duplicate was found.
}

// Return a string representation of this object
string Record::ToString() const {
	
					// I am not sure that this is the way we SHOULD do this...
	string s = identifier;
	for (int x = 0; x < members.size(); x++) {
		s += ( "   " + members[x]->ToString() + "\n");
	}
	return s;
}

// Return a C-formatted string representation of this object
string Record::CString() const {
	return "";
}	