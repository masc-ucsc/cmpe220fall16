/*******************************************************************************
  Filename:       operation.hpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#ifndef OPERATION_H_
#define OPERATION_H_

#include "errorcode.hpp"
#include "operation_opcodes.hpp"

using namespace std;


/********************************
*
*   MACROs
*
*   @Desp:
*/
#define NBITMASK(n)     (0xFFFFFFFFFFFFFFFF >> (64 - (n)))


/********************************
*   Type Define
*
*/
// Major Variable Type
typedef uint8_t  opCode_t;
typedef uint16_t proId_t;
typedef uint32_t delay_t;
typedef uint64_t pc_t;
typedef uint64_t addr_t;
// Value Types
typedef uint8_t  val8_t;
typedef uint16_t val16_t;
typedef uint32_t val32_t;
typedef uint64_t val64_t;
typedef uint64_t valUnit_t;
typedef vector<valUnit_t>   val_t;
// Extra Parameter Type
typedef uint32_t param_t;
typedef uint8_t  opNum_t;
// Binary Data Variable Type
typedef uint8_t                 binaryUnit_t;
typedef vector<binaryUnit_t>    binary_t;


/********************************
*
*   Constants
*
*   @Desp: OP Parameters
*/
// OP TYPE
#define OPTYPE_LOAD         (1)
//#define OPTYPE_LOADX        (2)
#define OPTYPE_STORE        (3)
//#define OPTYPE_STOREX       (4)
#define OPTYPE_LC           (5)

// data size in byte
#define OP_DATASIZE_0       (0)     // No data
#define OP_DATASIZE_8       (1)     // 1 byte
#define OP_DATASIZE_16      (2)     // 2 bytes
#define OP_DATASIZE_32      (4)     // 4 bytes
#define OP_DATASIZE_64      (8)     // 8 bytes
#define OP_DATASIZE_128     (16)    // 16 bytes
#define OP_DATASIZE_256     (32)    // 32 bytes
#define OP_DATASIZE_512     (64)    // 64 bytes



/********************************
*
*   Default Values
*
*/
#define DEFAULT_OPCODE      (0)
#define DEFAULT_PID         (0)
#define DEFAULT_DELAY       (0)

#define DEFAULT_PC          (0)
#define DEFAULT_ADDRESS     (0)
#define DEFAULT_VALUE       (0)

#define DEFAULT_OPNUM       (0)
#define DEFAULT_OPTYPE      (1)
#define DEFAULT_DATASIZE    (0)

#define DEFAULT_LOADDATA    (false)


/********************************
*
*   Constants
*
*   @Desp: components size
*/
#define OPCODE_BITS         (8)
#define OPNUM_BITS          (8)
#define PID_BITS            (12)
#define DELAY_BITS          (12)
#define PC_BITS             (64)
#define ADDR_BITS           (64)
#define VAL_BITS            (64)

#define BIN_BITS            (8)

/********************************
*
*   Constants
*
*   @Desp: Effective Bits Mask（EBMask）
*/
#define EBMASK_OPCODE       (NBITMASK(OPCODE_BITS))    // b'1111_1111
#define EBMASK_OPNUM        (NBITMASK(OPNUM_BITS))
#define EBMASK_PID          (NBITMASK(PID_BITS))       // b'0000_0011_1111_1111
#define EBMASK_DELAY        (NBITMASK(DELAY_BITS))     // b'0000_0011_1111_1111

#define EBMASK_PC           (NBITMASK(PC_BITS))
#define EBMASK_ADDRESS      (NBITMASK(ADDR_BITS - 3) << 3)
#define EBMASK_VALUE        (NBITMASK(VAL_BITS))

#define EBMASK_BIN          (NBITMASK(BIN_BITS))

/********************************
*
*   Classes
*
*   @Desp: Class Operation for one single operation
*/
class Operation{
private:
    /********************************
    *  Variables
    */
    // Major Operation variables
    opCode_t    opCode;
    proId_t     pid;
    delay_t     delay;
    pc_t        pc;
    addr_t      addr;
    // Data
    val_t       val;
    
    // Extra Parameter
    param_t     opNum;
    param_t     opType;         // L, LX, S, SX, LC
    param_t     dataSize;       // number of bytes of data
    
    // Special flag
    bool        ldData;
    
    // Op Codes HashMap
    static map<opNum_t, opCode_t> opcodeMap;
    // Op Number HashMap
    static map<opCode_t, opNum_t> loadOpnumMap;
    static map<opCode_t, opNum_t> storeOpnumMap;
    // Op Name
    static map<opNum_t, string> opNameMap;

    /********************************
    *  Input Functions
    */
    // Parameters
    bool setOpNum(param_t opNum);
    bool setOpType(param_t opType);
    bool setDataSize(param_t dataSize);

    
    /********************************
    *  Output Functions
    */
    // Parameters
//    opNum_t getOpnum();
    param_t getOpNum();
    bool    loadNeedData();


    /********************************
    *  Parameter Help Functions
    */
    opCode_t getByOpNum(opNum_t opNum);
    param_t getDataSize();
    opNum_t  getLoadByOpcode(opCode_t opCode);
    opNum_t  getStoreByOpcode(opCode_t opCode);

    /********************************
    *  Binary Functions
    */
    binary_t   getLCBinary();

public:

    /********************************
     *  Input Functions
     */
    bool setLoadOpCode(opCode_t opCode);
    bool setStoreOpCode(opCode_t opCode);
    bool setLiveCacheOp();
    bool setPid(proId_t pid);
    bool setDelay(delay_t delay);
    bool setPC(pc_t pc);
    bool setAddr(addr_t addr);
    // for values
    bool setVal(val8_t val);
    bool setVal(val16_t val);
    bool setVal(val32_t val);
    bool setVal(val64_t val);
    bool setVal(val_t val);
    // Parameters
    bool setLoadNeedData();
    bool setLoadNoData();


    /********************************
     *  Output Functions
     */
    opCode_t   getOpCode();
    addr_t     getAddr();
    val_t      getVal();
    pc_t       getPC();
    proId_t    getPid();
    delay_t    getDelay();

    // get parameters
    param_t getOpType();
    param_t getOpTypeByOpNum(opNum_t opNum);
    /********************************
     *  Binary Functions
     */
    size_t setFromBinary(binary_t binary);
    binary_t   getBinary();

    

    /********************************
     *  Printers
     */
    void print();
    void printParams();
    void printOpCode();
    void printPid();
    void printDelay();
    void printPC();
    void printAddr();
    void printVal();
    void printBIN();

    /********************************
     * Special Functions
     */


    /*Constructor*/
    Operation();
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
