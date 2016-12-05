/*******************************************************************************
  Filename:       operation_get.cpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


/*********************************************************************
*   Note: Element processing must strictly following the sequence of 
*   the class variable declaration.
*
*********************************************************************/


#include "operation.hpp"


/*********************************************************************
* @fn      Operation::getOpCode
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
opCode_t Operation::getOpCode() {
    return this->opCode;
}


/*********************************************************************
* @fn      Operation::getPid
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
proId_t Operation::getPid() {
    return this->pid;
}


/*********************************************************************
* @fn      Operation::getDelay
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
delay_t Operation::getDelay() {
    return this->delay;
}


/*********************************************************************
* @fn      Operation::getPC
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
pc_t Operation::getPC() {
    return this->pc;
}


/*********************************************************************
* @fn      Operation::getAddr
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
addr_t Operation::getAddr() {
    return this->addr;
}


/*********************************************************************
* @fn      Operation::getVal
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
val_t Operation::getVal() {
    val_t outputVal = val_t(this->val);
    switch(this->getDataSize()) {
    case OP_DATASIZE_0:
        outputVal[0] = 0;
    case OP_DATASIZE_8:
    case OP_DATASIZE_16:
    case OP_DATASIZE_32:
    case OP_DATASIZE_64:
        outputVal[0] &= NBITMASK(this->getDataSize() * 8);
        outputVal[1] = 0;
    case OP_DATASIZE_128:
        outputVal[2] = 0;
        outputVal[3] = 0;
    case OP_DATASIZE_256:
        outputVal[4] = 0;
        outputVal[5] = 0;
        outputVal[6] = 0;
        outputVal[7] = 0;
        break;
    case OP_DATASIZE_512:
        break;
    default:
        break;
    }
    return outputVal;
}


/*********************************************************************
* @fn      Operation::getOpNum
*
* @brief   ...
*
* @param   none
*
* @return  param_t op type
*/
param_t Operation::getOpNum() {
    return this->opNum;
}


/*********************************************************************
* @fn      Operation::getOpType
*
* @brief   ...
*
* @param   none
*
* @return  param_t op type
*/
param_t Operation::getOpType() {
    return this->opType;
}


/*********************************************************************
* @fn      Operation::getDataSize
*
* @brief   ...
*
* @param   none
*
* @return  param_t data size in byte
*/
param_t Operation::getDataSize() {
    return this->dataSize;
}



/*********************************************************************
* @fn      Operation::loadNeedData
*
* @brief   ...
*
* @param   none
*
* @return  bool
*/
bool Operation::loadNeedData() {
    return this->ldData;
}


/*********************************************************************
* @fn      Operation::getByOpNum
*
* @brief   Empty type
*
* @param   opCode_t opnum
*
* @return  opNum_t opcode
*/
opCode_t Operation::getByOpNum(opNum_t opNum) {
    return this->opcodeMap.at(opNum);
}


/*********************************************************************
* @fn      Operation::getLoadByOpcode
*
* @brief   Empty type
*
* @param   opCode_t opnum
*
* @return  opNum_t opcode
*/
opNum_t  Operation::getLoadByOpcode(opCode_t opCode) {
    return this->loadOpnumMap.at(opCode);
}


/*********************************************************************
* @fn      Operation::getStoreByOpcode
*
* @brief   Empty type
*
* @param   opCode_t opnum
*
* @return  opNum_t opcode
*/
opNum_t  Operation::getStoreByOpcode(opCode_t opCode) {
    return this->storeOpnumMap.at(opCode);
}


/*********************************************************************
* @fn      Operation::getOpTypeByOpNum
*
* @brief
*
* @param   none
*
* @return  param_t
*/
param_t Operation::getOpTypeByOpNum(opNum_t opNum) {

    switch(opNum){
    case OPNUM_L08U:
    case OPNUM_L08S:
    case OPNUM_L16U:
    case OPNUM_L16S:
    case OPNUM_L32U:
    case OPNUM_L32S:
    case OPNUM_L64U:
    case OPNUM_L128U:
    case OPNUM_L256U:
    case OPNUM_L512U:
    case OPNUM_XL08U:
    case OPNUM_XL08S:
    case OPNUM_XL16U:
    case OPNUM_XL16S:
    case OPNUM_XL32U:
    case OPNUM_XL32S:
    case OPNUM_XL64U:
    case OPNUM_XL128U:
    case OPNUM_XL256U:
    case OPNUM_XL512U:
        return OPTYPE_LOAD;
        break;
    case OPNUM_S08:
    case OPNUM_S16:
    case OPNUM_S32:
    case OPNUM_S64:
    case OPNUM_S128:
    case OPNUM_S256:
    case OPNUM_S512:
    case OPNUM_XS00:
    case OPNUM_XS08:
    case OPNUM_XS16:
    case OPNUM_XS32:
    case OPNUM_XS64:
    case OPNUM_XS128:
    case OPNUM_XS256:
    case OPNUM_XS512:
        return OPTYPE_STORE;
        break;
    case OPNUM_LIVECACHE:
        return OPTYPE_LC;
        break;
    default:
        exit(ERROR_OpTypeInvalid);
        break;
    }
}





