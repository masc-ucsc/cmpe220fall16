#include <iostream>
#include "DC_define.h"
#include "scmemc.h"

using namespace std;

bool NO_TAG_PRESENT;

struct index_tag {
int index_bit;
int slice_bit;
int bank_even_bit;
int pipe_bit;
int bank_sel;
};
struct tag_req_data { //15 bits
  int tag;
 int state;
 int counter;

};

struct tag_input{

tag_req_data 	req_data;
int coretodc_ld_req;
int coretodc_std_req;
int l2tol1_snack;
int index;
};

struct tag_output{
int l1tol2req;
int way_no;
};


class tag_bank{

private:
 

 tag_req_data	tagbank_data[256];
 tag_input input_req;
 tag_output output_tag;
 
 int next_action;
 bool hit;
 bool miss;

public:

tag_bank(){ cout<< "\n Creating Tag-bank0 ..........Now I am in Constructor"<<endl;

for(int i=0;i<256;i++)
{
  tagbank_data[i]={0,I,3};
  cout<< ";";
}
}

~tag_bank(){cout<< "\n Destructig Tag-bank0 ..........\n Now I am in Destructor\n";}

void write_in_tagbank(int index, tag_req_data* req_data)
{    int way;

     cout<<" TAg in Write function"<<req_data->tag<<endl;
 for(int way_no=0;way_no<=7;way_no++)
    { cout<<"way is "<<way_no<<endl;
      int req_pos_in_tag = (index*8+way_no);
     if (tagbank_data[req_pos_in_tag ].tag==req_data->tag)
         {
	 way=way_no;
         hit=1; 
         miss=0;
 cout<<" \nWriting in TagBAnk.....HIT: Getting the Way_no..."<<way;
	 tagbank_data[index*8+way].tag=req_data->tag;
         tagbank_data[index*8+way].state=M;
         tagbank_data[index*8+way].counter=3;  
         cout<<" \nComplete Writing in Tagbank in HiT..........\n"<<" Tag:"<< tagbank_data[way].tag<<" State:"<<tagbank_data[way].state<<" Counter:"<<  tagbank_data[way].counter;
	//return 1;
        } //if 
    	
     else //
	 {NO_TAG_PRESENT=1;
         hit=0; 
         miss=1;//return -1 if miss
        cout<<"Writing in TagBAnk.....MiSS:**********..."<<endl;	
         }//else

         cout<<"way ened"<<endl;
 
}//for

 if (miss==1){

     for(int way_no=0;way_no<=7;way_no++)
       {cout<<"way is "<<way_no<<" index is"<<index<<endl;
       int req_pos_in_tag = (index*8+way_no);
       cout<<"counter is "<<tagbank_data[req_pos_in_tag ].counter<<endl;
      if(tagbank_data[req_pos_in_tag ].counter==3)
	 { tagbank_data[index*8+way_no].tag=req_data->tag;
           cout<<"tag is "<<tagbank_data[req_pos_in_tag ].tag<<endl;
           tagbank_data[index*8+way_no].state=M;
           cout<<"state is "<<tagbank_data[req_pos_in_tag ].state<<endl;
           tagbank_data[index*8+way_no].counter--;
           cout<<"counter is "<<tagbank_data[req_pos_in_tag ].counter<<endl;
           cout<<" \nComplete Writing in Tagbank in Miss.........."<<endl;
             return ;	
         }
      else 
           {tagbank_data[req_pos_in_tag].counter--;
             cout<<" \nCounter...."<<tagbank_data[req_pos_in_tag ].counter;
              }
      }//for

}//if
//TODO
}


int  Read_and_Get_way_no( int index, tag_req_data* req_data){

 cout<<" \nTag is "<<req_data->tag<<" and Index :"<<index;
 cout<<"\nCAche state"<<req_data->state;
for(int way_no=0;way_no<=7;way_no++)
 {
   int req_pos_in_tag = (index*8+way_no);
   if (tagbank_data[req_pos_in_tag ].tag==req_data->tag)
         {
	 int way=way_no;
         if(tagbank_data[req_pos_in_tag].state!=I) //what happens if cacheline is hit but in I state?
         {
         hit=1; 
         miss=0;
         cout<<" \nReading in TagBAnk.....HIT: Getting the Way_no..."<<way;
	return way;
      }
        } //if 
    	
     else //
         {NO_TAG_PRESENT=1;
         hit=0; 
         miss=1;//return -1 if miss
         cout<<" \nNo ......Reading in TagBAnk.....MiSS:**********...";	
         return -1; 
}//else 
}//for 
}//func 


int Set_cacheline_next_state(int state_bits, int req_type, bool req_valid ,int snack_type, bool snack_valid , int next_action_req, int next_state_bits)
{

if(req_type==CORE_LOP_L32U && req_valid)

  {  if (state_bits==US)  next_state_bits=US;
                            else if (state_bits==UM) next_state_bits=UM; 
				else if (state_bits==S) next_state_bits=S; 
					else 	next_state_bits	=  state_bits;  
}  


if(req_type==CORE_MOP_S32 && req_valid)

  {
  if (state_bits==US) next_state_bits=UM;
                            else if (state_bits==S) next_state_bits=UM; 
				else if (state_bits==S) next_state_bits=M; 
					else 	next_state_bits	=  M;    
  }


 
if (snack_valid)
{ 
 switch(snack_type){

 case SC_SCMD_ACK_S : if (state_bits==US)  next_state_bits=US;
                            else if (state_bits==UM) next_state_bits=UM; 
				
					else 	if (state_bits==M)  next_state_bits=S; //******l1tol2_disp=SC_DCMD_WS;l1tol2_disp_valid=1;
						else 	if (state_bits==E) next_state_bits=S; 
							else 	if (state_bits==S) next_state_bits=S; 
								else 	next_state_bits	=  state_bits;  

						    
		


 case SC_SCMD_ACK_E : if (state_bits==US) next_state_bits=US;
                            else if (state_bits==UM) next_state_bits=UM; 
			 				else 	if (state_bits==M)  next_state_bits=US; //****l1tol2_disp=SC_DCMD_WS;
						            else 	if (state_bits==E) next_state_bits=US; 
							         else 	if (state_bits==S) next_state_bits=US; 
								     else 	next_state_bits	=  state_bits;   

						    
		




 case SC_SCMD_ACK_M : if (state_bits==I) next_state_bits=E;
                            else if (state_bits==I) next_state_bits=S; 
			 		else 	next_state_bits	=  state_bits;   

						    
		


 default:    next_state_bits =  state_bits; 

}//case
}

}//func 

/*

index_tag get_index( int addr){

index_tag a;
a.index_bit=32 & 0xf80;//VA[11:7]
a.slice_bit=addr & 0x40;//VA[6]
a.bank_even_bit=32 & 0x20;//VA[5]
a.pipe_bit=32 & 0x10;//VA[4]
a.bank_sel=7 & 0x001c;
return a;
}*/


index_tag get_index( int addr){
index_tag a;
a.index_bit=1;//VA[11:7]
a.slice_bit=addr & 0x40;//VA[6]
a.bank_even_bit=0;//VA[5]
a.pipe_bit=32 & 0x10;//VA[4]
a.bank_sel=2;
return a;
}


int Get_RRIP_way_no (int l2tol1_snack_valid, int l2tol1_snack, int index)
{
  if (l2tol1_snack_valid && NO_TAG_PRESENT) {
     if((l2tol1_snack==SC_SCMD_ACK_S)||(l2tol1_snack==SC_SCMD_ACK_M)||(l2tol1_snack==SC_SCMD_ACK_S))
       {   for(int way_no=0;way_no<=7;way_no++){
               int req_pos_in_tag = (index*8+way_no);
               if(tagbank_data[req_pos_in_tag ].counter==3)
	             return way_no;
	       else 
                      tagbank_data[req_pos_in_tag ].counter++;
}//for
}//if1
}//if2
}//func
};//class tag_bank








 

