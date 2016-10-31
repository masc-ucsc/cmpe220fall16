#include "dumper.h"



dumper:: dumper(string filename)
{
    this->file.open(filename, ios::out| ios::binary | ios::trunc);
}

bool dumper::dump()
{
    while(!this->insq.empty())
    {
        array<uint32_t, BINARY_SIZE> ins = this->insq.front();
        this->insq.pop();
        for(int i = 0; i < BINARY_SIZE; i++)
            this->file.write((char*) &ins[i], sizeof(uint32_t));;
    }

    return true;
}

bool dumper::closeFile()
{
    this->file.close();
    return true;
}

bool dumper::add(array<uint32_t, BINARY_SIZE> binary)
{
    this->insq.push(binary);

    return true;
}


