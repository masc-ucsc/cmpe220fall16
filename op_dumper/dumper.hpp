/*******************************************************************************
  Filename:       dumper.hpp
  Revised:        $Date: 2016-10-21 $
  Revision:       $Revision: $
  author:         Zhehao Ding

  Description:    This file is 
*******************************************************************************/


#ifndef DUMPER_H_INCLUDED
#define DUMPER_H_INCLUDED


#include "errorcode.hpp"
#include "operation.hpp"

using namespace std;

/********************************
*   Macros
*
*/


/********************************
*   Type define
*
*/
typedef uint8_t    dumperMode_t;


/********************************
*   Constants
*
*/
static const dumperMode_t   mode_uninit = 0;
static const dumperMode_t   mode_read   = 1;
static const dumperMode_t   mode_write  = 2;


/********************************
*   Classes
*
*/
class Dumper{
private:
    fstream        file;
    dumperMode_t    mode;

    // open file
    bool open(string filename, dumperMode_t mode);

    // check params
    void checkMode(dumperMode_t mode);
    void checkFileState();
    bool binIsStoreOp(binaryUnit_t binary_0);
    uint8_t getFilePeek();
    
public:
    // constructor
    Dumper();
    Dumper(string filename, dumperMode_t mode);

    // file operations
    // open file
    bool openToWrite(string filename);
    bool openToRead(string filename);
    bool close();

    // file R/W
    bool add(Operation op);
    Operation get();

    // Tool
    bool hasNext();
    
};


#endif // DUMPER_H_INCLUDED
