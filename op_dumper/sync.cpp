#include "sync.h"
#include "instruction.h"
#include "dumper.h"




/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool memsync::setMemcpy(memsyncAddr_t src, memsyncAddr_t dest, size_t num)
{
    this->syncType      = SYNC_MEMCPY;

    this->srcAddress    = src;
    this->destAddress   = dest;
    this->counter       = 0;
    this->len           = num*2;            // has 2*num ops: num ld & num st

    this->step          = 1;                // FIXME: currently only copy as uint8_t
    this->opType        = SYNC_DEFAULT;     // FIXME: has 2 ops, lbu and sab

    this->data          = SYNC_DEFAULT;     // NOTE: no data?

    return true;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   Initial private variables based on this
*
* @param   none
*
* @return  none
*/
bool memsync::setMemset(memsyncAddr_t address, memsyncVal_t value, size_t num)
{
    this->syncType      = SYNC_MEMSET;

    this->srcAddress    = SYNC_DEFAULT;     // NOTE: no need to do anything for MEMSET
    this->destAddress   = address;
    this->counter       = 0;
    this->len           = num;

    //this->step          = dataSize(value);
    //this->opType        = opDataType(SYNC_MEMSET, step);
    this->step          = 1;                // FIXME: currently only operate as uint8_t
    this->opType        = OP_SDB;

    this->data          = value;            // NOTE: only use uint8_t right now

    return true;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
Instruction memsync::getNext()
{
    Instruction ins;
    if(this->syncType == SYNC_MEMSET) {
        // MEMSET
        // Fill info into ins
        ins.setAddr(this->destAddress);
        ins.setDelay(SYNC_DEFAULT);     // NOTE: do nothing
        ins.setOpType(this->opType);
        ins.setPc(this->pc);            // FIXME: where to get PC?
        ins.setPid(SYNC_DEFAULT);       // NOTE: do nothing
        ins.setVal(this->data);

        // Increment
        this->destAddress += step;
        this->counter++;
    }else if(this->syncType == SYNC_MEMCPY) {
        // MEMCPY
        // DEFAULT OP is
        if(counter%2 == 0){
            // Even ops, LOAD
            ins.setAddr(this->srcAddress);
            ins.setDelay(SYNC_DEFAULT);     // NOTE: do nothing
            ins.setOpType(OP_LBU);          // FIXME: fixed as LBU
            ins.setPc(this->pc);            // FIXME: where to get PC?
            ins.setPid(SYNC_DEFAULT);       // NOTE: do nothing
            ins.setVal(SYNC_DEFAULT);       // NOTE: no data needed

            this->srcAddress += step;
            this->counter++;
        }else{
            // Odd ops, STORE ADDRESS
            ins.setAddr(this->destAddress);
            ins.setDelay(SYNC_DEFAULT);     // NOTE: do nothing
            ins.setOpType(OP_SAB);          // FIXME: fixed as SAB
            ins.setPc(this->pc);            // FIXME: where to get PC?
            ins.setPid(SYNC_DEFAULT);       // NOTE: do nothing
            ins.setVal(SYNC_DEFAULT);       // NOTE: no data needed

            this->destAddress += step;
            this->counter++;
        }
    }

    this->pc++;

    return ins;
}


/*********************************************************************
* @fn      dumper::
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
* @fn      dumper::
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
* @fn       dumper::opDataType
*
* @brief    ...
*
* @param    memsyncType_t syncType
*           memsyncDataSize_t dsize
*
* @return   none
*/
opType_t memsync::opDataType(memsyncType_t syncType, memsyncDataSize_t dsize)
{
    if(syncType == SYNC_MEMSET){
        switch(dsize){
        case 1:
            return OP_SDB;
            break;
        case 2:
            return OP_SDH;
            break;
        case 4:
            return OP_SDW;
            break;
        case 8:
            return OP_SDD;
            break;
        default:
            exit(ERROR_OpTypeInvalid);
            break;
        }
    }else{
        // FIXME: for MEMCPY LD and STORE
        exit(ERROR_OpTypeInvalid);
    }
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
memsync:: memsync()
{
    this->pc = 0;
}

