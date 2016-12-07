# Memory Operation Dumper



## Contents

* [Use](#use)
    * [Create a Memory Operation](#create-a-memory-operation)
    * [Get binary data of a Memory Operation](#get-binary-data-of-a-memory-operation)
    * [Write memory operations into a binary file](#write-memory-operations-into-a-binary-file)
    * [Read memory operations from a binary file](#read-memory-operations-from-a-binary-file)
    * [Use Sync to generate simulated memory sync operations](#use-sync-to-generate-simulate-memory-sync-operations)
* [Classes](#classes)
    * [Operation](#operation)
        * Introduction
        * Constructions
        * Functions
        * Types
        * Constants
        * Macros
    * [Dumper](#dumper)
        * Introduction
        * Constructions
        * Functions
        * Types
        * Constants
    * [Sync](#sync)
        * Introduction 
        * Constructions
        * Functions
        * Types
        * Constants


## Use


### Create a Memory Operation

~~Need to add example and sample code for usage explanation~~

### Get binary data of a Memory Operation

~~Need to add example and sample code for usage explanation~~

### Write memory operations into a binary file

~~Need to add example and sample code for usage explanation~~

### Read memory operations from a binary file

~~Need to add example and sample code for usage explanation~~

### Use Sync to generate simulated memory sync operations

~~Need to add example and sample code for usage explanation~~

## Classes

### Operation

#### Introduction
The **Operation** class is the instance class for each individual memory operation. Each object has several properties to indicate the property of the memory operation.

#### Constructions
| Modifier  |Function   |Description |File   |
|:--------:|:---------------- |:-------------------------------- |:-------- |
|Constructor|Operation()|  Operation class constructor |operation.cpp|


#### Functions
<!--Operation Class Function Table-->
<table>
    <tr>
        <th>Modifier </th>
        <th>Function</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Input Functions</b></sub></td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setLoadOpCode(opCode_t opCode) </td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setStoreOpCode(opCode_t opCode)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setLiveCacheOp()</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setPid(proId_t pid)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setDelay(delay_t delay)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setPC(pc_t pc) </td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setAddr(addr_t addr)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setVal(val8_t val) </td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setVal(val16_t val)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setVal(val32_t val)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setVal(val64_t val)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setVal(val_t val)</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setLoadNeedData()</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setLoadNoData()</td>
        <td>~~need some explanation~~</td>
        <td>operation_set.cpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Output Functions</b></sub></td>
    </tr>
    <tr>
        <td>opCode_t</td>
        <td>getOpCode()</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>addr_t </td>
        <td>getAddr()</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>val_t</td>
        <td>getVal()</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>pc_t</td>
        <td>getPC()</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>proId_t</td>
        <td>getPid()</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>delay_t</td>
        <td>getDelay() </td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>param_t</td>
        <td>getOpType()</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td>param_t</td>
        <td>getOpTypeByOpNum(opNum_t opNum)</td>
        <td>~~need some explanation~~</td>
        <td>operation_get.cpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Binary Manipulation Functions</b></sub></td>
    </tr>
    <tr>
        <td>size_t </td>
        <td>setFromBinary(binary_t binary) </td>
        <td>~~need some explanation~~</td>
        <td>operation_binary.cpp</td>
    </tr>
    <tr>
        <td>binary_t</td>
        <td>getBinary()</td>
        <td>~~need some explanation~~</td>
        <td>operation_binary.cpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Parameter Print Functions</b></sub></td>
    </tr>
    <tr>
        <td>void</td>
        <td>print()</td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printParams()</td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printOpCode()</td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printPid() </td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printDelay()</td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printPC()</td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printAddr()</td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printVal() </td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
    <tr>
        <td>void</td>
        <td>printBIN() </td>
        <td>~~need some explanation~~</td>
        <td>operation_print.cpp</td>
    </tr>
</table>

#### Types

<!--Operation Class Type Table-->
<table>
    <tr>
        <th>Type</th>
        <th>Primitive Type</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Type for Basic Parameters</b></sub></td>
    </tr>
    <tr>
        <td>opCode_t</td>
        <td>uint8_t</td>
        <td>Type for opcode. 8 bits, unsigned. Different operations may have the same opcodes.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>proId_t</td>
        <td>uint16_t</td>
        <td>Type for processor ID. 16 bits, unsigned.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>delay_t</td>
        <td>uint16_t</td>
        <td>Type for delay time. 16 bits, unsigned.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>pc_t</td>
        <td>uint64_t</td>
        <td>Type for PC. 64 bits, unsigned.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>addr_t </td>
        <td>uint64_t</td>
        <td>Type for operation Address. 64 bits, unsigned. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Type for Different Size of Data</b></sub></td>
    </tr>
    <tr>
        <td>val8_t </td>
        <td>uint8_t</td>
        <td>Type for value. 8 bits, unsigned.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>val16_t</td>
        <td>uint16_t</td>
        <td>Type for value. 16 bits, unsigned. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>val32_t</td>
        <td>uint32_t</td>
        <td>Type for value. 32 bits, unsigned. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>val64_t</td>
        <td>uint64_t</td>
        <td>Type for value. 64 bits, unsigned. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>valUnit_t</td>
        <td>uint64_t</td>
        <td>Unit type for value larger than 64-bit. 64 bits, unsigned. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>val_t</td>
        <td>vector&lt;uint64_t&gt;</td>
        <td>Type for value larger than 64-bit. vector of 64-bit, unsigned. Length is fixed to 8 * uint64_t in the Operation object. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Type for Extra Parameters</b></sub></td>
    </tr>
    <tr>
        <td>param_t</td>
        <td>uint32_t</td>
        <td>Type for parameters. 32 bits, unsigned.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>opNum_t</td>
        <td>uint8_t</td>
        <td>Type for op number. 8 bits, unsigned.</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Type for Binary Output</b></sub></td>
    </tr>
    <tr>
        <td>binaryUnit_t</td>
        <td>uint8_t</td>
        <td>Unit Type for binary output. 8 bits, unsigned. </td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>binary_t</td>
        <td>vector&lt;uint8_t&gt;</td>
        <td>Type for binary output. vector of 8 bits, unsigned. Length is dynamic based on Operation object properties.</td>
        <td>operation.hpp</td>
    </tr>
</table>

#### Constants
<!--Operation Class Constants Table-->
<table>
    <tr>
        <th>Constant</th>
        <th>Value</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td>OPTYPE_LOAD</td>
        <td>(1)</td>
        <td>Number of load type code</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OPTYPE_STORE</td>
        <td>(3)</td>
        <td>Number of Store type code</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OPTYPE_LC</td>
        <td>(5)</td>
        <td>Number of Live Cache type code</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_0</td>
        <td>(0)</td>
        <td>Number of bytes for 0-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_8</td>
        <td>(1)</td>
        <td>Number of bytes for 8-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_16</td>
        <td>(2)</td>
        <td>Number of bytes for 16-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_32</td>
        <td>(4)</td>
        <td>Number of bytes for 32-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_64</td>
        <td>(8)</td>
        <td>Number of bytes for 64-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_128</td>
        <td>(16)</td>
        <td>Number of bytes for 128-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_256</td>
        <td>(32)</td>
        <td>Number of bytes for 256-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OP_DATASIZE_512</td>
        <td>(64)</td>
        <td>Number of bytes for 512-bit data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Parameter Default Value</b></sub></td>
    </tr>
    <tr>
        <td>DEFAULT_OPCODE</td>
        <td>(0)</td>
        <td>Default value of op code</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_PID</td>
        <td>(0)</td>
        <td>Default value of pid</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_DELAY </td>
        <td>(0)</td>
        <td>Default value of delay</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_PC</td>
        <td>(0)</td>
        <td>Default value of PC</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_ADDRESS</td>
        <td>(0)</td>
        <td>Default value of address</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_VALUE </td>
        <td>(0)</td>
        <td>Default value of data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_OPNUM </td>
        <td>(0)</td>
        <td>Default value of op number</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_OPTYPE</td>
        <td>(1)</td>
        <td>Default value of op type</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_DATASIZE</td>
        <td>(0)</td>
        <td>Default value of data size</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DEFAULT_LOADDATA</td>
        <td>(false)</td>
        <td>Default value of load-need-data</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Parameter Bit Width</b></sub></td>
    </tr>
    <tr>
        <td>OPCODE_BITS</td>
        <td>(8)</td>
        <td>Number of bits of op code</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>OPNUM_BITS</td>
        <td>(8)</td>
        <td>Number of bits of op number</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>PID_BITS</td>
        <td>(12)</td>
        <td>Number of bits of pid</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>DELAY_BITS</td>
        <td>(12)</td>
        <td>Number of bits of delay</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>PC_BITS</td>
        <td>(64)</td>
        <td>Number of bits of PC</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>ADDR_BITS </td>
        <td>(64)</td>
        <td>Number of bits of address</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>VAL_BITS</td>
        <td>(64)</td>
        <td>Number of bits of data unit</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>BIN_BITS</td>
        <td>(8)</td>
        <td>Number of bits of binary unit</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Parameter Effective Bit-Mask</b></sub></td>
    </tr>
    <tr>
        <td>EBMASK_OPCODE </td>
        <td>(NBITMASK(OPCODE_BITS))</td>
        <td>Effective Bit Mask of op code</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_OPNUM</td>
        <td>(NBITMASK(OPNUM_BITS) </td>
        <td>Effective Bit Mask of op number</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_PID</td>
        <td>(NBITMASK(PID_BITS))</td>
        <td>Effective Bit Mask of pid</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_DELAY</td>
        <td>(NBITMASK(DELAY_BITS))</td>
        <td>Effective Bit Mask of delay</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_PC </td>
        <td>(NBITMASK(PC_BITS))</td>
        <td>Effective Bit Mask of PC</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_ADDRESS</td>
        <td>(NBITMASK(ADDR_BITS - 3) << 3)</td>
        <td>Effective Bit Mask of address</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_VALUE</td>
        <td>(NBITMASK(VAL_BITS))</td>
        <td>Effective Bit Mask of data unit</td>
        <td>operation.hpp</td>
    </tr>
    <tr>
        <td>EBMASK_BIN</td>
        <td>(NBITMASK(BIN_BITS))</td>
        <td>Effective Bit Mask of binary unit</td>
        <td>operation.hpp</td>
    </tr>
</table>


#### Macros
<table>
    <tr>
        <th>Macro</th>
        <th>Final Expand</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td>NBITMASK(n)</td>
        <td>(0xFFFFFFFFFFFFFFFF >> (64 - (n)))</td>
        <td>Build a 64-bit mask, the lowest <i>n</i> bits is set and others are clear.</td>
        <td>operation.hpp</td>
    </tr>
</table>


### Dumper

#### Introduction

#### Constructions
<table>
    <tr>
        <th>Modifier</th>
        <th>Function</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td>Constructor</td>
        <td>Dumper()</td>
        <td>Empty Dumper class constructor.</td>
        <td>dumper.cpp</td>
    </tr>
    <tr>
        <td>Constructor</td>
        <td>Dumper(string filename, dumperMode_t mode)</td>
        <td>Dumper class constructor with file name and dump mode(write ops into file or read ops from file).</td>
        <td>dumper.cpp</td>
    </tr>
</table>

#### Functions
<table>
    <tr>
        <td>Modifier</td>
        <td>Function</td>
        <td>Description</td>
        <td>File</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>File Manipulation</b></sub></td>
    </tr>
    <tr>
        <td>bool</td>
        <td>openToWrite(string filename)</td>
        <td>~~need some explanation~~</td>
        <td>dumper.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>openToRead(string filename)</td>
        <td>~~need some explanation~~</td>
        <td>dumper.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>close()</td>
        <td>~~need some explanation~~</td>
        <td>dumper.cpp</td>
    </tr>
    <tr>
        <td colspan="4" ><sub><b>Operation Manipulation</b></sub></td>
    </tr>
    <tr>
        <td>bool</td>
        <td>add(Operation op)</td>
        <td>~~need some explanation~~</td>
        <td>dumper.cpp</td>
    </tr>
    <tr>
        <td>Operation</td>
        <td>get()</td>
        <td>~~need some explanation~~</td>
        <td>dumper.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>hasNext()</td>
        <td>~~need some explanation~~</td>
        <td>dumper.cpp</td>
    </tr>
</table>

#### Types

#### Constants




### Sync

#### Introduction 

#### Constructions
<table>
    <tr>
        <th>Modifier</th>
        <th>Function</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td>Constructor</td>
        <td>memsync()</td>
        <td>Empty memsync class constructor.</td>
        <td>sync.cpp</td>
    </tr>
   
</table>
#### Functions
<table>
    <tr>
        <th>Modifier</th>
        <th>Function</th>
        <th>Description</th>
        <th>File</th>
    </tr>
    <tr>
        <td>bool</td>
        <td>setMemset(memsyncAddr_t address, memsyncVal_t value, size_t num)</td>
        <td>Set up MEMSET syncing mode with destination address, value and number of units</td>
        <td>sync.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>setMemcpy(memsyncAddr_t src, memsyncAddr_t dest, size_t num)</td>
        <td>Set up MEMCPY syncing mode with source address, destination address and number of units</td>
        <td>sync.cpp</td>
    </tr>
    <tr>
        <td>Operation</td>
        <td>getNext()</td>
        <td>Get next Operation object based set syncing mode and parameters.</td>
        <td>sync.cpp</td>
    </tr>
    <tr>
        <td>bool</td>
        <td>hasNext()</td>
        <td>Check if there is any further syncing operation. Return true if there is; Return false if there is not.</td>
        <td>sync.cpp</td>
    </tr>
</table>

#### Types

#### Constants

