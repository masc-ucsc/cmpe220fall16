/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "instruction.h"



/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
binary_t Instruction::getBinary()
{
    binary_t binary;
    // clear space;
    memset(&binary, 0, sizeof(binary_t));

    // Operation type
    binary[OPTYPE_INDEX_OFFSET] |= OPTYPE_TOBIN(this->opType);
    // PID
    binary[PID_INDEX_OFFSET_1] |= PID_TOBIN_1(this->pid);
    binary[PID_INDEX_OFFSET_2] |= PID_TOBIN_2(this->pid);
    // DELAY
    binary[DELAY_INDEX_OFFSET_1] |= DELAY_TOBIN_1(this->delay);
    binary[DELAY_INDEX_OFFSET_2] |= DELAY_TOBIN_2(this->delay);

    for(int i = 0; i < ADDR_VAR_BYTE; i++)
    {
        binary[ADDR_INDEX_OFFSET + i]    = ADDR_TOBIN(this->addr, i);
    }

    for(int i = 0; i < PC_VAR_BYTE; i++)
    {
        binary[PC_INDEX_OFFSET + i]      = PC_TOBIN(this->pc, i);
    }

    if(this->opType < 8 )
    {
        // STORE ops
        for(int i = 0; i < VAL_VAR_BYTE; i++)
        {
            binary[VAL_INDEX_OFFSET + i]     = VAL_TOBIN(this->val, i);
        }
    }else
    {
        // LOAD ops
        for(int i = 0; i < VAL_VAR_BYTE; i++)
        {
            binary[VAL_INDEX_OFFSET + i]     = 0;
        }
    }
    return binary;
}


/*********************************************************************
* @fn      Instruction::setFromBinary
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
bool Instruction::setFromBinary(binary_t binary)
{
    this->opType    = OPTYPE_TOVAR(binary[OPTYPE_INDEX_OFFSET]);

    this->pid       = PID_TOVAR_1(binary[PID_INDEX_OFFSET_1]);
    this->pid       |= PID_TOVAR_2(binary[PID_INDEX_OFFSET_2]);

    this->delay     = DELAY_TOVAR_1(binary[DELAY_INDEX_OFFSET_1]);
    this->delay     |= DELAY_TOVAR_2(binary[DELAY_INDEX_OFFSET_2]);

    this->addr = 0;
    for(int i = 0; i < ADDR_VAR_BYTE; i++)
    {
        this->addr |= ADDR_TOVAR(binary[ADDR_INDEX_OFFSET + i], i);
    }

    this->pc = 0;
    for(int i = 0; i < PC_VAR_BYTE; i++)
    {
        this->pc |= PC_TOVAR(binary[PC_INDEX_OFFSET + i], i);
    }

    this->val = 0;
    for(int i = 0; i < VAL_VAR_BYTE; i++)
    {
        this->val |= VAL_TOVAR(binary[VAL_INDEX_OFFSET + i], i);
    }

    return true;
}


/*********************************************************************
* @fn      Instruction::isStoreOp
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
bool Instruction::isStoreOp()
{
    if(this->opType > 7)
    {
        return false;
    }else
    {
        return true;
    }

    return true;
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
void Instruction::print()
{
    //printf("\n");
    printf("#%04d  ", this->pid);

    // op type
    cout << opNames[this->opType] << "\t";

    printf("PC: %016" PRIXLEAST64 "  ", this->pc);
    printf("@%016" PRIXLEAST64 "  ", this->addr);
    printf("[%016" PRIXLEAST64 "]  ", this->val);
    printf("delay: %04d  ", this->delay);
    printf("\n");
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printOpType()
{
    cout << "Op Type: " << opNames[this->opType] << "\n";
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printPid()
{
    printf("Processor ID: #%04d\n", this->pid);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printDelay()
{
    printf("delay: %04d\n", this->delay);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printPC()
{
    printf("PC: %" PRIXLEAST64 "\n", this->pc);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printAddr()
{
    printf("Address: %" PRIXLEAST64 "\n", this->addr);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printVal()
{
    printf("Data: [%" PRIXLEAST64 "]\n", this->val);
}


/*********************************************************************
 * @fn      Instruction::setOpType
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
bool Instruction::setOpType(opType_t opType_new)
{
	this->opType = opType_new;
	// TODO: set param's boundary
	return true;
}

/*********************************************************************
 * @fn      Instruction::setAddr
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 bool Instruction::setAddr(addr_t addr_new)
{
	this->addr = addr_new;
	// TODO: set param's boundary
	return true;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 bool Instruction::setVal(val_t val_new)
{
	this->val = val_new;
	// TODO: set param's boundary
	return true;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 bool Instruction::setPc(pc_t pc_new)
{
	this->pc = pc_new;
	// TODO: set param's boundary
	return true;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 bool Instruction::setPid(proId_t pid_new)
{
	this->pid = pid_new;
	// TODO: set param's boundary
	return pid;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 bool Instruction::setDelay(delay_t delay_new)
{
	this->delay = delay_new;
	// TODO: set param's boundary
	return true;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 opType_t Instruction::getOpType()
{
	return this->opType;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 addr_t Instruction::getAddr()
{
	return this->addr;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 val_t Instruction::getVal()
{
	return this->val;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 pc_t Instruction::getPc()
{
	return this->pc;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 proId_t Instruction::getPid()
{
	return this->pid;
}


/*********************************************************************
 * @fn      Instruction::
 *
 * @brief   ...
 *
 * @param   none
 *
 * @return  none
 */
 delay_t Instruction::getDelay()
{
	return this->delay;
}



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
    // Do nothing
}


/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opType, address
 *
 * @return  none
 */
Instruction:: Instruction(opType_t _opType, addr_t _addr)
{
    // if operation is store, need value input
    if(_opType > 7)
    {
        cout << endl << "ERROR: operation store needs data value input!" << endl;
        exit(ERROR_InstructionInitial);
    }


	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val 		= DEFAULT_VALUE;
	this->pc		= DEFAULT_PC;
	this->pid 		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}


/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opType, address, value
 *
 * @return  none
 */
Instruction:: Instruction(opType_t _opType, addr_t _addr, val_t _val)
{
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val 		= _val;
	this->pc		= DEFAULT_PC;
	this->pid 		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}

/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opType, address, value, PC
 *
 * @return  none
 */
Instruction:: Instruction(opType_t _opType, addr_t _addr, val_t _val, pc_t _pc){
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= DEFAULT_PID;
	this->delay		= DEFAULT_DELAYTIME;
}


/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opType, address, value, PC, pid
 *
 * @return  none
 */
Instruction:: Instruction(opType_t _opType, addr_t _addr, val_t _val, pc_t _pc, proId_t _pid){
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= _pid;
	this->delay		= DEFAULT_DELAYTIME;
}


/*********************************************************************
 * @fn      Instruction::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opType, address, value, PC, pid, delay
 *
 * @return  none
 */
Instruction:: Instruction(opType_t _opType, addr_t _addr, val_t _val, pc_t _pc, proId_t _pid, delay_t _delay){
	this->opType 	= _opType;
	this->addr 		= _addr;
	this->val		= _val;
	this->pc		= _pc;
	this->pid		= _pid;
	this->delay		= _delay;
}

