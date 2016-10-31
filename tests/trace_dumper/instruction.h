/*
 * instruction.h
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#ifndef INSTRUCTION_H_
#define INSTRUCTION_H_

#include <iostream>
#include <cstdint>
#include <array>

using namespace std;


#define DEFAULT_OPTYPE		(0)		// Not allowed to be used
#define DEFAULT_ADDRESS		(0)		// Not allowed to be used
#define DEFAULT_VALUE		(0)		// Not allowed to be used

#define DEFAULT_PC			(0)
#define DEFAULT_PID			(0)
#define DEFAULT_DELAYTIME	(0)

#define BINARY_VAR_SIZE     (32)
#define BINARY_SIZE         (7)

#define OPTYPE_BITSIZE      (4)
#define ADDR_BITSIZE        (64)
#define VAL_BITSIZE         (64)
#define PC_BITSIZE          (64)
#define PID_BITSIZE         (10)
#define DELAY_BITSIZE       (10)

#define OPTYPE_VAR_SIZE     (8)
#define ADDR_VAR_SIZE       (64)
#define VAL_VAR_SIZE        (64)
#define PC_VAR_SIZE         (64)
#define PID_VAR_SIZE        (16)
#define DELAY_VAR_SIZE      (16)

#define OPTYPE_MASK         (0xff >> (OPTYPE_VAR_SIZE - OPTYPE_BITSIZE))
#define ADDR_MASK           (0xffffffffffffffff >> (ADDR_VAR_SIZE - ADDR_BITSIZE))
#define VAL_MASK            (0xffffffffffffffff >> (VAL_VAR_SIZE - VAL_BITSIZE))
#define PC_MASK             (0xffffffffffffffff >> (PC_VAR_SIZE - PC_BITSIZE))
#define PID_MASK            (0xffff >> (PID_VAR_SIZE - PID_BITSIZE))
#define DELAY_MASK          (0xffff >> (DELAY_VAR_SIZE - DELAY_BITSIZE))


#define OPTYPE_TO_BIN_MASK(var) (((uint32_t)var & OPTYPE_MASK) << (BINARY_VAR_SIZE - OPTYPE_BITSIZE))

#define ADDR_TO_BIN_MASK1(var)  ((var & ADDR_MASK)  & 0x00000000ffffffff)
#define ADDR_TO_BIN_MASK2(var)  (((var & ADDR_MASK)  & 0xffffffff00000000) >> (ADDR_BITSIZE - BINARY_VAR_SIZE))

#define VAL_TO_BIN_MASK1(var)   ((var & VAL_MASK)  & 0x00000000ffffffff)
#define VAL_TO_BIN_MASK2(var)   (((var & VAL_MASK)  & 0xffffffff00000000) >> (VAL_BITSIZE - BINARY_VAR_SIZE))

#define PC_TO_BIN_MASK1(var)    ((var & VAL_MASK)  & 0x00000000ffffffff)
#define PC_TO_BIN_MASK2(var)    (((var & VAL_MASK)  & 0xffffffff00000000) >> (PC_BITSIZE - BINARY_VAR_SIZE))

#define PID_TO_BIN_MASK(var)    (((uint32_t)var & PID_MASK) << 16)
#define DELAY_TO_BIN_MASK(var)  (((uint32_t)var & DELAY_MASK) << 0)



// Critical parameters type
typedef uint8_t 	opType_t;
typedef	uint64_t	addr_t;
typedef	uint64_t	val_t;
// Secondary parameters type
typedef	uint64_t	pc_t;
typedef	uint16_t	Pid_t;
typedef	uint32_t	delay_t;
// Binary
typedef uint32_t    binary_t;


class Instruction{
private:
	// Critical parameters
	opType_t	opType;
	addr_t		addr;
	val_t		val;
	// Secondary parameters, can be omitted when initialized
	pc_t		pc;
	Pid_t		pid;
	delay_t		delay;

public:
	/*
	 * Special Functions
	 *
	 */

	/*Constructor*/
		// Constructor w/ critical parameters
	Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val);
		// Constructor w/ critical parameters + PC
	Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val,
			uint64_t _pc);
		// Constructor w/ critical parameters + PC, PID
	Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val,
			uint64_t _pc, uint16_t _pid);
		// Constructor w/ all parameters
	Instruction(uint8_t _opType, uint64_t _addr, uint64_t _val,
			uint64_t _pc, uint16_t _pid, uint32_t _delay);
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

	/*
	 * Input Functions
	 *
	 */
	bool setOpType(opType_t	opType_new);
	bool setAddr(addr_t addr_new);
	bool setVal(val_t val_new);
	bool setPc(pc_t pc_new);
	bool setPid(Pid_t pid_new);
	bool setDelay(delay_t delay_new);
    bool setFromBinary(array<uint32_t, BINARY_SIZE> binary);
	/*
	 * Output Functions
	 *
	 */
	opType_t getOpType();
	addr_t getAddr();
	val_t getVal();
	pc_t getPc();
	Pid_t getPid();
	delay_t getDelay();
    array<uint32_t, BINARY_SIZE> getBinary();
};

#endif /* INSTRUCTION_H_ */
