/*******************************************************************************
  Filename:       Operation_binary.cpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#include "operation.hpp"



/*********************************************************************
* @fn      Operation::getBinary
*
* @brief   generate binary data based on the parameters of the
*          Operation instance.
*
* @param   none
*
* @return  binary_t (vector<uint8_t> data)
*/
binary_t Operation::getBinary() {
    binary_t binary;
    binaryUnit_t binUnit;

    // Live Cache has a special one
    if(this->getOpNum() == OPNUM_LIVECACHE) {
        return this->getLCBinary();
    }
    
    /***************************************************************
     * @Byte: [0]
     *
     * @Src: opNum[7:0]
     *
     * @Dest: binUnit[7:0]
     *
     * @desp: instead of opcode, using opnum to avoid duplicate
     *        codes in both load and store side
     */
    binUnit = 0;
    binUnit |= (this->getOpNum() & EBMASK_OPNUM);
    binary.push_back(binUnit);


    /***************************************************************
     * @Byte: [1]
     *
     * @Src:  PID[11:4]
     *
     * @Dest: binUnit[7:0]
     *
     * @desp: PID high 8 bits
     */
    binUnit = 0;
    binUnit |= (((this->getPid() & EBMASK_PID) >> 4) & EBMASK_BIN);
    binary.push_back(binUnit);
    

    /***************************************************************
     * @Byte: [2]
     *
     * @Src:  PID[3:0], delay[11:8]
     *
     * @Dest: binUnit[7:4], binUnit[3:0]
     *
     * @desp: PID low 4 bits, delay high 4 bits
     */
    binUnit = 0;
    binUnit |= (((this->getPid() & EBMASK_PID) << 4) & EBMASK_BIN);
    binUnit |= (((this->getDelay() & EBMASK_DELAY) >> 8) & EBMASK_BIN);
    binary.push_back(binUnit);


    /***************************************************************
     * @Byte: [3]
     *
     * @Src:  delay[7:0]
     *
     * @Dest: binUnit[7:0]
     *
     * @desp: delay low 8 bits
     */
    binUnit = 0;
    binUnit |= ((this->getDelay() & EBMASK_DELAY) & EBMASK_BIN);
    binary.push_back(binUnit);


    /***************************************************************
     * @Byte: [4]
     *
     * @Src:  PC[63:0]
     *
     * @Dest: binUnit[7:0] * 8
     *
     * @desp: 8 1-byte data of PC
     */
    for(int i = 0; i < PC_BITS/8; i++) {
        binUnit = (((this->getPC() & EBMASK_PC) >> (i*BIN_BITS)) & EBMASK_BIN);
        binary.push_back(binUnit);
    }

    /***************************************************************
     * @Byte: [5]
     *
     * @Src:  Address[63:0]
     *
     * @Dest: binUnit[7:0] * 8
     *
     * @desp: 8 1-byte data of Address
     */
    for(int i = 0; i < ADDR_BITS/8; i++) {
        binUnit = (((this->getAddr() & EBMASK_ADDRESS) >> (i*BIN_BITS)) & EBMASK_BIN);
        // Load need last bit of address to identify whether it needs the data
        if(i == 0 && this->getOpType() == OPTYPE_LOAD && this->loadNeedData()) {
            binUnit |= 0x01;
        }
        binary.push_back(binUnit);
    }


    /***************************************************************
     * @Byte: [6]
     *
     * @Src:  Value[63:0]
     *
     * @Dest: binUnit[7:0] * (0~64)
     *
     * @desp: (0~64) 1-byte data of PC
     */
    param_t dataSize = this->getDataSize();
    val_t data = this->getVal();
    for(param_t i = 0; i < dataSize; i++) {
        binUnit = (((data.at(i/8) & EBMASK_VALUE) >> (i*BIN_BITS)) & EBMASK_BIN);
        binary.push_back(binUnit);
    }



    return binary;
}


/*********************************************************************
* @fn      Operation::setFromBinary
*
* @brief   Read binary input and
*
* @param   none
*
* @return  size_t (number of bytes of the data)
*/
size_t Operation::setFromBinary(binary_t binary) {
    // FIXME: upgrade
    binaryUnit_t bin;

    opNum_t opNum = 0;
    proId_t PID = 0;
    delay_t delay = 0;
    addr_t  addr = 0;
    pc_t    PC = 0;
    

    /***************************************************************
     * @Byte: [0]
     *
     * @Src:  bin[7:0]
     *
     * @Dest: opNum[7:0]
     *
     * @desp: OP Number
     */
    opNum = binary.at(0);
    if(this->getOpTypeByOpNum(opNum) == OPTYPE_LOAD) {
        this->setLoadOpCode(this->getByOpNum(opNum));
    }else{
        this->setStoreOpCode(this->getByOpNum(opNum));
    }


    /***************************************************************
     * @Byte: [1]
     *
     * @Src:  bin[7:0]
     *
     * @Dest: PID[11:4]
     *
     * @desp: PID high 8 bits
     */
    bin = binary.at(1);
    PID |= (((proId_t)bin & EBMASK_BIN) << 4);


    /***************************************************************
     * @Byte: [2]
     *
     * @Src:  bin[7:4], bin[3:0]
     *
     * @Dest: PID[3:0], delay[11:8]
     *
     * @desp: PID low 4 bits & delay high 4 bits
     */
    bin = binary.at(2);
    PID |= ((((proId_t)bin & EBMASK_BIN) >> 4) & EBMASK_PID);
    this->setPid(PID & EBMASK_PID);


    delay |= (((delay_t)bin & NBITMASK(4)) << 8);


    /***************************************************************
     * @Byte: [3]
     *
     * @Src:  bin[7:0]
     *
     * @Dest: delay[7:0]
     *
     * @desp: delay low 8 bits
     */
    bin = binary.at(3);
    delay |= ((delay_t)bin & EBMASK_BIN);
    this->setDelay(delay & EBMASK_DELAY);


    /***************************************************************
     * @Byte: [4]
     *
     * @Src:  bin[7:0]
     *
     * @Dest: PC[7:0] * 8
     *
     * @desp: PC 8-bit * 8
     */
    for(int i = 0; i < 8; i++) {
        bin = binary.at(i+4);
        PC |= (((pc_t)bin & EBMASK_BIN) << (i*8));
    }
    this->setPC(PC & EBMASK_PC);



    /***************************************************************
     * @Byte: [5]
     *
     * @Src:  bin[7:0]
     *
     * @Dest: Addr[7:0]
     *
     * @desp: Addr 8 bits * 8
     */
    for(int i = 0; i < 8; i++) {
        bin = binary.at(i+4+8);
        addr |= (((addr_t)bin & EBMASK_BIN) << (i*8));
    }
    // Check the last bit of address
    if((addr& 0x0001) == 1) {
        this->setLoadNeedData();
    }else{
        this->setLoadNoData();
    }
    // Set address with mask ends as 0xFC
    this->setAddr(addr & EBMASK_ADDRESS);


    return this->getDataSize();
}


/*********************************************************************
* @fn      Operation::getLCBinary
*
* @brief   generate Live Cache binary data based on the parameters of
*          the Operation instance.
*
* @param   none
*
* @return  binary_t (vector<uint8_t> data)
*/
binary_t Operation::getLCBinary() {
    binary_t data;
    binaryUnit_t bin;

    bin = OPNUM_LIVECACHE;
    data.push_back(bin);

    for(int i = 0; i < 8; i++) {
        bin = (((this->getAddr() & EBMASK_ADDRESS) >> (i*BIN_BITS)) & EBMASK_BIN);
        data.push_back(bin);
    }


    return data;
}


