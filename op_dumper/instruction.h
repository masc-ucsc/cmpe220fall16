/*
 * instruction.h
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#ifndef INSTRUCTION_H_
#define INSTRUCTION_H_

#include "errorcode.h"

using namespace std;

/********
*
*   Operations
*
*/
// LOAD
#define OP_LB   (0x0)   //b'0000   // Load Byte
#define OP_LH   (0x1)   //b'0001   // Load Half
#define OP_LW   (0x2)   //b'0010   // Load Word
#define OP_LBU  (0x4)   //b'0100   // Load Unsigned Byte
#define OP_LHU  (0x5)   //b'0101   // Load Unsigned Half
#define OP_LWU  (0x6)   //b'0110   // Load Unsigned Word
#define OP_LD   (0x3)   //b'0011   // Load DWord

// STORE
#define OP_SAB  (0x8)   //b'1000   // Store Address Byte
#define OP_SAH  (0x9)   //b'1001   // Store Address Half
#define OP_SAW  (0xA)   //b'1010   // Store Address Word
#define OP_SAD  (0xB)   //b'1011   // Store Address DWord

#define OP_SDB  (0xC)   //b'1100   // Store DATA Byte
#define OP_SDH  (0xD)   //b'1101   // Store DATA Half
#define OP_SDW  (0xE)   //b'1110   // Store DATA Word
#define OP_SDD  (0xF)   //b'1111   // Store DATA DWord



/********************************
*
*   Default Values
*
*/

#define DEFAULT_OPTYPE		(0)		// Not allowed to be used
#define DEFAULT_ADDRESS		(0)		// Not allowed to be used
#define DEFAULT_VALUE		(0)     // Not allowed for Store

#define DEFAULT_PC			(0)
#define DEFAULT_PID			(0)
#define DEFAULT_DELAYTIME	(0)


/********************************
*
*   Size Define
*
*/

#define BINARY_BITS         (OPTYPE_BITS \
                             + ADDR_BITS \
                             + VAL_BITS \
                             + PC_BITS \
                             + PID_BITS \
                             + DELAY_BITS )
#define BINARY_BYTE         (BINARY_BITS>>3)

#define OPTYPE_BITS         (4)
#define PID_BITS            (10)
#define DELAY_BITS          (10)
#define ADDR_BITS           (64)
#define PC_BITS             (64)
#define VAL_BITS            (64)

#define OPTYPE_VAR_BITS     (8)
#define PID_VAR_BITS        (16)
#define DELAY_VAR_BITS      (16)
#define ADDR_VAR_BITS       (64)
#define PC_VAR_BITS         (64)
#define VAL_VAR_BITS        (64)

#define OPTYPE_VAR_BYTE     (1)
#define PID_VAR_BYTE        (2)
#define DELAY_VAR_BYTE      (2)
#define ADDR_VAR_BYTE       (8)
#define PC_VAR_BYTE         (8)
#define VAL_VAR_BYTE        (8)

const vector<string> opNames = {"L_B", "L_H", "L_W", "L_D",
                                "L_BU", "L_HU", "L_WU", "",
                                "S_A_B", "S_A_H", "S_A_W", "S_A_D",
                                "S_D_B", "S_D_H", "S_D_W", "S_D_D"};

/********************************
*
*   Variable MASK to BINARY
*
*   @Desp: binary[*_OFFSET_BINARY] |= MASK(DATA) << *_OFFSET_BITS
*/

#define OPTYPE_MASK_TOBIN   (0x0F)      //b'00001111

#define PID_MASK_TOBIN_1    (0x03C0)    //b'00000011_11000000
#define PID_MASK_TOBIN_2    (0x003F)    //b'00000000_00111111

#define DELAY_MASK_TOBIN_1  (0x0300)    //b'00000011_00000000
#define DELAY_MASK_TOBIN_2  (0x00FF)    //b'00000000_11111111

#define FULL_MASK_TOBIN     (0xFF)


/********************************
*
*   Binary Variable index
*
*   @Desp: binary[*_index_OFFSET]
*/
#define OPTYPE_INDEX_OFFSET          (0)
#define PID_INDEX_OFFSET_1           (0)
#define PID_INDEX_OFFSET_2           (1)
#define DELAY_INDEX_OFFSET_1         (1)
#define DELAY_INDEX_OFFSET_2         (2)
#define ADDR_INDEX_OFFSET            (3)
#define PC_INDEX_OFFSET              (11)
#define VAL_INDEX_OFFSET             (19)


/********************************
*
*   Binary Offsets to BINARY
*
*   @Desp: binary[*_OFFSET_BINARY] |= MASK(DATA) << *_OFFSET_BITS
*/

#define OPTYPE_OFFSET_TOBIN_BITS    (4)     // left shift

#define PID_OFFSET_TOBIN_BITS_1     (6)     // right shift

#define PID_OFFSET_TOBIN_BITS_2     (2)     // left shift

#define DELAY_OFFSET_TOBIN_BITS_1   (8)     // right shift

#define DELAY_OFFSET_TOBIN_BITS_2   (0)     // right shift


static const int PARAM_64_to_8_OFFSET[] = {56, 48, 40, 32, 24, 16, 8, 0};

/********************************
*
*   Variable to BINARY conversion
*
*   @Desp: binary[*_OFFSET_BINARY] |= MASK(DATA) << *_OFFSET_BITS
*/

#define OPTYPE_TOBIN(var)   ((var & OPTYPE_MASK_TOBIN) << OPTYPE_OFFSET_TOBIN_BITS)           //b'1111_XXXX

#define PID_TOBIN_1(var)    ((var & PID_MASK_TOBIN_1) >> PID_OFFSET_TOBIN_BITS_1)       //b'XXXX1111
#define PID_TOBIN_2(var)    ((var & PID_MASK_TOBIN_2) << PID_OFFSET_TOBIN_BITS_2)       //b'111111XX

#define DELAY_TOBIN_1(var)  ((var & DELAY_MASK_TOBIN_1) >> DELAY_OFFSET_TOBIN_BITS_1)   //b'XXXXXX11
#define DELAY_TOBIN_2(var)  ((var & DELAY_MASK_TOBIN_2) >> DELAY_OFFSET_TOBIN_BITS_2)   //b'11111111

#define FULL_TOBIN(var, i)  ((var >> PARAM_64_to_8_OFFSET[i]) & FULL_MASK_TOBIN)

#define ADDR_TOBIN(var, i)  (FULL_TOBIN(var, i))

#define PC_TOBIN(var, i)    (FULL_TOBIN(var, i))

#define VAL_TOBIN(var, i)   (FULL_TOBIN(var, i))


/********************************
*
*   Variable MASK to VARIABLE
*
*   @Desp: binary[*_OFFSET_BINARY] |= MASK(DATA) << *_OFFSET_BITS
*/

#define OPTYPE_MASK_TOVAR   (0xF0)      //b'1111XXXX

#define PID_MASK_TOVAR_1    (0x0F)      //b'XXXX1111
#define PID_MASK_TOVAR_2    (0xFC)      //b'111111XX

#define DELAY_MASK_TOVAR_1  (0x03)      //b'XXXXXX11
#define DELAY_MASK_TOVAR_2  (0xFF)      //b'11111111

#define FULL_MASK_TOVAR     (0xFF)      //b'11111111


/********************************
*
*   Binary Offsets to VARIABLE
*
*   @Desp: binary[*_OFFSET_BINARY] |= MASK(DATA) << *_OFFSET_BITS
*/

#define OPTYPE_OFFSET_TOVAR_BITS    (4)     // right shift

#define PID_OFFSET_TOVAR_BITS_1     (6)     // left shift

#define PID_OFFSET_TOVAR_BITS_2     (2)     // right shift

#define DELAY_OFFSET_TOVAR_BITS_1   (8)     // left shift

#define DELAY_OFFSET_TOVAR_BITS_2   (0)     // right shift


//static const int PARAM_64_to_8_OFFSET[] = {56, 48, 40, 32, 24, 16, 8, 0};

/********************************
*
*   Variable to VARIABLE conversion
*
*   @Desp: binary[*_OFFSET_BINARY] |= MASK(DATA) << *_OFFSET_BITS
*/

#define OPTYPE_TOVAR(var)   ((var & OPTYPE_MASK_TOVAR) >> OPTYPE_OFFSET_TOVAR_BITS)           //b'XXXX1111

#define PID_TOVAR_1(var)    ((var & PID_MASK_TOVAR_1) << PID_OFFSET_TOVAR_BITS_1)       //b'XXXX1111
#define PID_TOVAR_2(var)    ((var & PID_MASK_TOVAR_2) >> PID_OFFSET_TOVAR_BITS_2)       //b'111111XX

#define DELAY_TOVAR_1(var)  ((var & DELAY_MASK_TOVAR_1) << DELAY_OFFSET_TOVAR_BITS_1)   //b'XXXXXX11
#define DELAY_TOVAR_2(var)  ((var & DELAY_MASK_TOVAR_2) >> DELAY_OFFSET_TOVAR_BITS_2)   //b'11111111

#define FULL_TOVAR(var, i)  ((((uint64_t)var) & FULL_MASK_TOVAR) << PARAM_64_to_8_OFFSET[i])

#define ADDR_TOVAR(var, i)  (FULL_TOVAR(var, i))

#define PC_TOVAR(var, i)    (FULL_TOVAR(var, i))

#define VAL_TOVAR(var, i)   (FULL_TOVAR(var, i))


/********************************
*   Type Define
*
*/

// Critical parameters type
typedef uint8_t 	opType_t;
typedef	uint64_t	addr_t;
typedef	uint64_t	val_t;
// Secondary parameters type
typedef	uint64_t	pc_t;
typedef	uint16_t	proId_t;
typedef	uint32_t	delay_t;
// Binary
typedef uint8_t                         binaryUnit_t;
typedef array<binaryUnit_t, BINARY_BYTE>    binary_t;



/********************************
*
*   Classes
*
*   @Desp: Class Instruction for one single instruction
*/
class Instruction{
private:
	// Critical parameters
	volatile opType_t	opType;
	volatile addr_t		addr;
	// Secondary parameters, can be omitted when initialized
	volatile pc_t		pc;
	volatile proId_t		pid;
	volatile val_t		val;
	volatile delay_t		delay;

public:

	/********************************
	 *  Input Functions
	 *
	 */
	bool setOpType(opType_t	opType_new);
	bool setAddr(addr_t addr_new);
	bool setVal(val_t val_new);
	bool setPc(pc_t pc_new);
	bool setPid(proId_t pid_new);
	bool setDelay(delay_t delay_new);
    // Binary
    bool setFromBinary(binary_t binary);

	/********************************
	 *  Output Functions
	 *
	 */
	opType_t getOpType();
	addr_t getAddr();
	val_t getVal();
	pc_t getPc();
	proId_t getPid();
	delay_t getDelay();
    // Binary
    binary_t getBinary();

    /********************************
	 *  Tools
	 *
	 */
	 bool isStoreOp();

    /********************************
	 *  Printers
	 *
	 */
    void print();
    void printOpType();
    void printPid();
    void printDelay();
    void printPC();
    void printAddr();
    void printVal();

    /********************************
	 * Special Functions
	 *
	 */

	/*Constructor*/
        // EMPTY
	Instruction();
		// Constructor w/ critical parameters
	Instruction(opType_t _opType, addr_t _addr);
		// Constructor w/ critical parameters + val
	Instruction(opType_t _opType, addr_t _addr,
             val_t _val);
		// Constructor w/ critical parameters + val, PC
	Instruction(opType_t _opType, addr_t _addr,
             val_t _val, pc_t _pc);
		// Constructor w/ critical parameters + val, PC, PID
	Instruction(opType_t _opType, addr_t _addr,
             val_t _val, pc_t _pc, proId_t _pid);
		// Constructor w/ all parameters
	Instruction(opType_t _opType, addr_t _addr,
             val_t _val, pc_t _pc, proId_t _pid, delay_t _delay);
	/*Destructor*/
		//TODO: Maybe need it
	/*Copy constructor*/
		//TODO: Maybe need it
	/*Copy assignment*/
		//TODO: Maybe need it
	/*Move constructor*/
		//TODO: Maybe need it
	/*Move assignment*/
		//TODO: Maybe need it

};

#endif /* INSTRUCTION_H_ */
