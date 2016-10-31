#ifndef DUMPER_H_INCLUDED
#define DUMPER_H_INCLUDED

#include <iostream>
#include <cstdint>
#include <array>
#include <fstream>
#include <queue>

#include "instruction.h"

using namespace std;



class dumper{
private:
    ofstream file;
    queue<array<uint32_t, BINARY_SIZE>> insq;


public:
    dumper(string filename);
    bool closeFile();
    bool add(array<uint32_t, BINARY_SIZE> binary);
    bool dump();
};


#endif // DUMPER_H_INCLUDED
