/*
 * instruction.cpp
 *
 *  Created on: Oct 21, 2016
 *      Author: Zhehao Ding
 */

#include "operation.h"


/*------------------------Print class elements----------------------*/
/*********************************************************************
* @fn      Instruction::
*
* @brief   Read binary input and
*
* @param   none
*
* @return  none
*/
void Instruction::print()
{
    //printf("\n");
    printf("#%04d  ", this->pid);

    // op type
    cout << opNames[this->opCode] << "\t";

    printf("PC: %016" PRIXLEAST64 "  ", this->pc);
    printf("@%016" PRIXLEAST64 "  ", this->addr);
    printf("[%016" PRIXLEAST64 "]  ", this->val);
    printf("delay: %04d  ", this->delay);
    printf("\n");
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printOpCode()
{
    cout << "Op Type: " << opNames[this->opCode] << "\n";
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printPid()
{
    printf("Processor ID: #%04d\n", this->pid);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printDelay()
{
    printf("delay: %04d\n", this->delay);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printPC()
{
    printf("PC: %" PRIXLEAST64 "\n", this->pc);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printAddr()
{
    printf("Address: %" PRIXLEAST64 "\n", this->addr);
}


/*********************************************************************
* @fn      Instruction::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Instruction::printVal()
{
    printf("Data: [%" PRIXLEAST64 "]\n", this->val);
}

