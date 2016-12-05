/*******************************************************************************
  Filename:       operation_opcodes.cpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/

#include <map>

#include "operation.hpp"
#include "operation_opcodes.hpp"

/*********************************************************************
* @fn      Operation::loadOpcodeMap
*
* @brief   Static HashMap using op number from trace file to get op
*          code
*
* @param   op number
*
* @return  op code
*/
map<opNum_t , opCode_t> Operation::opcodeMap = {
// Load
    {OPNUM_L08U,   OPCODE_L08U},
    {OPNUM_L08S,   OPCODE_L08S},
    {OPNUM_L16U,   OPCODE_L16U},
    {OPNUM_L16S,   OPCODE_L16S},
    {OPNUM_L32U,   OPCODE_L32U},
    {OPNUM_L32S,   OPCODE_L32S},
    {OPNUM_L64U,   OPCODE_L64U},
    {OPNUM_L128U,  OPCODE_L128U},
    {OPNUM_L256U,  OPCODE_L256U},
    {OPNUM_L512U,  OPCODE_L512U},
// Load with line pindown/lock
    {OPNUM_XL08U,  OPCODE_XL08U},
    {OPNUM_XL08S,  OPCODE_XL08S},
    {OPNUM_XL16U,  OPCODE_XL16U},
    {OPNUM_XL16S,  OPCODE_XL16S},
    {OPNUM_XL32U,  OPCODE_XL32U},
    {OPNUM_XL32S,  OPCODE_XL32S},
    {OPNUM_XL64U,  OPCODE_XL64U},
    {OPNUM_XL128U, OPCODE_XL128U},
    {OPNUM_XL256U, OPCODE_XL256U},
    {OPNUM_XL512U, OPCODE_XL512U},
// Store
    {OPNUM_S08,    OPCODE_S08},
    {OPNUM_S16,    OPCODE_S16},
    {OPNUM_S32,    OPCODE_S32},
    {OPNUM_S64,    OPCODE_S64},
    {OPNUM_S128,   OPCODE_S128},
    {OPNUM_S256,   OPCODE_S256},
    {OPNUM_S512,   OPCODE_S512},
// Store with line unclock
    {OPNUM_XS00,   OPCODE_XS00},
    {OPNUM_XS08,   OPCODE_XS08},
    {OPNUM_XS16,   OPCODE_XS16},
    {OPNUM_XS32,   OPCODE_XS32},
    {OPNUM_XS64,   OPCODE_XS64},
    {OPNUM_XS128,  OPCODE_XS128},
    {OPNUM_XS256,  OPCODE_XS256},
    {OPNUM_XS512,  OPCODE_XS512}
};


/*********************************************************************
* @fn      Operation::loadOpnumMap
*
* @brief   Static HashMap using op code from Operation instance to get
*          op number
*
* @param   op code
*
* @return  op number
*/
map<opCode_t , opNum_t> Operation::loadOpnumMap = {
// Load
    {OPCODE_L08U,   OPNUM_L08U},
    {OPCODE_L08S,   OPNUM_L08S},
    {OPCODE_L16U,   OPNUM_L16U},
    {OPCODE_L16S,   OPNUM_L16S},
    {OPCODE_L32U,   OPNUM_L32U},
    {OPCODE_L32S,   OPNUM_L32S},
    {OPCODE_L64U,   OPNUM_L64U},
    {OPCODE_L128U,  OPNUM_L128U},
    {OPCODE_L256U,  OPNUM_L256U},
    {OPCODE_L512U,  OPNUM_L512U},
// Load with line pindown/lock
    {OPCODE_XL08U,  OPNUM_XL08U},
    {OPCODE_XL08S,  OPNUM_XL08S},
    {OPCODE_XL16U,  OPNUM_XL16U},
    {OPCODE_XL16S,  OPNUM_XL16S},
    {OPCODE_XL32U,  OPNUM_XL32U},
    {OPCODE_XL32S,  OPNUM_XL32S},
    {OPCODE_XL64U,  OPNUM_XL64U},
    {OPCODE_XL128U, OPNUM_XL128U},
    {OPCODE_XL256U, OPNUM_XL256U},
    {OPCODE_XL512U, OPNUM_XL512U},
};


/*********************************************************************
* @fn      Operation::storeOpnumMap
*
* @brief   Static HashMap using op code from Operation instance to get
*          op number
*
* @param   op code
*
* @return  op number
*/
map<opCode_t , opNum_t> Operation::storeOpnumMap = {
// Store
    {OPCODE_S08,    OPNUM_S08},
    {OPCODE_S16,    OPNUM_S16},
    {OPCODE_S32,    OPNUM_S32},
    {OPCODE_S64,    OPNUM_S64},
    {OPCODE_S128,   OPNUM_S128},
    {OPCODE_S256,   OPNUM_S256},
    {OPCODE_S512,   OPNUM_S512},
// Store with line unclock
    {OPCODE_XS00,   OPNUM_XS00},
    {OPCODE_XS08,   OPNUM_XS08},
    {OPCODE_XS16,   OPNUM_XS16},
    {OPCODE_XS32,   OPNUM_XS32},
    {OPCODE_XS64,   OPNUM_XS64},
    {OPCODE_XS128,  OPNUM_XS128},
    {OPCODE_XS256,  OPNUM_XS256},
    {OPCODE_XS512,  OPNUM_XS512},
};


/*********************************************************************
* @fn      Operation::opNameMap
*
* @brief
*
* @param   OP NUMBER
*
* @return  op NAME STRING
*/
map<opNum_t, string> Operation::opNameMap = {
    {OPNUM_L08U, "LD U8"},
    {OPNUM_L08S, "LD S8"},
    {OPNUM_L16U, "LD U16"},
    {OPNUM_L16S, "LD S16"},
    {OPNUM_L32U, "LD U32"},
    {OPNUM_L32S, "LD S32"},
    {OPNUM_L64U, "LD U64"},
    {OPNUM_L128U, "LD U128"},
    {OPNUM_L256U, "LD U256"},
    {OPNUM_L512U, "LD U512"},
    {OPNUM_XL08U, "LX U8"},
    {OPNUM_XL08S, "LX S8"},
    {OPNUM_XL16U, "LX U16"},
    {OPNUM_XL16S, "LX S16"},
    {OPNUM_XL32U, "LX U32"},
    {OPNUM_XL32S, "LX S32"},
    {OPNUM_XL64U, "LX U64"},
    {OPNUM_XL128U, "LX U128"},
    {OPNUM_XL256U, "LX U256"},
    {OPNUM_XL512U, "LX U512"},
    {OPNUM_S08, "ST S8"},
    {OPNUM_S16, "ST S16"},
    {OPNUM_S32, "ST S32"},
    {OPNUM_S64, "ST S64"},
    {OPNUM_S128, "ST S128"},
    {OPNUM_S256, "ST S256"},
    {OPNUM_S512, "ST S512"},
    {OPNUM_XS00, "SX 00"},
    {OPNUM_XS08, "SX S8"},
    {OPNUM_XS16, "SX S16"},
    {OPNUM_XS32, "SX S32"},
    {OPNUM_XS64, "SX S64"},
    {OPNUM_XS128, "SX S128"},
    {OPNUM_XS256, "SX S256"},
    {OPNUM_XS512, "SX S512"},
    {OPNUM_LIVECACHE, "LIVE CACHE"}
};


/***********************************************************************
switch(){
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
    break;
default:
    break;
}


switch(){
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
    break;
default:
    break;
}

***********************************************************************/
