/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "operation.h"


/*------------------------Set class elements------------------------*/
/*********************************************************************
* @fn      Instruction::setLoadNeedData
*
* @brief   Set Load ops need data in trace file
*
* @param   none
*
* @return  none
*/
void Instruction::setLoadNeedData()
{
    this->ldData = true;

    switch(this->getOpCode()) {
        case 0:
        case 4:
            this->setDataSize(OP_DATASIZE_1);
            break;
        case 1:
        case 5:
            this->setDataSize(OP_DATASIZE_2);
            break;
        case 2:
        case 6:
            this->setDataSize(OP_DATASIZE_4);
            break;
        case 3:
            this->setDataSize(OP_DATASIZE_8);
            break;
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
        	break;
        case 7:
        default:
            break;
    }
}


/*********************************************************************
* @fn      Instruction::setLoadNoData
*
* @brief   Set load ops doesn't need data in trace file
*
* @param   none
*
* @return  none
*/
void Instruction::setLoadNoData()
{
    this->ldData = true;

    switch(this->getOpCode()) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
            this->setDataSize(OP_DATASIZE_0);
            break;
        case 8:
		case 9:
		case 10:
		case 11:
		case 12:
		case 13:
		case 14:
		case 15:
			break;
		case 7:
		default:
			break;
    }
}


/*********************************************************************
* @fn      Instruction::setopCode
*
* @brief   ...
*
* @note    switch(opCode) {
*          case 1:
*          case 2:
*           .
*           .
*           .
*           default:
*               break;
*           }
*
* @param   none
*
* @return  none
*/
bool Instruction::setOpCode(opCode_t opCode)
{
    if(opCode == 7) {
        printf("ERROR: op code: %d is not valid!", opCode);
        exit(ERROR_OpTypeInvalid);
    }

    // update this->opCode
	this->opCode = opCode;

    // Parameters:
    // op Catagory
    switch(opCode) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
        this->setOpCatagory(OPCATAGORY_LOAD);
        break;
    case 8:
    case 9:
    case 10:
    case 11:
    case 12:
    case 13:
    case 14:
    case 15:
    	this->setOpCatagory(OPCATAGORY_STORE);
        break;
    case 7:
    default:
        // TODO: invalid opcode error!
        break;
    }

    // op type
    switch(opCode) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    	this->setOpType(OPTYPE_LOAD);
        break;
    case 8:
    case 9:
    case 10:
    case 11:
    	this->setOpType(OPTYPE_STOREA);
        break;
    case 12:
    case 13:
    case 14:
    case 15:
    	this->setOpType(OPTYPE_STORED);
        break;
    case 7:
    default:
        // TODO: invalid opcode error!
        break;
    }

    // number of data size in byte
    if(this->loadNeedData()) {
        /*
        *   LOAD need extra space for data
        */
        switch(opCode) {
        case 8:
        case 9:
        case 10:
        case 11:
            this->setDataSize(OP_DATASIZE_0);
            break;
        case 0:
        case 4:
        case 12:
            this->setDataSize(OP_DATASIZE_1);
            break;
        case 1:
        case 5:
        case 13:
            this->setDataSize(OP_DATASIZE_2);
            break;
        case 2:
        case 14:
            this->setDataSize(OP_DATASIZE_4);
            break;
        case 3:
        case 6:
        case 15:
            this->setDataSize(OP_DATASIZE_8);
            break;
        case 7:
        default:
            // TODO: invalid opcode error!
            break;
        }
    }else{
        /*
        *   LOAD no data
        */
        switch(opCode) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 8:
        case 9:
        case 10:
        case 11:
            this->setDataSize(OP_DATASIZE_0);
            break;
        case 12:
            this->setDataSize(OP_DATASIZE_1);
            break;
        case 13:
            this->setDataSize(OP_DATASIZE_2);
            break;
        case 14:
            this->setDataSize(OP_DATASIZE_4);
            break;
        case 15:
            this->setDataSize(OP_DATASIZE_8);
            break;
        case 7:
        default:
            // TODO: invalid opcode error!
            break;
        }
    }


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
bool Instruction::setOpCatagory(param_t opCatagory) {
    this->opCatagory = opCatagory;
    // TODO: ...
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
bool Instruction::setOpType(param_t opType) {
    this->opType = opType;
    // TODO: ...
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
bool Instruction::setDataSize(param_t dataSize) {
    this->dataSize = dataSize;
    // TODO: ...
    return true;
}

