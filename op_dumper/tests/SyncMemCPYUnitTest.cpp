/*
 * main.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 *
 */

#include <iostream>
#include <cstdlib>
#include <cstdint>

#include "dumper.hpp"
#include "operation.hpp"
#include "sync.hpp"

using namespace std;

map<opNum_t , opCode_t> opcodeMap = {
    // Load
        {OPNUM_L08U,   OPCODE_L08U},
        {OPNUM_L08S,   OPCODE_L08S},
        {OPNUM_L16U,   OPCODE_L16U},
        {OPNUM_L16S,   OPCODE_L16S},
        {OPNUM_L32U,   OPCODE_L32U},
        {OPNUM_L32S,   OPCODE_L32S},
        {OPNUM_L64U,   OPCODE_L64U},
        {OPNUM_L128U,  OPCODE_L128U},
        {OPNUM_L256U,  OPCODE_L256U},
        {OPNUM_L512U,  OPCODE_L512U},
    // Load with line pindown/lock
        {OPNUM_XL08U,  OPCODE_XL08U},
        {OPNUM_XL08S,  OPCODE_XL08S},
        {OPNUM_XL16U,  OPCODE_XL16U},
        {OPNUM_XL16S,  OPCODE_XL16S},
        {OPNUM_XL32U,  OPCODE_XL32U},
        {OPNUM_XL32S,  OPCODE_XL32S},
        {OPNUM_XL64U,  OPCODE_XL64U},
        {OPNUM_XL128U, OPCODE_XL128U},
        {OPNUM_XL256U, OPCODE_XL256U},
        {OPNUM_XL512U, OPCODE_XL512U},
    // Store
        {OPNUM_S08,    OPCODE_S08},
        {OPNUM_S16,    OPCODE_S16},
        {OPNUM_S32,    OPCODE_S32},
        {OPNUM_S64,    OPCODE_S64},
        {OPNUM_S128,   OPCODE_S128},
        {OPNUM_S256,   OPCODE_S256},
        {OPNUM_S512,   OPCODE_S512},
    // Store with line unclock
        {OPNUM_XS00,   OPCODE_XS00},
        {OPNUM_XS08,   OPCODE_XS08},
        {OPNUM_XS16,   OPCODE_XS16},
        {OPNUM_XS32,   OPCODE_XS32},
        {OPNUM_XS64,   OPCODE_XS64},
        {OPNUM_XS128,  OPCODE_XS128},
        {OPNUM_XS256,  OPCODE_XS256},
        {OPNUM_XS512,  OPCODE_XS512}
    };

    val_t data = {
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd,
            0xabcdefabcdefabcd
    };

int main ()
{
    Operation op;
    Dumper dumper = Dumper();
    memsync syncer = memsync();

    dumper.openToWrite("syncer.dat");

    syncer.setMemcpy(0xabcdef1234567000, 0x1234566666666000, 10);

    while(syncer.hasNext()) {
        op = syncer.getNext();
        //cout << op.getOpType() << endl;
        //op.print();
        dumper.add(op);
    }

    dumper.close();

    cout << endl;
    cout << endl;
    cout << "****************************************************************" << endl;
    cout << "****************************************************************" << endl;
    cout << "****************************************************************" << endl;
    cout << endl;
    cout << endl;

    dumper.openToRead("syncer.dat");

    while(dumper.hasNext())
    {
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();
//        op = dumper.get();

        op = dumper.get();
        op.print();
        op.printParams();
    }

    dumper.close();

    return EXIT_SUCCESS;
}

