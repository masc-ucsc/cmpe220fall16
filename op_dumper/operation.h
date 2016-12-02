/*
 * instruction.h
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#ifndef OPERATION_H_
#define OPERATION_H_

#include "errorcode.h"

using namespace std;


/********************************
*
*   MACROs
*
*   @Desp:
*/
#define NBITMASK(n)     (0xFFFFFFFFFFFFFFFF >> (64 - n))


/********************************
*
*   Constants
*
*   @Desp: OP CODEs
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
*   Constants
*
*   @Desp: OP Name String
*/

const vector<string> opNames = {"L_B", "L_H", "L_W", "L_D",
                                "L_BU", "L_HU", "L_WU", "",
                                "S_A_B", "S_A_H", "S_A_W", "S_A_D",
                                "S_D_B", "S_D_H", "S_D_W", "S_D_D"};


/********************************
*
*   Constants
*
*   @Desp: OP Parameters
*/
// OP Catagory
#define OPCATAGORY_LOAD     1
#define OPCATAGORY_STORE    2

// OP TYPE
#define OPTYPE_LOAD         1
#define OPTYPE_STOREA       2
#define OPTYPE_STORED       3

// data size in byte
#define OP_DATASIZE_0       0   // No data
#define OP_DATASIZE_1       1   // 8 bits
#define OP_DATASIZE_2       2   // 16 bits
#define OP_DATASIZE_4       4   // 32 bits
#define OP_DATASIZE_8       8   // 64 bits


/********************************
*
*   Default Values
*
*/

#define DEFAULT_OPCODE		(0)		// Not allowed to be used
#define DEFAULT_ADDRESS		(0)		// Not allowed to be used
#define DEFAULT_VALUE		(0)     // Not allowed for Store

#define DEFAULT_PC			(0)
#define DEFAULT_PID			(0)
#define DEFAULT_DELAYTIME	(0)

#define DEFAULT_OPVATAGORY  (1)
#define DEFAULT_OPTYPE      (1)
#define DEFAULT_DATASIZE    (0)
#define DEFAULT_LOADDATA    (false)


/********************************
*
*   Constants
*
*   @Desp: components size
*/
#define BINARY_BITS         (OPCODE_BITS \
                             + ADDR_BITS \
                             + VAL_BITS \
                             + PC_BITS \
                             + PID_BITS \
                             + DELAY_BITS )
#define BINARY_BYTE         ((BINARY_BITS+7)>>3)

#define OPCODE_BITS         (4)
#define PID_BITS            (10)
#define DELAY_BITS          (10)
#define ADDR_BITS           (64)
#define PC_BITS             (64)
#define VAL_BITS            (64)

#define opCode_VAR_BITS     (8)
#define PID_VAR_BITS        (16)
#define DELAY_VAR_BITS      (16)
#define ADDR_VAR_BITS       (64)
#define PC_VAR_BITS         (64)
#define VAL_VAR_BITS        (64)

#define opCode_VAR_BYTE     (1)
#define PID_VAR_BYTE        (2)
#define DELAY_VAR_BYTE      (2)
#define ADDR_VAR_BYTE       (8)
#define PC_VAR_BYTE         (8)
#define VAL_VAR_BYTE        (8)


/********************************
*
*   Constants
*
*   @Desp: Effective Bits Mask（EBMask）
*/

#define EBMASK_OPCODE		(NBITMASK(4))     // b'0000_1111
#define EBMASK_ADDRESS		(NBITMASK(64))
#define EBMASK_VALUE		(NBITMASK(64))

#define EBMASK_PC			(NBITMASK(64))
#define EBMASK_PID			(NBITMASK(10))   // b'0000_0011_1111_1111
#define EBMASK_DELAYTIME	(NBITMASK(10))   // b'0000_0011_1111_1111


/********************************
*   Type Define
*
*/

// Critical parameters type
typedef uint8_t 	opCode_t;
typedef	uint64_t	addr_t;
typedef	uint64_t	val_t;
// Secondary parameters type
typedef	uint64_t	pc_t;
typedef	uint16_t	proId_t;
typedef	uint32_t	delay_t;
// parameters type
typedef uint32_t     param_t;

// Binary
typedef uint8_t                 binaryUnit_t;
typedef vector<binaryUnit_t>    binary_t;

/********************************
*
*   Classes
*
*   @Desp: Class Instruction for one single instruction
*/
class Instruction{
private:
	// Critical parameters
	opCode_t	opCode;
	addr_t		addr;
	// Secondary parameters, can be omitted when initialized
	pc_t		pc;
	proId_t		pid;
	val_t		val;
	delay_t		delay;

    // Assistant Information
    param_t     opCatagory;     // Load or Store
    param_t     opType;         // Load, Store Address or Store Data
    param_t     dataSize;       // number of bytes of data
    bool        ldData;

    /********************************
	*  Input Functions
	*
	*/
	// Parameters
	bool setOpCatagory(param_t opCatagory);
	bool setOpType(param_t opType);
	bool setDataSize(param_t dataSize);

	/********************************
	*  Output Functions
	*
	*/
	// Parameters
	param_t    getOpCatagory();
	param_t    getOpType();
	param_t    getDataSize();
	bool       loadNeedData();


public:

	/********************************
	 *  Input Functions
	 *
	 */
    bool setOpCode(opCode_t opCode);
	bool setAddr(addr_t addr_new);
	bool setVal(val_t val_new);
	bool setPc(pc_t pc_new);
	bool setPid(proId_t pid_new);
	bool setDelay(delay_t delay_new);
    // Parameters
    void setLoadNeedData();
    void setLoadNoData();

	/********************************
	 *  Output Functions
	 *
	 */
	opCode_t   getOpCode();
	addr_t     getAddr();
	val_t      getVal();
	pc_t       getPc();
	proId_t    getPid();
	delay_t    getDelay();

    /********************************
     *  Binary Functions
     *
     */
    size_t setFromBinary(binary_t binary);
    binary_t   getBinary();
    
    /********************************
     *  Printers
     *
     */
    void print();
    void printOpCode();
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
/*
		// Constructor w/ critical parameters
	Instruction(opCode_t _opCode, addr_t _addr);
		// Constructor w/ critical parameters + val
	Instruction(opCode_t _opCode, addr_t _addr,
             val_t _val);
		// Constructor w/ critical parameters + val, PC
	Instruction(opCode_t _opCode, addr_t _addr,
             val_t _val, pc_t _pc);
		// Constructor w/ critical parameters + val, PC, PID
	Instruction(opCode_t _opCode, addr_t _addr,
             val_t _val, pc_t _pc, proId_t _pid);
		// Constructor w/ all parameters
	Instruction(opCode_t _opCode, addr_t _addr,
             val_t _val, pc_t _pc, proId_t _pid, delay_t _delay);
*/
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

#endif /* OPERATION_H_ */
