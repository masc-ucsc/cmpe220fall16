/*******************************************************************************
  Filename:       operation_print.cpp
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
* @fn      Operation::print
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
void Operation::print() {
    //printf("\n");
    printf("Core%04d  ", this->getPid());

    // op type
    cout << opNameMap.at(this->getOpNum()) << " ";

    printf("#%016" PRIXLEAST64 "  ", this->getPC());
    printf("@%016" PRIXLEAST64 "  ", this->getAddr());
    printf("delay: %04d  ", this->getDelay());
    val_t data = this->getVal();
    for(uint32_t i = 0; i < data.size(); i++) {
        printf("\n(%d) [0x%016" PRIXLEAST64 "]", i, data[i]);
    }
    printf("\n");
}


/*********************************************************************
* @fn      Operation::printParams
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
void Operation::printParams() {
    //printf("\n");
    printf("Op Number: %04d  ", this->getOpNum());
    printf("Op Type: %d ", this->getOpType());
    printf("Data Size: %d ", this->getDataSize());
    printf("\n");
}


/*********************************************************************
* @fn      Operation::printOpCode
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printOpCode() {
    // FIXME: opNames changed
    cout << "Op Type: " << opNameMap.at(this->getOpNum()) << "\n";
}


/*********************************************************************
* @fn      Operation::printPid
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printPid() {
    printf("Processor ID: #%04d\n", this->getPid());
}


/*********************************************************************
* @fn      Operation::printDelay
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printDelay() {
    printf("delay: %04d\n", this->getDelay());
}


/*********************************************************************
* @fn      Operation::printPC
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printPC() {
    printf("PC: %" PRIXLEAST64 "\n", this->getPC());
}


/*********************************************************************
* @fn      Operation::printAddr
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printAddr() {
    printf("Address: %" PRIXLEAST64 "\n", this->getAddr());
}


/*********************************************************************
* @fn      Operation::printVal
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printVal() {
    val_t data = this->getVal();
    for(uint32_t i = 0; i < data.size(); i++) {
        printf("\n(%d) [0x%016" PRIXLEAST64 "]", i, data[i]);
    }
}


/*********************************************************************
* @fn      Operation::printBIN
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Operation::printBIN() {
    binary_t binary = this->getBinary();
    printf("BINARY:\n");
    int index = 0;
    for(uint32_t i = 0; i < binary.size(); i++) {
        if(index%8 == 0) {
            printf("(%02d) [0x", i/8);
        }
        printf("%02X", binary[i]);
        if((index+1)%8 == 0) {
            printf("]\n");
        }
        index++;
    }
    if((index+1)%8 != 0) {
        printf("]\n");
    }
    cout << endl;
}


