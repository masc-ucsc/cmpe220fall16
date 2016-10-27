
#include "Vdirectory_bank_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

//Set which sets you want to run
//#define TEST_PFREQ 1
#define TEST_REQ 1
//#define TEST_ACK 1

#define TEST_REQ_FAILURE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

//Used for testing failure state
int valid_count = 0;

//Below is code from other tb
void advance_half_clock(Vdirectory_bank_wp *top) {
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

void advance_clock(Vdirectory_bank_wp *top, int nclocks=1) {

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

  if (pass)
    printf("\nTB:PASS\n");
  else
    printf("\nTB:FAILED\n");

  exit(0);
}

struct InputPacket_l2todr_pfreq {
  uint64_t addr;
};

struct OutputPacket_drtomem_pfreq {
  uint64_t addr; // read result
};

struct InputPacket_l2todr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t addr;
};

struct OutputPacket_drtomem_req {
  uint8_t drid;
  uint8_t cmd;
  uint64_t addr; // read result
};

struct InputPacket_memtodr_ack {
  uint8_t drid;
  uint8_t ack_cmd;
  uint64_t line_7;
  uint64_t line_6;
  uint64_t line_5;
  uint64_t line_4;
  uint64_t line_3;
  uint64_t line_2;
  uint64_t line_1;
  uint64_t line_0;
};

struct OutputPacket_drtol2_snack {
  uint8_t nid;
  uint8_t l2id;
  uint8_t drid;
  uint8_t ack_cmd;
  uint64_t addr; // read result
  uint64_t line_7;
  uint64_t line_6;
  uint64_t line_5;
  uint64_t line_4;
  uint64_t line_3;
  uint64_t line_2;
  uint64_t line_1;
  uint64_t line_0;
  
};

double sc_time_stamp() {
  return 0;
}

uint16_t memory[256];

std::list<InputPacket_l2todr_pfreq>  inp_list_pfreq;
std::list<OutputPacket_drtomem_pfreq> out_list_pfreq;

std::list<InputPacket_l2todr_req>  inp_list_req;
std::list<OutputPacket_drtomem_req> out_list_req;

std::list<InputPacket_memtodr_ack>  inp_list_ack;
std::list<OutputPacket_drtol2_snack> out_list_ack;

void error_found(Vdirectory_bank_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_send_packet(Vdirectory_bank_wp *top) {
  
  //pfreq
  top->drtomem_pfreq_retry = (rand()&0x3F)==0; 

  if (!top->l2todr_pfreq_retry) {
    top->l2todr_pfreq_paddr = rand();
    if (inp_list_pfreq.empty() || (rand() & 0x3)) { // Once every 4
      top->l2todr_pfreq_valid = 0;
    }else{
      top->l2todr_pfreq_valid = 1;
    }
  }
  
  //req
#ifdef TEST_REQ_FAILURE
  if(valid_count == 1)
    top->drtomem_req_retry = 1;
  else
    top->drtomem_req_retry = 0;
  
  if (!top->l2todr_req_retry) {
    top->l2todr_req_paddr = rand();
    if (inp_list_req.empty()) { // Once every 4
      top->l2todr_req_valid = 0;
      valid_count = 0;
    }else{
      top->l2todr_req_valid = 1;
      valid_count++;
    }
  }
#else
  top->drtomem_req_retry = (rand()&0x3F)==0; 

  if (!top->l2todr_req_retry) {
    top->l2todr_req_paddr = rand();
    if (inp_list_req.empty() || (rand() & 0x3)) { // Once every 4
      top->l2todr_req_valid = 0;
    }else{
      top->l2todr_req_valid = 1;
    }
  }
#endif 
  
  //ack
  top->drtol2_snack_retry = (rand()&0x3F)==0; 

  if (!top->memtodr_ack_retry) {
    top->memtodr_ack_line_7 = rand();
    top->memtodr_ack_line_6 = rand();
    top->memtodr_ack_line_5 = rand();
    top->memtodr_ack_line_4 = rand();
    top->memtodr_ack_line_3 = rand();
    top->memtodr_ack_line_2 = rand();
    top->memtodr_ack_line_1 = rand();
    top->memtodr_ack_line_0 = rand();
    
    if (inp_list_ack.empty() || (rand() & 0x3)) { // Once every 4
      top->memtodr_ack_valid = 0;
    }else{
      top->memtodr_ack_valid = 1;
    }
  }
  
  
  //pfreq
  if (top->l2todr_pfreq_valid && !top->l2todr_pfreq_retry) {
    if (inp_list_pfreq.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }


    InputPacket_l2todr_pfreq inp1 = inp_list_pfreq.back();
    top->l2todr_pfreq_paddr = inp1.addr;
#ifdef DEBUG_TRACE
    printf("@%lu pfreq addr:%lu \n",global_time, inp1.addr);
#endif
   
    OutputPacket_drtomem_pfreq out1;
    out1.addr = inp1.addr;
    out_list_pfreq.push_front(out1);
    

    inp_list_pfreq.pop_back();
  }
  
  //req
  if (top->l2todr_req_valid && !top->l2todr_req_retry) {
    if (inp_list_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }


    InputPacket_l2todr_req inp2   = inp_list_req.back();
    top->l2todr_req_paddr = inp2.addr;
#ifdef DEBUG_TRACE
    printf("@%lu req addr:%lu \n",global_time, inp2.addr);
#endif
   
    OutputPacket_drtomem_req out2;
    out2.addr = inp2.addr;
    out_list_req.push_front(out2);
    

    inp_list_req.pop_back();
  }
  
  //ack
  if (top->memtodr_ack_valid && !top->memtodr_ack_retry) {
    if (inp_list_ack.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }

#ifdef TEST_ACK
    InputPacket_memtodr_ack inp3 = inp_list_ack.back();
    top->memtodr_ack_drid = inp3.drid;
    
    top->memtodr_ack_line_7 = inp3.line_7;
    top->memtodr_ack_line_6 = inp3.line_6;
    top->memtodr_ack_line_5 = inp3.line_5;
    top->memtodr_ack_line_4 = inp3.line_4;
    top->memtodr_ack_line_3 = inp3.line_3;
    top->memtodr_ack_line_2 = inp3.line_2;
    top->memtodr_ack_line_1 = inp3.line_1;
    top->memtodr_ack_line_0 = inp3.line_0;

#ifdef DEBUG_TRACE
    printf("@%lu ack req data:%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu\n",global_time, inp3.line_7
                                                                             ,inp3.line_6
                                                                             ,inp3.line_5
                                                                             ,inp3.line_4
                                                                             ,inp3.line_3
                                                                             ,inp3.line_2
                                                                             ,inp3.line_1
                                                                             ,inp3.line_0); //change
#endif
   
    //the output expection should expect a specific nid and l2id. Not fully implemented yet.
    OutputPacket_drtol2_snack out3;    
    out3.line_7 = inp3.line_7;
    out3.line_6 = inp3.line_6;
    out3.line_5 = inp3.line_5;
    out3.line_4 = inp3.line_4;
    out3.line_3 = inp3.line_3;
    out3.line_2 = inp3.line_2;
    out3.line_1 = inp3.line_1;
    out3.line_0 = inp3.line_0;
    out_list_ack.push_front(out3);
#endif    



    inp_list_ack.pop_back();
  }
  
 

}

//above is code from other tb
void try_recv_packet_pfreq(Vdirectory_bank_wp *top) {

  //pfreq
  if (top->drtomem_pfreq_valid && out_list_pfreq.empty()) {
    printf("ERROR: unexpected pfreq ack addr:%lu\n",top->drtomem_pfreq_paddr);
    error_found(top);
    return;
  }

  if (top->drtomem_pfreq_retry)
    return;

  if (!top->drtomem_pfreq_valid)
    return;

  if (out_list_pfreq.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lu pfreq ack addr:%lu\n",global_time, top->drtomem_pfreq_paddr);
#endif
  OutputPacket_drtomem_pfreq o1 = out_list_pfreq.back();
  if (top->drtomem_pfreq_paddr != o1.addr) {
    printf("ERROR: expected addr:%lu but ack is %lu\n",o1.addr,top->drtomem_pfreq_paddr);
    error_found(top);
  }

  out_list_pfreq.pop_back();
  
}

void try_recv_packet_req(Vdirectory_bank_wp *top) {

  //req
  if (top->drtomem_req_valid && out_list_req.empty()) {
    printf("ERROR: unexpected req ack addr:%lu\n",top->drtomem_req_paddr);
    error_found(top);
    return;
  }

  if (top->drtomem_req_retry)
    return;

  if (!top->drtomem_req_valid)
    return;

  if (out_list_req.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lu req ack addr:%lu\n",global_time, top->drtomem_req_paddr);
#endif
  OutputPacket_drtomem_req o2 = out_list_req.back();
  if (top->drtomem_req_paddr != o2.addr) {
    printf("ERROR: expected addr:%lu but ack is %lu\n",o2.addr,top->drtomem_req_paddr);
    error_found(top);
  }
  
  //When we receive a request, push an ack
  InputPacket_memtodr_ack inAck;    
  inAck.line_7 = rand();
  inAck.line_6 = rand();
  inAck.line_5 = rand();
  inAck.line_4 = rand();
  inAck.line_3 = rand();
  inAck.line_2 = rand();
  inAck.line_1 = rand();
  inAck.line_0 = rand();
  inAck.drid = rand();
  inp_list_ack.push_front(inAck);
  
  out_list_req.pop_back();
}

//ack
void try_recv_packet_ack(Vdirectory_bank_wp *top) {

  if (top->drtol2_snack_valid && out_list_ack.empty()) {
    printf("ERROR: unexpected req ack data:%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu\n",top->drtol2_snack_line_7
                                                                             ,top->drtol2_snack_line_6
                                                                             ,top->drtol2_snack_line_5
                                                                             ,top->drtol2_snack_line_4
                                                                             ,top->drtol2_snack_line_3
                                                                             ,top->drtol2_snack_line_2
                                                                             ,top->drtol2_snack_line_1
                                                                             ,top->drtol2_snack_line_0); //change
    error_found(top);
    return;
  }

  if (top->drtol2_snack_retry)
    return;

  if (!top->drtol2_snack_valid)
    return;

  if (out_list_ack.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lu ack ack data:%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu\n",global_time, top->drtol2_snack_line_7
                                                                             ,top->drtol2_snack_line_6
                                                                             ,top->drtol2_snack_line_5
                                                                             ,top->drtol2_snack_line_4
                                                                             ,top->drtol2_snack_line_3
                                                                             ,top->drtol2_snack_line_2
                                                                             ,top->drtol2_snack_line_1
                                                                             ,top->drtol2_snack_line_0); //change
#endif
  OutputPacket_drtol2_snack o3 = out_list_ack.back();
  if (top->drtol2_snack_line_7 != o3.line_7) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_7,top->drtol2_snack_line_7);
    error_found(top);
  } else if (top->drtol2_snack_line_6 != o3.line_6) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_6,top->drtol2_snack_line_6);
    error_found(top);
  } else if (top->drtol2_snack_line_5 != o3.line_5) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_5,top->drtol2_snack_line_5);
    error_found(top);
  } else if (top->drtol2_snack_line_4 != o3.line_4) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_4,top->drtol2_snack_line_4);
    error_found(top);
  } else if (top->drtol2_snack_line_3 != o3.line_3) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_3,top->drtol2_snack_line_3);
    error_found(top);
  } else if (top->drtol2_snack_line_2 != o3.line_2) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_2,top->drtol2_snack_line_2);
    error_found(top);
  } else if (top->drtol2_snack_line_1 != o3.line_1) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_1,top->drtol2_snack_line_1);
    error_found(top);
  } else if (top->drtol2_snack_line_0 != o3.line_0) {
    printf("ERROR: expected data:%lu but ack is %lu\n",o3.line_0,top->drtol2_snack_line_0);
    error_found(top);
  }


  out_list_ack.pop_back();
}




int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vdirectory_bank_wp *top = new Vdirectory_bank_wp;

  int t = (int)time(0);
#ifdef TEST_REQ_FAILURE
  //srand(1477551033);
  srand(t);
#else
  srand(t);
#endif
  printf("My RAND Seed is %d\n",t);

#ifdef TRACE
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("output.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;
  top->reset = 1;

  advance_clock(top,1024);  // Long reset to give time to the state machine
  //-------------------------------------------------------
  top->reset = 0;
  top->drtomem_pfreq_retry = 1;
  top->drtomem_req_retry = 1;
  
  top->drtol2_snack_retry = 1;
  top->memtodr_ack_valid = 0;

  
  top->l2todr_req_nid = 0;
  top->l2todr_req_l2id = 0;
  top->l2todr_req_cmd = 0;
  //First test: only test a single set of signals like the l2 to dr or even prefetch
  //Associate retry signal with one I am testing.... prefetch it is.
  advance_clock(top,1);

  
  //I think I have given up converting this and it will be easier writing my own testbench.
  //I could actually use the code, but I have to alter the send packet function.

#if 1
  for(int i =0;i<10240;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    
#ifdef TEST_PFREQ
    try_recv_packet_pfreq(top);
#endif

#ifdef TEST_REQ
    try_recv_packet_req(top);
#endif

#ifdef TEST_ACK    
    try_recv_packet_ack(top);
#endif
    advance_half_clock(top);
    
#ifdef TEST_PFREQ
    if (((rand() & 0x3)==0) && inp_list_pfreq.size() < 3 ) {
      InputPacket_l2todr_pfreq i;

      if (rand() % 3)
        i.addr = rand() & 0x0001FFFFFFFFFFFF;
      else if (!inp_list_pfreq.empty())
        i.addr = inp_list_pfreq.front().addr;
      else
        i.addr = rand() & 0x00000000FFFFFFFF;

      inp_list_pfreq.push_front(i);
    }
#endif
    
#ifdef TEST_REQ  
#ifdef TEST_REQ_FAILURE
    if (inp_list_req.empty()) {
      InputPacket_l2todr_req i;
      i.addr = rand() & 0x0001FFFFFFFFFFFF;
      
      //Push multiple times, tests seems to only fails with multiple valids in a row,
      //so we set up that condition to occur by populating the list.
      inp_list_req.push_front(i);
      inp_list_req.push_front(i);
      inp_list_req.push_front(i);
    }
#else
    if (((rand() & 0x3)==0) && inp_list_req.size() < 3 ) {
      InputPacket_l2todr_req i;

      if (rand() % 3)
        i.addr = rand() & 0x0001FFFFFFFFFFFF;
      else if (!inp_list_req.empty())
        i.addr = inp_list_req.front().addr;
      else
        i.addr = rand() & 0x00000000FFFFFFFF;

      inp_list_req.push_front(i);
    }
#endif
#endif
    //Ack does not have one of these because every push from from the response to a request
    
  }
#endif

  sim_finish(true);

}

