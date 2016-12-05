/*******************************************************************************
  Filename:       sync.hpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#ifndef SYNC_H_INCLUDED
#define SYNC_H_INCLUDED

#include "errorcode.hpp"
#include "operation.hpp"

/********************************
*   Typedef
*
*/
typedef uint64_t    memsyncAddr_t;
typedef size_t      memsyncNum_t;
typedef uint8_t    memsyncVal_t;
typedef uint64_t    memsyncCnt_t;
typedef uint16_t    memsyncType_t;
typedef uint8_t     memsyncDataSize_t;

/********************************
*   Sync Type
*
*/
#define SYNC_MEMSET     (1)
#define SYNC_MEMCPY     (2)
#define SYNC_MEMCPY_LD  (3)
#define SYNC_MEMCPY_ST  (4)


/********************************
*   Constants
*
*/
#define SYNC_DEFAULT    (0)


/********************************
*   Class
*
*/
class memsync{
private:
    memsyncType_t       syncType;

    memsyncCnt_t        pc;

    memsyncAddr_t       srcAddress;
    memsyncAddr_t       destAddress;
    memsyncCnt_t        counter;
    memsyncCnt_t        len;

    memsyncDataSize_t   step;
    opCode_t            opCode;

    memsyncVal_t        data;

    // Functions
    memsyncDataSize_t   dataSize(void* value);
    opCode_t            opDataType(memsyncType_t syncType, memsyncDataSize_t dsize);

public:
    // API for getting instruction
    Operation getNext();
    bool hasNext();

    // Build a set of instructions
    bool setMemset(memsyncAddr_t address, memsyncVal_t value, size_t num);         // store data
    bool setMemcpy(memsyncAddr_t src, memsyncAddr_t dest, size_t num);      // load & store address

    memsync();
};


#endif // SYNC_H_INCLUDED
