#include <iostream> 
#include <vector>

using namespace std;

struct databank_entry{
int data;
int write_musk_reset[3];
};

class databank_1 {
 
private:

databank_entry data_bank_one[512];

public:
databank_1 (){ cout<<"Creating 1 Data Bank..............\n";
}

~databank_1 (){ cout<<"Deleting the previous Data Bank............\n";
}

void set_write_Musk(bool write_enable,int pos_read_write ){

if(write_enable){ cout<<"\nSetting the write musk: "; 
   for(int i=0;i<=3;i++)
   {data_bank_one[pos_read_write].write_musk_reset[i]=1;
    cout<<data_bank_one[pos_read_write].write_musk_reset[i]<<" ";
    }
                }
}

int  get_read_write_pos(int index, int way, bool odd_even){
 int req_pos_bank = (index*16)+(way*2)+odd_even;
 cout<<"\n Getting write Position for Index:"<<index<<" and way: "<<way<<".......Position is "<<req_pos_bank;
 return req_pos_bank;

}

void write_one_bank( int data,int pos_read_write){
 data_bank_one[pos_read_write].data=data;
 cout<<"  Writting data at position "<< pos_read_write <<"is "<<data_bank_one[pos_read_write].data;
 }

int  Get_Read_one_bank(int pos_read_write){
 int read_data;
 read_data=data_bank_one[pos_read_write].data;
 cout<<" Reading data at position is "<< pos_read_write <<"is"<<data_bank_one[pos_read_write].data;
 cout<<"Return.....problem";
 return read_data;
}

};









