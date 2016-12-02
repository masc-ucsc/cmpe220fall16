/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "operation.h"


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
opCode_t Instruction::getOpCode()
{
	return this->opCode;
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
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
param_t Instruction::getOpCatagory() {
    return this->opCatagory;
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
param_t Instruction::getOpType() {
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
param_t Instruction::getDataSize() {
    return this->dataSize;
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
bool Instruction::loadNeedData() {
    return this->ldData;
}
