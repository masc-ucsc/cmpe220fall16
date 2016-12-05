/*******************************************************************************
  Filename:       operation_set.cpp
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
* @fn      Operation::setLoadOpCode
*
* @brief   ...
*
* @param   opCode_t opCode
*
* @return  bool
*/
bool Operation::setLoadOpCode(opCode_t opCode) {
    this->opCode = opCode;
    
    // OP NUMBER
    this->setOpNum(this->getLoadByOpcode(opCode));
    // OP TYPE
    this->setOpType(OPTYPE_LOAD);
    // DATA SIZE
    this->setDataSize(OP_DATASIZE_0);

    return true;
}


/*********************************************************************
* @fn      Operation::setStoreOpCode
*
* @brief   ...
*
* @param   opCode_t opCode
*
* @return  bool
*/
bool Operation::setStoreOpCode(opCode_t opCode) {
    this->opCode = opCode;
    
    // OP NUMBER
    this->setOpNum(this->getStoreByOpcode(opCode));
    // OP TYPE
    this->setOpType(OPTYPE_STORE);
    // DATA SIZE
    switch(this->getOpNum()){
    case OPNUM_XS00:
        this->setDataSize(OP_DATASIZE_0);
        break;
    case OPNUM_S08:
    case OPNUM_XS08:
        this->setDataSize(OP_DATASIZE_8);
        break;
    case OPNUM_S16:
    case OPNUM_XS16:
        this->setDataSize(OP_DATASIZE_16);
        break;
    case OPNUM_S32:
    case OPNUM_XS32:
        this->setDataSize(OP_DATASIZE_32);
        break;
    case OPNUM_S64:
    case OPNUM_XS64:
        this->setDataSize(OP_DATASIZE_64);
        break;
    case OPNUM_S128:
    case OPNUM_XS128:
        this->setDataSize(OP_DATASIZE_128);
        break;
    case OPNUM_S256:
    case OPNUM_XS256:
        this->setDataSize(OP_DATASIZE_256);
        break;
    case OPNUM_S512:
    case OPNUM_XS512:
        this->setDataSize(OP_DATASIZE_512);
        break;
    default:
        break;
    }

    return true;
}


/*********************************************************************
* @fn      Operation::setLiveCacheOp
*
* @brief   ...
*
* @param   opCode_t opCode
*
* @return  bool
*/
bool Operation::setLiveCacheOp() {
    this->opCode = OPNUM_LIVECACHE;
    
    // OP NUMBER
    this->setOpNum(OPNUM_LIVECACHE);
    this->setOpType(OPTYPE_LC);
    this->setDataSize(OP_DATASIZE_0);

    return true;
}


/*********************************************************************
* @fn      Operation::setPid
*
* @brief   ...
*
* @param   proId_t pid
*
* @return  bool
*/
bool Operation::setPid(proId_t pid) {
    this->pid = pid;

    return pid;
}


/*********************************************************************
* @fn      Operation::setDelay
*
* @brief   ...
*
* @param   delay_t delay
*
* @return  bool
*/
bool Operation::setDelay(delay_t delay) {
    this->delay = delay;

    return true;
}


/*********************************************************************
* @fn      Operation::setPC
*
* @brief   ...
*
* @param   pc_t pc
*
* @return  bool
*/
bool Operation::setPC(pc_t pc) {
    this->pc = pc;

    return true;
}


/*********************************************************************
* @fn      Operation::setAddr
*
* @brief   ...
*
* @param   addr_t addr
*
* @return  bool
*/
bool Operation::setAddr(addr_t addr) {
    this->addr = (addr & 0xFFFFFFFFFFFFFFF8);

    return true;
}


/*********************************************************************
* @fn      Operation::setVal
*
* @brief   ...
*
* @param   val_t val
*
* @return  bool
*/
bool Operation::setVal(val_t val) {
    for(uint32_t i = 0; i < val.size() && i < this->val.size(); i++) {
        this->val[i] = val[i];
    }
    return true;
}


/*********************************************************************
* @fn      Operation::setVal
*
* @brief   ...
*
* @param   val_t val
*
* @return  bool
*/
bool Operation::setVal(val8_t val) {
    this->val[0] = (valUnit_t)val;

    return true;
}


/*********************************************************************
* @fn      Operation::setVal
*
* @brief   ...
*
* @param   val_t val
*
* @return  bool
*/
bool Operation::setVal(val16_t val) {
    this->val[0] = (valUnit_t)val;

    return true;
}


/*********************************************************************
* @fn      Operation::setVal
*
* @brief   ...
*
* @param   val_t val
*
* @return  bool
*/
bool Operation::setVal(val32_t val) {
    this->val[0] = (valUnit_t)val;

    return true;
}


/*********************************************************************
* @fn      Operation::setVal
*
* @brief   ...
*
* @param   val_t val
*
* @return  bool
*/
bool Operation::setVal(val64_t val) {
    this->val[0] = (valUnit_t)val;

    return true;
}


/*********************************************************************
* @fn      Operation::setLoadNeedData
*
* @brief   Set Load ops need data in trace file
*
* @param   none
*
* @return  bool
*/
bool Operation::setLoadNeedData() {
    this->ldData = true;

    if(this->getOpType() == OPTYPE_LOAD) {
        switch(this->getOpNum()) {
        case OPNUM_L08U:
        case OPNUM_L08S:
        case OPNUM_XL08U:
        case OPNUM_XL08S:
            this->setDataSize(OP_DATASIZE_8);
            break;
        case OPNUM_L16U:
        case OPNUM_L16S:
        case OPNUM_XL16U:
        case OPNUM_XL16S:
            this->setDataSize(OP_DATASIZE_16);
            break;
        case OPNUM_L32U:
        case OPNUM_L32S:
        case OPNUM_XL32U:
        case OPNUM_XL32S:
            this->setDataSize(OP_DATASIZE_32);
            break;
        case OPNUM_L64U:
        case OPNUM_XL64U:
            this->setDataSize(OP_DATASIZE_64);
            break;
        case OPNUM_L128U:
        case OPNUM_XL128U:
            this->setDataSize(OP_DATASIZE_128);
            break;
        case OPNUM_L256U:
        case OPNUM_XL256U:
            this->setDataSize(OP_DATASIZE_256);
            break;
        case OPNUM_L512U:
        case OPNUM_XL512U:
            this->setDataSize(OP_DATASIZE_512);
            break;
        default:
            cout << "ERROR: Invalid Opration code!" << endl;
            exit(ERROR_OpTypeInvalid);
            break;
        }
        return true;
    }else{
        return false;
    }
}


/*********************************************************************
* @fn      Operation::setLoadNoData
*
* @brief   Set load ops doesn't need data in trace file
*
* @param   none
*
* @return  bool
*/
bool Operation::setLoadNoData() {

    if(this->getOpType() == OPTYPE_LOAD) {
        this->ldData = false;
        this->setDataSize(OP_DATASIZE_0);

        return true;
    }else{
        return false;
    }
}


/*********************************************************************
* @fn      private Operation::setOpType
*
* @brief   ...
*
* @param   param_t opType
*
* @return  bool
*/
bool Operation::setOpNum(param_t opNum) {
    this->opNum = opNum;

    return true;
}


/*********************************************************************
* @fn      private Operation::setOpType
*
* @brief   ...
*
* @param   param_t opType
*
* @return  bool
*/
bool Operation::setOpType(param_t opType) {
    this->opType = opType;

    return true;
}


/*********************************************************************
* @fn      private Operation::setDataSize
*
* @brief   ...
*
* @param   param_t dataSize
*
* @return  bool
*/
bool Operation::setDataSize(param_t dataSize) {
    this->dataSize = dataSize;

    return true;
}


