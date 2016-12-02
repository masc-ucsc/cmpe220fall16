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

#include "dumper.h"
#include "operation.h"
#include "sync.h"

using namespace std;

int main ()
{
	Instruction ins = Instruction();

	ins.setOpCode(0x8);
	ins.setPid(0x3ff);
	ins.setDelay(111);
	ins.setAddr(0x1234567890abcdef);
	ins.setVal(0xabcdef1234567890);
	ins.setPc(0);
	ins.print();
	printf("%0X\n",ins.getBinary().front());
	return EXIT_SUCCESS;
}


