// Set.h
#pragma once
#include "MetaType.h"

class Set:public MetaType {
public:
    Set(const string name);
    ~Set();
    
    void SetRange(int low, int high);
    
    string ToString() const;
    string CString() const;

private:
    int low;
    int high;

};
