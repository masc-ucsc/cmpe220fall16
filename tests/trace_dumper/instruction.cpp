/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "instruction.h"






Instruction:: Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val)
{
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val 		= _val;
	this->pc		= DEFAULT_PC;
	this->pid 		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}

Instruction:: Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val, uint64_t _pc){
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}


Instruction:: Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val, uint64_t _pc, uint16_t _pid){
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= _pid;
	this->delay		= DEFAULT_DELAYTIME;
}


Instruction:: Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val, uint64_t _pc, uint16_t _pid, uint32_t _delay){
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= _pid;
	this->delay		= _delay;
}



bool Instruction::setOpType(opType_t opType_new)
{
	this->opType = opType_new;
	// TODO: set param's boundary
	return true;
}

bool Instruction::setAddr(addr_t addr_new)
{
	this->addr = addr_new;
	// TODO: set param's boundary
	return true;
}

bool Instruction::setVal(val_t val_new)
{
	this->val = val_new;
	// TODO: set param's boundary
	return true;
}

bool Instruction::setPc(pc_t pc_new)
{
	this->pc = pc_new;
	// TODO: set param's boundary
	return true;
}

bool Instruction::setPid(Pid_t pid_new)
{
	this->pid = pid_new;
	// TODO: set param's boundary
	return pid;
}

bool Instruction::setDelay(delay_t delay_new)
{
	this->delay = delay_new;
	// TODO: set param's boundary
	return true;
}

bool Instruction::setFromBinary(array<uint32_t, BINARY_SIZE> binary)
{
    // TODO: decode Binary
    // TODO: set param's boundary
    return true;
}




opType_t Instruction::getOpType()
{
	return this->opType;
}

addr_t Instruction::getAddr()
{
	return this->addr;
}

val_t Instruction::getVal()
{
	return this->val;
}

pc_t Instruction::getPc()
{
	return this->pc;
}

Pid_t Instruction::getPid()
{
	return this->pid;
}

delay_t Instruction::getDelay()
{
	return this->delay;
}


array<uint32_t, BINARY_SIZE> Instruction::getBinary()
{
    array<uint32_t,BINARY_SIZE> binary;

    binary[0] = OPTYPE_TO_BIN_MASK(this->opType) | PID_TO_BIN_MASK(this->pid) | DELAY_TO_BIN_MASK(this->delay);
    binary[1] = ADDR_TO_BIN_MASK1(this->addr);
    binary[2] = ADDR_TO_BIN_MASK2(this->addr);
    binary[3] = VAL_TO_BIN_MASK1(this->val);
    binary[4] = VAL_TO_BIN_MASK2(this->val);
    binary[5] = PC_TO_BIN_MASK1(this->pc);
    binary[6] = PC_TO_BIN_MASK2(this->pc);

    return binary;
}
