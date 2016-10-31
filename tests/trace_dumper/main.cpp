/*
 * main.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include <iostream>
#include <cstdlib>
#include <cstdint>

#include "instruction.h"
#include "dumper.h"

using namespace std;

int main ()
{
	cout << "Welcome to dumper! " << endl;
    Instruction ins = {0xf,
                        0x1234567890abcdef,
                        0x0123456789abcdef,
                        0xabcdef0123456789,
                        0x3db,
                        0x2bd};

    array<uint32_t, 7> result = ins.getBinary();

    dumper dump = {"testfile.data"};

    dump.add(result);
    dump.add(result);
    dump.add(result);
    dump.dump();
    dump.closeFile();

  return EXIT_SUCCESS;
}


