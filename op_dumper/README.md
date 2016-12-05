# Memory Operation Dumper



## Contents

* [Use](#use)
	* [Sample tests](#sample-tests)
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

### Sample tests

In folder *./tests/* copy any file you want into the root folder, rename it as **main.cpp** or **make sure there is and only is one main function** in the the compiling. Use "*make*" or "*make clean make*" to compile and run the program.

### Create a Memory Operation

~~Need to add example and sample code for usage explaination~~

### Get binary data of a Memory Operation

~~Need to add example and sample code for usage explaination~~

### Write memory operations into a binary file

~~Need to add example and sample code for usage explaination~~

### Read memory operations from a binary file

~~Need to add example and sample code for usage explaination~~

### Use Sync to generate simulated memory sync operations

~~Need to add example and sample code for usage explaination~~

## Classes


### Operation

#### Introduction

The **Operation** class is the instance class for each individual memory operation. Each object has several properties to indicate the property of the memory operation.

#### Constructions
| Modifier  |Function   |Description |File   |
|:---------:|:---------:|:----------:|:-----:|
|Constructor|Operation()|  Operation class constructor |operation.cpp|


#### Functions
| Modifier  |Function   |Description |File   |
|:---------:|:---------|:----------|:-----|
|bool|setLoadOpCode(opCode_t opCode)|~~need some explaination~~|operation_set.cpp|
|bool|setStoreOpCode(opCode_t opCode)|~~need some explaination~~|operation_set.cpp|
|bool|setLiveCacheOp()                  |~~need some explaination~~|operation_set.cpp|
|bool|setPid(proId_t pid)               |~~need some explaination~~|operation_set.cpp|
|bool|setDelay(delay_t delay)           |~~need some explaination~~|operation_set.cpp|
|bool|setPC(pc_t pc)                    |~~need some explaination~~|operation_set.cpp|
|bool|setAddr(addr_t addr)              |~~need some explaination~~|operation_set.cpp|
|bool|setVal(val8_t val)                |~~need some explaination~~|operation_set.cpp|
|bool|setVal(val16_t val)               |~~need some explaination~~|operation_set.cpp|
|bool|setVal(val32_t val)               |~~need some explaination~~|operation_set.cpp|
|bool|setVal(val64_t val)               |~~need some explaination~~|operation_set.cpp|
|bool|setVal(val_t val)                 |~~need some explaination~~|operation_set.cpp|
|bool|setLoadNeedData()                 |~~need some explaination~~|operation_set.cpp|
|bool|setLoadNoData()                   |~~need some explaination~~|operation_set.cpp|
|opCode_t|getOpCode()                   |~~need some explaination~~|operation_get.cpp|
|addr_t|getAddr()                       |~~need some explaination~~|operation_get.cpp|
|val_t|getVal()                         |~~need some explaination~~|operation_get.cpp|
|pc_t|getPC()                    		|~~need some explaination~~|operation_get.cpp|
|proId_t|getPid()                		|~~need some explaination~~|operation_get.cpp|
|delay_t|getDelay()              		|~~need some explaination~~|operation_get.cpp|
|param_t|getOpType()                    |~~need some explaination~~|operation_get.cpp|
|param_t|getOpTypeByOpNum(opNum_t opNum)|~~need some explaination~~|operation_get.cpp|
|size_t|setFromBinary(binary_t binary)|~~need some explaination~~|operation_binary.cpp|
|binary_t|getBinary()|~~need some explaination~~|operation_binary.cpp|
|void|print()|~~need some explaination~~|operation_print.cpp|
|void|printParams()|~~need some explaination~~|operation_print.cpp|
|void|printOpCode()|~~need some explaination~~|operation_print.cpp|
|void|printPid()|~~need some explaination~~|operation_print.cpp|
|void|printDelay()|~~need some explaination~~|operation_print.cpp|
|void|printPC()|~~need some explaination~~|operation_print.cpp|
|void|printAddr()|~~need some explaination~~|operation_print.cpp|
|void|printVal()|~~need some explaination~~|operation_print.cpp|
|void|printBIN()|~~need some explaination~~|operation_print.cpp|


#### Types


#### Constants


#### Macros



### Dumper

#### Introduction

#### Constructions
| Modifier  |Function   |Description |File   |
|:---------:|:---------|:----------|:-----|
|Constructor|Dumper()|~~need some explaination~~|dumper.cpp|

#### Functions
| Modifier  |Function   |Description |File   |
|:---------:|:---------|:----------|:-----|
|bool|()|~~need some explaination~~|dumper.cpp|

#### Types

#### Constants




### Sync

#### Introduction 

#### Constructions
| Modifier  |Function   |Description |File   |
|:---------:|:---------|:----------|:-----|
|Constructor|sync()|~~need some explaination~~|sync.cpp|

#### Functions
| Modifier  |Function   |Description |File   |
|:---------:|:---------|:----------|:-----|
|bool|()|~~need some explaination~~|sync.cpp|


#### Types

#### Constants


