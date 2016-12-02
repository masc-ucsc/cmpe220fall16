/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "operation.h"



/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
binary_t Instruction::getBinary()
{
    // TODO: more compact binary
    binary_t binary;
    binaryUnit_t bin;

    // 0. opcode[0:3] 7~4, pid[9:6] 3~0
    bin = 0;
//    printf("%0X\n",bin);
    bin |= ((this->getOpCode() & EBMASK_OPCODE) << (8 - OPCODE_BITS));
//    printf("%04X, %04d, %04X, %X\n", bin, 8 - (int)OPCODE_BITS, this->getOpCode(), EBMASK_OPCODE);
    bin |= ((this->getPid() & EBMASK_PID) >> (PID_BITS - 8 + OPCODE_BITS));
//    printf("%04X, %04d, %04X, %X\n", bin, (int)PID_BITS - 8 + (int)OPCODE_BITS, this->getPid(), EBMASK_PID);
    binary.push_back(bin);

    // 1. pid[5:0] 7~2, delay[9:8] 1~0
    bin =   0;
    bin |=  ((this->getPid() & EBMASK_PID) << (8 - (PID_BITS - 8 + OPCODE_BITS)));
//    printf("%x, %d\n", bin, (8 - (PID_BITS - 8 + OPCODE_BITS)));
    bin |=  ((this->getDelay() & EBMASK_DELAYTIME) >> (8 - (PID_BITS - 8 + OPCODE_BITS)));
//	printf("%x, %d\n", bin, (8 - (PID_BITS - 8 + OPCODE_BITS)));
    binary.push_back(bin);

    // 2. delay[7:0] 7~0
    bin = 0;
    bin |=	(this->getDelay() & EBMASK_DELAYTIME);
    binary.push_back(bin);

    // 3.   PC[63:56]  7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 56);
    binary.push_back(bin);
    // 4.   PC[55:48]  7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 48);
    binary.push_back(bin);
    // 5.   PC[47:40]  7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 40);
    binary.push_back(bin);
    // 6.   PC[39:32]  7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 32);
    binary.push_back(bin);
    // 7.   PC[31:24]  7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 24);
    binary.push_back(bin);
    // 8.   PC[23:16]  7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 16);
    binary.push_back(bin);
    // 9.   PC[15:8]   7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC) >> 8);
    binary.push_back(bin);
    // 10.  PC[7:0]    7~0
    bin = 0;
    bin |=	((this->getPC() & EBMASK_PC));
	binary.push_back(bin);
    
    
    // 11.   Addr[63:56]  7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 56);
    binary.push_back(bin);
    // 12.   Addr[55:48]  7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 48);
    binary.push_back(bin);
    // 13.   Addr[47:40]  7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 40);
    binary.push_back(bin);
    // 14.   Addr[39:32]  7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 32);
    binary.push_back(bin);
    // 15.   Addr[31:24]  7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 24);
    binary.push_back(bin);
    // 16.   Addr[23:16]  7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 16);
    binary.push_back(bin);
    // 17.   Addr[15:8]   7~0
    bin = 0;
    bin |=	((this->getAddr() & EBMASK_ADDRESS) >> 8);
    binary.push_back(bin);
    // 18.   Addr[7:3]    7~3, ldData   0
    bin = 0;
    bin |=	((this->getAddr() & 0xF8));
    if(this->loadNeedData() && this->getOpCatagory() == OPCATAGORY_LOAD) {
       bin |= 0x01;
    }
    binary.push_back(bin);
    

    if(	this->getOpCatagory() == OPCATAGORY_STORED || 
        (this->getOpCatagory() == OPCATAGORY_LOAD && this->loadNeedData())) {
        // 19.   Val[63:56]  7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 56);
        binary.push_back(bin);
        // 20.   Val[55:48]  7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 48);
        binary.push_back(bin);
        // 21.   Val[47:40]  7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 40);
        binary.push_back(bin);
        // 22.   Val[39:32]  7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 32);
        binary.push_back(bin);
        // 23.   Val[31:24]  7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 24);
        binary.push_back(bin);
        // 24.   Val[23:16]  7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 16);
        binary.push_back(bin);
        // 25.   Val[15:8]   7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE) >> 8);
        binary.push_back(bin);
        // 26.   Val[7:0]    7~0
        bin = 0;
        bin |=  ((this->getVal() & EBMASK_VALUE));
        binary.push_back(bin);
	}

    return binary;
}


/*********************************************************************
* @fn      Instruction::setFromBinary
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
size_t Instruction::setFromBinary(binary_t)
{
    // FIXME: upgrade
    binary_t binary;
    binaryUnit_t bin;
    uint32_t counter = 0;

    proId_t newPID = 0;
    delay_t newDelay = 0;
    addr_t  newAddr = 0;
    pc_t    newPC = 0;
    val_t   newVal = 0;
    

    // 0. opcode[0:3] 7~4, pid[9:6] 3~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    this->setOpCode((bin >> (8 - OPCODE_BITS)) & (EBMASK_OPCODE));
    newPID = (bin & 0x07) << (PID_BITS - (8 - OPCODE_BITS));
    counter++;

    // 1. pid[5:0] 7~2, delay[9:8] 1~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPID |= ((bin & 0xFC) >> 2);
    this->setPid(newPID);
    newDelay = ((bin & 0x03) << (8));
    counter++;

    // 2. delay[7:0] 7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newDelay |= bin;
    this->setDelay(newDelay);
    counter++;

    // 3.   PC[63:56]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 56);
    counter++;
    // 4.   PC[55:48]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 48);
    counter++;
    // 5.   PC[47:40]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 40);
    counter++;
    // 6.   PC[39:32]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 32);
    counter++;
    // 7.   PC[31:24]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 24);
    counter++;
    // 8.   PC[23:16]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 16);
    counter++;
    // 9.   PC[15:8]   7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin << 8);
    counter++;
    // 10.  PC[7:0]    7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newPC |= (bin);
    this->setPc(newPC);
    counter++;
    
    // 11.   Addr[63:56]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 56);
    counter++;
    // 12.   Addr[55:48]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 48);
    counter++;
    // 13.   Addr[47:40]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 40);
    counter++;
    // 14.   Addr[39:32]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 32);
    counter++;
    // 15.   Addr[31:24]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 24);
    counter++;
    // 16.   Addr[23:16]  7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 16);
    counter++;
    // 17.   Addr[15:8]   7~0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin << 8);
    counter++;
    // 18.   Addr[7:3]    7~3, ldData   0
    bin = binary.at(counter);
//  printf("@%d: %x\n", counter, bin);
    newAddr |= (bin & 0xF8);    // ignore last 3 digits
    this->setAddr(newAddr);
    if(this->getOpCatagory() == OPCATAGORY_LOAD && (bin & 0x01) == 0x01) {
        this->setLoadNeedData();
    }else{
        this->setLoadNoData();
    }
    counter++;
    
    if( this->getOpCatagory() == OPCATAGORY_STORED || 
        (this->getOpCatagory() == OPCATAGORY_LOAD && this->loadNeedData())) {
        // 19.   Val[63:56]  7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 56);
        counter++;
        // 20.   Val[55:48]  7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 48);
        counter++;
        // 21.   Val[47:40]  7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 40);
        counter++;
        // 22.   Val[39:32]  7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 32);
        counter++;
        // 23.   Val[31:24]  7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 24);
        counter++;
        // 24.   Val[23:16]  7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 16);
        counter++;
        // 25.   Val[15:8]   7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin << 8);
        counter++;
        // 26.   Val[7:0]    7~0
        bin = binary.at(counter);
    //  printf("@%d: %x\n", counter, bin);
        newVal |= (bin);
        counter++;
        
        this->setVal(newVal);
    }


    return counter;
}



