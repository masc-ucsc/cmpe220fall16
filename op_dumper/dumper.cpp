/*******************************************************************************
  Filename:       dumper.cpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#include "dumper.hpp"



/*********************************************************************
* @fn      Dumper::add
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::add(Operation op)
{
    // Pre-checks
    checkMode(mode_write);
    checkFileState();

    binary_t bin = op.getBinary();

    for(uint32_t i = 0; i < bin.size(); i++) {
        this->file.write((char *)&bin.at(i), sizeof(binaryUnit_t));
    }

    return true;
}


/*********************************************************************
* @fn      Dumper::get
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
Operation Dumper::get()
{
    // Pre-checks
    checkMode(mode_read);
    checkFileState();

    binaryUnit_t binUnit;
    Operation op = Operation();

    // Get Op Number
    this->file.read((char *)&binUnit, 1);

    // Special case for LIVE CACHE
    if(op.getOpTypeByOpNum(binUnit) == OPTYPE_LC) {
        op.setLiveCacheOp();
        addr_t address = 0;
        for(int i = 0; i < 8; i++) {    // NOTE: change if address is not 64-bit
            this->file.read((char *)&binUnit, 1);
            address |= (((addr_t)binUnit) << (i*8));
        }
        op.setAddr(address);
        return op;
    }

    // Read Fixed elements
    binary_t binary;
    binary.push_back(binUnit);

    for(int i = 0; i < 19; i++) {   // NOTE: change if rest of the fixed part changed
        this->file.read((char *)&binUnit, 1);
        binary.push_back(binUnit);
    }

    // Fixed Element read END

    // Get data size
    param_t dataSize = op.setFromBinary(binary);

    // Get data
    val_t data;
    valUnit_t dataUnit = 0;
    for(param_t i = 0; i < dataSize; i++) {
        if(i%8 == 0) {
            dataUnit = 0;
        }

        this->file.read((char *)&binUnit, 1);
        dataUnit |= (((valUnit_t)binUnit & EBMASK_BIN) << ((i*8) % 64));

        if((i + 1) % 8 == 0) {
            data.push_back(dataUnit);
        }
    }
    if(dataSize > data.size() * 8) {
        data.push_back(dataUnit);
    }
    op.setVal(data);

    return op;
}


/*********************************************************************
* @fn      Dumper::hasNext
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::hasNext()
{
    // Pre-checks
    checkFileState();

    auto ptr = this->file.tellg();

//    char c;
//    c = this->file.get();
//    printf("get a c: %x\n", c);

    this->file.get();

    if(this->file.eof())
    {
        // End Of File
        return false;
    }else
    {
        this->file.seekg(ptr);
        return true;
    }
}


/*********************************************************************
* @fn      Dumper::openToWrite
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::openToWrite(string filename)
{
    this->open(filename, mode_write);

    return true;
}


/*********************************************************************
* @fn      Dumper::openToRead
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::openToRead(string filename)
{
    this->open(filename, mode_read);

    return true;
}


/*********************************************************************
* @fn      Dumper::open
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::open(string filename, dumperMode_t mode)
{
    if(mode == mode_write)
    {
        this->file.open(filename, ios::out| ios::binary | ios::trunc);
    }else if(mode == mode_read)
    {
        this->file.open(filename, ios::in| ios::binary);
    }else
    {
        checkMode(mode);
    }

    this->mode = mode;

    return true;
}


/*********************************************************************
* @fn      Dumper::close
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::close()
{
    this->file.close();
    this->mode = mode_uninit;
    return true;
}


/*********************************************************************
* @fn      Dumper::checkMode
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Dumper::checkMode(dumperMode_t mode)
{
    if(mode != mode_read && mode != mode_write)
    {
        cout << endl << "ERROR: Dumper file operation is invalid!" << endl;
        exit(ERROR_DumperModeInvalid);
    }

    string modeName[] = {"UNINITIALIZED", "WRITE", "READ"};

    if(mode != this->mode)
    {
        cout << endl << "ERROR: Dumper operation " << modeName[mode] << " is not compatible with current mode " << modeName[this->mode] <<"!" << endl;
        exit(ERROR_DumperModeInvalid);
    }
}


/*********************************************************************
* @fn      Dumper::checkFileState
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void Dumper::checkFileState()
{
    if(!this->file.is_open())
    {
        cout << endl << "ERROR: Dumper must open a file before any operation" << endl;
        exit(ERROR_DumperFileInvalid);
    }
}


/*********************************************************************
* @fn      Dumper::binIsStoreOp
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool Dumper::binIsStoreOp(binaryUnit_t binary_0)
{
    if((binary_0 >> 7) == 0)
    {
        // Store op: HSB is 0
        return true;
    }else
    {
        // Load op: LSB is 1
        return false;
    }
}


/*********************************************************************
* @fn      Dumper::getFilePeek
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
uint8_t Dumper::getFilePeek()
{
    return this->file.peek();
}


/*********************************************************************
* @fn      Dumper::constructor
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
Dumper:: Dumper()
{
    // Do nothing
}


/*********************************************************************
* @fn      Dumper::constructor
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
Dumper:: Dumper(string filename, dumperMode_t mode)
{
    this->file.open(filename, ios::out| ios::binary | ios::trunc);
    this->mode = mode;
}


