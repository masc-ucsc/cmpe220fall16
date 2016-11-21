#include "dumper.h"



/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::add(binary_t binary)
{
    // Pre-checks
    checkMode(mode_write);
    checkFileState();

    if(binIsStoreOp(binary[0]))
    {
        this->file.write((char *)&binary, sizeof(binary_t));
    }else
    {
        this->file.write((char *)&binary, sizeof(binary_t) - VAL_VAR_BYTE);
    }

    return true;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
binary_t dumper::get()
{
    // Pre-checks
    checkMode(mode_read);
    checkFileState();

    binary_t binary;
    // Initialize binary
    memset(&binary, 0, sizeof(binary));

    // EOF: end of the file. Return empty binary
    if(this->file.eof())
    {
        return binary;
    }

    if(binIsStoreOp(this->file.peek()))
    {
        this->file.read((char *)&binary[0], sizeof(binary_t));
    }else
    {
        this->file.read((char *)&binary[0], sizeof(binary_t) - VAL_VAR_BYTE);
    }

    return binary;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::hasNext()
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
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::openToWrite(string filename)
{
    this->open(filename, mode_write);

    return true;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::openToRead(string filename)
{
    this->open(filename, mode_read);

    return true;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::open(string filename, dumperMode_t mode)
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
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::close()
{
    this->file.close();
    this->mode = mode_uninit;
    return true;
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void dumper::checkMode(dumperMode_t mode)
{
    if(mode != mode_read && mode != mode_write)
    {
        cout << endl << "ERROR: dumper file operation is invalid!" << endl;
        exit(ERROR_DumperModeInvalid);
    }

    string modeName[] = {"UNINITIALIZED", "WRITE", "READ"};

    if(mode != this->mode)
    {
        cout << endl << "ERROR: dumper operation " << modeName[mode] << " is not compatible with current mode " << modeName[this->mode] <<"!" << endl;
        exit(ERROR_DumperModeInvalid);
    }
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
void dumper::checkFileState()
{
    if(!this->file.is_open())
    {
        cout << endl << "ERROR: dumper must open a file before any operation" << endl;
        exit(ERROR_DumperFileInvalid);
    }
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
bool dumper::binIsStoreOp(binaryUnit_t binary_0)
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
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
uint8_t dumper::getFilePeek()
{
    return this->file.peek();
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
dumper:: dumper()
{
    // Do nothing
}


/*********************************************************************
* @fn      dumper::
*
* @brief   ...
*
* @param   none
*
* @return  none
*/
dumper:: dumper(string filename, dumperMode_t mode)
{
    this->file.open(filename, ios::out| ios::binary | ios::trunc);
    this->mode = mode;
}


