/*******************************************************************************
  Filename:       operation.cpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is the C file for blcok buffer. Block buffer
*******************************************************************************/

#include "operation.hpp"


/*********************************************************************
* @fn      Operation::constructor
*
* @brief   Empty type
*
* @param   none
*
* @return  none
*/
Operation:: Operation() {
    this->opCode       = DEFAULT_OPCODE;
    this->pid          = DEFAULT_PID;
    this->delay        = DEFAULT_DELAY;
    
    this->addr         = DEFAULT_ADDRESS;
    this->pc           = DEFAULT_PC;
    this->val          = val_t(8, 0);
    
    this->opNum        = DEFAULT_OPNUM;
    this->opType       = DEFAULT_OPTYPE;
    this->dataSize     = DEFAULT_DATASIZE;
    
    this->ldData       = DEFAULT_LOADDATA;
}


/*********************************************************************
* @fn      Operation::constructor
*
* @brief   Can only be used for load ops
*
* @param   opCode, address
*
* @return  none
*/
/*
Operation:: Operation(opCode_t _opCode, addr_t _addr) {
    // if operation is store, need value input
    if(_opCode > 7)
    {
        cout << endl << "ERROR: operation store needs data value input!" << endl;
        exit(ERROR_OperationInitial);
    }


    this->opCode     = _opCode;
    this->addr         = _addr;
    this->val         = DEFAULT_VALUE;
    this->pc        = DEFAULT_PC;
    this->pid         = DEFAULT_PID;
    this->delay        = DEFAULT_DELAYTIME;
}
 */

/*********************************************************************
 * @fn      Operation::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value
 *
 * @return  none
 */
/*
Operation:: Operation(opCode_t _opCode, addr_t _addr, val_t _val) {
    this->opCode     = _opCode;
    this->addr         = _addr;
    this->val         = _val;
    this->pc        = DEFAULT_PC;
    this->pid         = DEFAULT_PID;
    this->delay        = DEFAULT_DELAYTIME;
}
 */
/*********************************************************************
 * @fn      Operation::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value, PC
 *
 * @return  none
 */
/*
Operation:: Operation(opCode_t _opCode, addr_t _addr, val_t _val, pc_t _pc) {
    this->opCode     = _opCode;
    this->addr         = _addr;
    this->val        = _val;
    this->pc        = _pc;
    this->pid        = DEFAULT_PID;
    this->delay        = DEFAULT_DELAYTIME;
}
 */

/*********************************************************************
 * @fn      Operation::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value, PC, pid
 *
 * @return  none
 */
/*
Operation:: Operation(opCode_t _opCode, addr_t _addr, val_t _val, pc_t _pc, proId_t _pid) {
    this->opCode     = _opCode;
    this->addr         = _addr;
    this->val        = _val;
    this->pc        = _pc;
    this->pid        = _pid;
    this->delay        = DEFAULT_DELAYTIME;
}
 */

/*********************************************************************
 * @fn      Operation::constructor
 *
 * @brief   Can only be used for load ops
 *
 * @param   opCode, address, value, PC, pid, delay
 *
 * @return  none
 */
/*
Operation:: Operation(opCode_t _opCode, addr_t _addr, val_t _val, pc_t _pc, proId_t _pid, delay_t _delay) {
    this->opCode     = _opCode;
    this->addr         = _addr;
    this->val        = _val;
    this->pc        = _pc;
    this->pid        = _pid;
    this->delay        = _delay;
}

*/
