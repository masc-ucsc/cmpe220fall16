// dcache pass-through testbench
// team: Nursultan, Nilufar

#include "VDC_top_bank_tag.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include  "DC_memc.h"
#include "DC_bank_test.h"
#include "DC_tag_test.h"


#include  "DC_define.h"
#include <list>

#include <time.h>

#define DEBUG_TRACE 1

// turn on/off testbench
#define TEST_L2_TO_L1_SNACK   1
#define TEST_CORE_TO_DC       1
vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;
long ntests = 0;
//******************** Clock Adding

//////////////Clock Ending

///////////////////////////////////////////////////////////
// pair #1
// l2tol1_snack_packet --> dctocore_ld_packet
///////////////////////////////////////////////////////////


void advance_half_clock(VDC_top_bank_tag *top) {
#ifdef TRACE
  tfp->dump(global_time);
#endif

  top->eval();
  top->clk = !top->clk;
  top->eval();
  
  global_time++;
  if (Verilated::gotFinish())  
    exit(0);
}

void advance_clock(VDC_top_bank_tag *top, int nclocks=1) {

  for( int i=0;i<nclocks;i++) {
    for (int clk=0; clk<2; clk++) {
      advance_half_clock(top);
    }
  }
}

void sim_finish(bool pass) {
#ifdef TRACE
  tfp->close();
#endif

#if 1
  if (pass)
    printf("\nTB:PASS\n");
  else
    printf("\nTB:FAILED\n");
#endif

  exit(0);
}


struct dctocore_ld_packet { //output
 int data0;

};


struct coretodc_ld_packet { //input to DUT
 int ckpid;
 int coreid;
 int lop;
 int pnr;
 int pcsign;
 int poffset;
 int imm;

};

struct l1tlbtol1_fwd_packet { //input to DUT
 int coreid;
 int prefetch;
 int l2_prefetch;
 int fault;
 int ppaddr; 
 int hpaddr;
};


coretodc_ld_packet generateRand_coretodc_ld_packet() {
  coretodc_ld_packet result;

  result.ckpid = 0;
  result.coreid = 0;
  result.lop = rand()&0x1f;
  result.pnr = rand()&0x1;
  result.pcsign = rand()&0x1fff;
  result.poffset = rand()&0xfff;
  result.imm = rand()&0xfff;

  return result;
}

// generate l1tlbtol1_fwd packet with random values
l1tlbtol1_fwd_packet generateRand_l1tlbtol1_fwd_packet() {
  l1tlbtol1_fwd_packet result;

  result.coreid = 0;
  result.prefetch = 0;
  result.l2_prefetch = 0;
  result.fault = rand()&0x7;
  result.hpaddr = rand() & 0x03ff;
  result.ppaddr = rand()&0x7;

  return result; 
}


void try_send_coretodc_ld(VDC_top_bank_tag *top,coretodc_ld_packet* input_core_DC, l1tlbtol1_fwd_packet* TLB_DC,index_tag* index_input) {
  //randomize validity of the packet

    top->row_even_odd=index_input->bank_even_bit;
    printf(" \ntop->row_even_odd:%x ",  top->row_even_odd);
    cout<< "and in C++ is " <<index_input->bank_even_bit<<endl;
    top->clk=1;
    top->reset=1;
    top->req_valid=1;
    top->write=1;
    top->ack_retry=0;
    top->req_data=8;
    top->req_tag=TLB_DC->hpaddr;
    cout<< "top->req_tagand in C++ is " <<top->req_tag<<"and"<<TLB_DC->hpaddr<<endl;
    top->index=index_input->index_bit;
    top->bank_sel=index_input->bank_sel;
    top->coretodc_ld_req=CORE_MOP_XS32; 
    top->coretodc_std_valid=1;
    top->l2tol1_snack_valid=0;
    top->l2tol1_snack=0;

#ifdef DEBUG_TRACE
    printf("@%lld ",global_time);
    printf("ckpid:%x ", input_core_DC->ckpid);
    printf("coreid:%x ", input_core_DC->coreid);
    printf("lop:%x ", input_core_DC->lop);
    printf("pcsign:%x ", input_core_DC->pcsign);
    printf("poffset:%x ",input_core_DC->poffset);
    printf("imm:%x\n", input_core_DC->imm);
    printf("ppaddr:%x ", TLB_DC->ppaddr);
    printf("hpaddr:%x\n", TLB_DC->hpaddr);
    printf("top Clk is :%x ",  top->clk);
    printf("top->req_tag is %x",TLB_DC->hpaddr);
    printf("top->index%x", top->index);
  
#endif
}

//*************************************************************************

//try recv
void try_recv_dctocore_ld(VDC_top_bank_tag *top, int a) {
 
#ifdef DEBUG_TRACE
   int d=top->ack_data_from_top;
   cout<<" I am in golobal time"<<endl;
   printf("\ndata_0 is :%x\n", d);
   cout<<" I am in data printing by receiving .......\n";
#endif
  bool f = false;
  if (d!= a) {
   printf("ERROR: expected data0 is %x but data0 is %x\n",a,top-> ack_data_from_top,"Lima");
    f=true;
  }
cout<<" Exiting from  Recieveing from DUT";
}

// generate coretodc_ld packet with random values
// try send
int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  VDC_top_bank_tag* top = new VDC_top_bank_tag;

  int t = (int)time(0);
  srand(t);
  coretodc_ld_packet input_core_DC = generateRand_coretodc_ld_packet();
  l1tlbtol1_fwd_packet TLB_DC =generateRand_l1tlbtol1_fwd_packet();
  cout<< "\n Entering into Tag-bank Object.........\n";
  cout<< " \noffset and imm are is ...."<<input_core_DC.poffset<<" "<<input_core_DC.imm<<endl;
  int addr=input_core_DC.poffset+input_core_DC.imm;

  tag_req_data req_data;
  req_data.tag=TLB_DC.hpaddr;

  cout<<" In C++ DUT......TAg is "<<TLB_DC.hpaddr<<endl;
  cout<<" in C++ DUT...address is "<<addr<<endl;
  req_data.state=M;
  req_data.counter=3;

  index_tag index_input;
  tag_bank tag_bank_A;
  index_input=tag_bank_A.get_index(addr);

 //cout<<" In main Index is"<<index_input;
 int write_hit;
 cout<<" Before Writing .....Index in Data Bank C++ DUT is "<<index_input.index_bit <<" and TAg is :"<<req_data.tag<<endl;
 tag_bank_A.write_in_tagbank(index_input.index_bit, &req_data);
 cout<<" \nIn main C++ Index and Tag "<<index_input.index_bit <<"and"<<req_data.tag<<endl;
 int way;
 cout<<" Wrting in C++ Finish!!!"<<endl;
 way=tag_bank_A.Read_and_Get_way_no(index_input.index_bit, &req_data);
 cout<<"\nReading ..TAgbank way in main is "<<way<<endl;
 cout<< "\n Hurry!!!Tag-bank created..........\n";
//*************************************************************BANK STARTS

 databank_1 databank_,databank0,databank1,databank2,databank3,databank4,databank5,databank6,databank7;
 bool write_enable=1;
 int bank_sel_=index_input.bank_sel;
 cout<<" Bank_sel is "<<bank_sel_;
 switch(bank_sel_){

case 0 : databank_=databank0; cout<<"Hurry!!!!!!!....DATA BANK...This time is 0"; break;
case 1 : databank_=databank1; cout<<"Hurry!!!!!!!....DATA BANK...This time is 1"; break;
case 2 : databank_=databank2; cout<<"Hurry!!!!!!!....DATA BANK...This time is 2"; break;
case 3 : databank_=databank3; cout<<"Hurry!!!!!!!....DATA BANK...This time is 3"; break;
case 4 : databank_=databank4; cout<<"Hurry!!!!!!!....DATA BANK...This time is 4"; break;
case 5 : databank_=databank5; cout<<"Hurry!!!!!!!....DATA BANK...This time is 5"; break;
case 6 : databank_=databank6; cout<<"Hurry!!!!!!!....DATA BANK...This time is 6"; break;
case 7 : databank_=databank7; cout<<"Hurry!!!!!!!....DATA BANK...This time is 7";break;
default: databank_=databank_; cout<<"Hurry!!!!!!!....DATA BANK...This time is default banks is "<<bank_sel_;break;

}
 int pos_read_write;
 pos_read_write=databank_.get_read_write_pos(index_input.index_bit,way,index_input.bank_even_bit);
 int data=8;
 databank_.write_one_bank(8,pos_read_write);
 databank_.set_write_Musk(write_enable,pos_read_write);
 cout<<" \nFinished Writing..........\n";
 int a= databank_.Get_Read_one_bank(pos_read_write);
 cout<<" \n....Finished Reading ... Data is "<<a<<"........in c++.......Now in testbench.........."<<endl;

#ifdef TRACE
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open("DC_top_bank_tag_output.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;
 // top->reset = 1;

   // Long reset to give time to the state machine
  //-------------------------------------------------------
  top->reset = 0;
//advance_clock(top,1);
int nclocks=3;

#if TEST_CORE_TO_DC
  for (int i=0; i<5; i++) {
    try_send_coretodc_ld(top,&input_core_DC,&TLB_DC,&index_input);
    advance_clock(top, nclocks);
cout<<" AFter Sending to COre....";
cout<<" DAta"<<top->ack_data_from_top;  
try_recv_dctocore_ld(top,a);
  //advance_half_clock(top);   
cout<<" COmplete 1st Cyle....";  
//advance_clock(top, nclocks);
}
#endif
 sim_finish(true);

}




















