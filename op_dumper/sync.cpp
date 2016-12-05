/*******************************************************************************
  Filename:       sync.cpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#include "sync.hpp"

#include "dumper.hpp"
#include "operation.hpp"




/*********************************************************************
* @fn      memsync::setMemcpy
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool memsync::setMemcpy(memsyncAddr_t src, memsyncAddr_t dest, size_t num)
{
    this->srcAddress = src;
    this->destAddress = dest;

    this->len = num*2;
    this->counter = 0;

    this->data = 0x66;

    this->syncType = SYNC_MEMCPY;
    this->opCode = OPCODE_L08U;
    return true;
}


/*********************************************************************
* @fn      memsync::setMemset
*
* @brief   Initial private variables based on this
*
* @param   none
*
* @return  none
*/
bool memsync::setMemset(memsyncAddr_t address, memsyncVal_t value, size_t num)
{
    this->destAddress = address;
    this->data = value;

    this->len = num;
    this->counter = 0;

    this->syncType = SYNC_MEMSET;
    this->opCode = OPCODE_S08;
    return true;
}


/*********************************************************************
* @fn      memsync::getNext
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
Operation memsync::getNext()
{
    Operation op = Operation();

    if(this->syncType == SYNC_MEMCPY) {
        if((this->counter % 2) == 0) {
            op.setLoadOpCode(OPCODE_L08S);
            op.setPid(0);
            op.setDelay(0);
            op.setPC(this->pc);
            op.setAddr(this->srcAddress + 8*this->counter);
            //op.setVal(this->data);
        }else{
            op.setStoreOpCode(OPCODE_S08);
            op.setPid(0);
            op.setDelay(0);
            op.setPC(this->pc);
            op.setAddr(this->destAddress + 8*this->counter);
            op.setVal(this->data);
        }
    }else{
        op.setStoreOpCode(OPCODE_S08);
        op.setPid(0);
        op.setDelay(0);
        op.setPC(this->pc);
        op.setAddr(this->destAddress + 8*this->counter);
        op.setVal(this->data);
    }
    this->counter++;
    this->pc++;

    return op;
}


/*********************************************************************
* @fn      memsync::hasNext
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool memsync::hasNext()
{
    if(counter < len) {
        return true;
    }else{
        return false;
    }
}


/*********************************************************************
* @fn      memsync::dataSize
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
memsyncDataSize_t memsync::dataSize(void* value)
{
    return sizeof(value);
}


/*********************************************************************
* @fn       memsync::opDataType
*
* @brief    ...
*
* @param    memsyncType_t syncType
*           memsyncDataSize_t dsize
*
* @return   none
*/
opCode_t memsync::opDataType(memsyncType_t syncType, memsyncDataSize_t dsize)
{
    if(syncType == SYNC_MEMSET){

    }else{
        // FIXME: for MEMCPY LD and STORE
        exit(ERROR_OpTypeInvalid);
    }

    return 0;	// FIXME!!!
}


/*********************************************************************
* @fn      memsync::memsync
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
memsync:: memsync()
{
    this->syncType = 0;
    this->pc = 0;
    this->srcAddress = 0;
    this->destAddress = 0;
    this->counter = 0;
    this->len = 0;
    this->step = 1;
    this->opCode = 0;
    this->data = 0;
}

