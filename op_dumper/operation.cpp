/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "operation.h"





/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Empty type
 *
 * @param   none
 *
 * @return  none
 */
Instruction:: Instruction()
{
    this->opCode       = DEFAULT_OPCODE;
    this->addr         = DEFAULT_ADDRESS;
    this->pc           = DEFAULT_PC;
	this->pid          = DEFAULT_PID;
	this->val          = DEFAULT_VALUE;
	this->delay        = DEFAULT_DELAYTIME;
	this->opCatagory   = DEFAULT_OPVATAGORY;
	this->opType       = DEFAULT_OPTYPE;
	this->dataSize     = DEFAULT_DATASIZE;
	this->ldData       = DEFAULT_LOADDATA;
}


/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address
 *
 * @return  none
 */
/*
Instruction:: Instruction(opCode_t _opCode, addr_t _addr)
{
    // if operation is store, need value input
    if(_opCode > 7)
    {
        cout << endl << "ERROR: operation store needs data value input!" << endl;
        exit(ERROR_InstructionInitial);
    }


	this->opCode 	= _opCode;
	this->addr 		= _addr;
	this->val 		= DEFAULT_VALUE;
	this->pc		= DEFAULT_PC;
	this->pid 		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}
 */

/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value
 *
 * @return  none
 */
/*
Instruction:: Instruction(opCode_t _opCode, addr_t _addr, val_t _val)
{
	this->opCode 	= _opCode;
	this->addr 		= _addr;
	this->val 		= _val;
	this->pc		= DEFAULT_PC;
	this->pid 		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}
 */
/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value, PC
 *
 * @return  none
 */
/*
Instruction:: Instruction(opCode_t _opCode, addr_t _addr, val_t _val, pc_t _pc){
	this->opCode 	= _opCode;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}
 */

/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value, PC, pid
 *
 * @return  none
 */
/*
Instruction:: Instruction(opCode_t _opCode, addr_t _addr, val_t _val, pc_t _pc, proId_t _pid){
	this->opCode 	= _opCode;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= _pid;
	this->delay		= DEFAULT_DELAYTIME;
}
 */

/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value, PC, pid, delay
 *
 * @return  none
 */
/*
Instruction:: Instruction(opCode_t _opCode, addr_t _addr, val_t _val, pc_t _pc, proId_t _pid, delay_t _delay){
	this->opCode 	= _opCode;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= _pid;
	this->delay		= _delay;
}

*/
