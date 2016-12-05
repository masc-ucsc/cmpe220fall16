/*******************************************************************************
  Filename:       operation_opcodes.hpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#ifndef SOURCE_OPERATION_OPCODES_HPP_
#define SOURCE_OPERATION_OPCODES_HPP_


//#include "operation.hpp"

using namespace std;

/********************************
*
*   Constants
*
*   @Desp: OP CODEs
*/
// Load
#define OPCODE_L08U        (0x00)  // 5'b0_0000
#define OPCODE_L08S        (0x01)  // 5'b0_0001
#define OPCODE_L16U        (0x02)  // 5'b0_0010
#define OPCODE_L16S        (0x03)  // 5'b0_0011
#define OPCODE_L32U        (0x04)  // 5'b0_0100
#define OPCODE_L32S        (0x05)  // 5'b0_0101
#define OPCODE_L64U        (0x06)  // 5'b0_0110
#define OPCODE_L128U       (0x08)  // 5'b0_1000
#define OPCODE_L256U       (0x0A)  // 5'b0_1010
#define OPCODE_L512U       (0x0C)  // 5'b0_1100

// Load with line pindown/lock
#define OPCODE_XL08U       (0x10)  // 5'b1_0000
#define OPCODE_XL08S       (0x11)  // 5'b1_0001
#define OPCODE_XL16U       (0x12)  // 5'b1_0010
#define OPCODE_XL16S       (0x13)  // 5'b1_0011
#define OPCODE_XL32U       (0x14)  // 5'b1_0100
#define OPCODE_XL32S       (0x15)  // 5'b1_0101
#define OPCODE_XL64U       (0x16)  // 5'b1_0110
#define OPCODE_XL128U      (0x18)  // 5'b1_1000
#define OPCODE_XL256U      (0x1A)  // 5'b1_1010
#define OPCODE_XL512U      (0x1C)  // 5'b1_1100

// Store
#define OPCODE_S08         (0x00)  // 7'b000_0000
#define OPCODE_S16         (0x02)  // 7'b000_0010
#define OPCODE_S32         (0x04)  // 7'b000_0100
#define OPCODE_S64         (0x06)  // 7'b000_0110
#define OPCODE_S128        (0x08)  // 7'b000_1000
#define OPCODE_S256        (0x0A)  // 7'b000_1010
#define OPCODE_S512        (0x0C)  // 7'b000_1100

// Store with line unclock
#define OPCODE_XS00        (0xFF)  // 7'b111_1111
#define OPCODE_XS08        (0x80)  // 7'b100_0000
#define OPCODE_XS16        (0x82)  // 7'b100_0010
#define OPCODE_XS32        (0x84)  // 7'b100_0100
#define OPCODE_XS64        (0x86)  // 7'b100_0110
#define OPCODE_XS128       (0x88)  // 7'b100_1000
#define OPCODE_XS256       (0x8A)  // 7'b100_1010
#define OPCODE_XS512       (0x8C)  // 7'b100_1100

// LiveCache
#define OPCODE_LIVECACHE   (0x66)     //8'b0110_0110


/********************************
*
*   Constants
*
*   @Desp: OP NUMBERs in Trace File
*/
// Load
// Numbering Interval [1, 20]
#define OPNUM_L08U     (1)  // 5'b00000
#define OPNUM_L08S     (2)  // 5'b00001
#define OPNUM_L16U     (3)  // 5'b00010
#define OPNUM_L16S     (4)  // 5'b00011
#define OPNUM_L32U     (5)  // 5'b00100
#define OPNUM_L32S     (6)  // 5'b00101
#define OPNUM_L64U     (7)  // 5'b00110
#define OPNUM_L128U    (8)  // 5'b01000
#define OPNUM_L256U    (9)  // 5'b01010
#define OPNUM_L512U    (10)  // 5'b01100

// Load with line pindown/lock
// Numbering Interval [21, 40]
#define OPNUM_XL08U    (21)  // 5'b10000
#define OPNUM_XL08S    (22)  // 5'b10001
#define OPNUM_XL16U    (23)  // 5'b10010
#define OPNUM_XL16S    (24)  // 5'b10011
#define OPNUM_XL32U    (25)  // 5'b10100
#define OPNUM_XL32S    (26)  // 5'b10101
#define OPNUM_XL64U    (27)  // 5'b10110
#define OPNUM_XL128U   (28)  // 5'b11000
#define OPNUM_XL256U   (29)  // 5'b11010
#define OPNUM_XL512U   (30)  // 5'b11100

// Store
// Numbering Interval [41, 60]
#define OPNUM_S08      (41)  // 7'b0000000
#define OPNUM_S16      (42)  // 7'b0000010
#define OPNUM_S32      (43)  // 7'b0000100
#define OPNUM_S64      (44)  // 7'b0000110
#define OPNUM_S128     (45)  // 7'b0001000
#define OPNUM_S256     (46)  // 7'b0001010
#define OPNUM_S512     (47)  // 7'b0001100

// Store with line unclock
// Numbering Interval [61, 80]
#define OPNUM_XS00     (61)  // 7'b1111111
#define OPNUM_XS08     (62)  // 7'b1000000
#define OPNUM_XS16     (63)  // 7'b1000010
#define OPNUM_XS32     (64)  // 7'b1000100
#define OPNUM_XS64     (65)  // 7'b1000110
#define OPNUM_XS128    (66)  // 7'b1001000
#define OPNUM_XS256    (67)  // 7'b1001010
#define OPNUM_XS512    (68)  // 7'b1001100

// LiveCache
#define OPNUM_LIVECACHE     (0)


#endif /* SOURCE_OPERATION_OPCODES_HPP_ */
