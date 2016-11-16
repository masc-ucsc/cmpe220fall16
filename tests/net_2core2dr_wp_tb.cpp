#include "Vnet_2core2dr_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

long ntests = 0;

void advance_half_clock(Vnet_2core2dr_wp *top) {
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

void advance_clock(Vnet_2core2dr_wp *top, int nclocks=1) {

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
/*
Inputs for l2todr
c0_l2itodr_req
c0_l2ittodr_req
c0_l2d_0todr_req
c0_l2dt_0todr_req
c1_l2itodr_req
c1_l2ittodr_req
c1_l2d_0todr_req
c1_l2dt_0todr_req

c0_l2itodr_disp
c0_l2ittodr_disp
c0_l2d_0todr_disp
c0_l2dt_0todr_disp
c1_l2itodr_disp
c1_l2ittodr_disp
c1_l2d_0todr_disp
c1_l2dt_0todr_disp

c0_l2itodr_snoop_ack
c0_l2ittodr_snoop_ack
c0_l2d_0todr_snoop_ack
c0_l2dt_0todr_snoop_ack
c1_l2itodr_snoop_ack
c1_l2ittodr_snoop_ack
c1_l2d_0todr_snoop_ack
c1_l2dt_0todr_snoop_ack

c0_l2itodr_pfreq
c0_l2d_0todr_pfreq
c1_l2itodr_pfreq
c1_l2d_0todr_pfreq

Inputs for drtol2
dr0tol2_snack
dr0tol2_dack
dr1tol2_snack
dr1tol2_dack
*/

struct InputPacket_c0_l2itodr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c0_l2ittodr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c0_l2d_0todr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c0_l2dt_0todr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c1_l2itodr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c1_l2ittodr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c1_l2d_0todr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct InputPacket_c1_l2dt_0todr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct OutputPacket_l2todr0_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

struct OutputPacket_l2todr1_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t paddr;
};

double sc_time_stamp() {
  return 0;
}

std::list<InputPacket_c0_l2itodr_req>  inp_list_c0_l2i_req;
std::list<InputPacket_c0_l2ittodr_req>  inp_list_c0_l2it_req;
std::list<InputPacket_c0_l2d_0todr_req>  inp_list_c0_l2d_req;
std::list<InputPacket_c0_l2dt_0todr_req>  inp_list_c0_l2dt_req;
std::list<InputPacket_c1_l2itodr_req>  inp_list_c1_l2i_req;
std::list<InputPacket_c1_l2ittodr_req>  inp_list_c1_l2it_req;
std::list<InputPacket_c1_l2d_0todr_req>  inp_list_c1_l2d_req;
std::list<InputPacket_c1_l2dt_0todr_req>  inp_list_c1_l2dt_req;
std::list<OutputPacket_l2todr0_req>  out_list_d0_req;
std::list<OutputPacket_l2todr1_req>  out_list_d1_req;


void try_send_packet(Vnet_2core2dr_wp *top) {
  #if 0 // This code should be completed after manual tests
  // req
  top->l2todr0_req_retry = (rand()&0x3F)==0; 
  top->l2todr1_req_retry = (rand()&0x3F)==0; 

  if (!top->c0_l2itodr_req_retry) {
    top->c0_l2itodr_req_paddr = rand();
    if (inp_list_c0_l2i_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2itodr_req_valid = 0;
    }else{
      top->c0_l2itodr_req_valid = 1;
    }
  }
  if (!top->c0_l2ittodr_req_retry) {
    top->c0_l2ittodr_req_paddr = rand();
    if (inp_list_c0_l2it_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2ittodr_req_valid = 0;
    }else{
      top->c0_l2ittodr_req_valid = 1;
    }
  }
  if (!top->c0_l2d_0todr_req_retry) {
    top->c0_l2d_0todr_req_paddr = rand();
    if (inp_list_c0_l2d_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2d_0todr_req_valid = 0;
    }else{
      top->c0_l2d_0todr_req_valid = 1;
    }
  }
  if (!top->c0_l2dt_0todr_req_retry) {
    top->c0_l2dt_0todr_req_paddr = rand();
    if (inp_list_c0_l2dt_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2dt_0todr_req_valid = 0;
    }else{
      top->c0_l2dt_0todr_req_valid = 1;
    }
  }
  if (!top->c1_l2itodr_req_retry) {
    top->c1_l2itodr_req_paddr = rand();
    if (inp_list_c1_l2i_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2itodr_req_valid = 0;
    }else{
      top->c1_l2itodr_req_valid = 1;
    }
  }
  if (!top->c1_l2ittodr_req_retry) {
    top->c1_l2ittodr_req_paddr = rand();
    if (inp_list_c1_l2it_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2ittodr_req_valid = 0;
    }else{
      top->c1_l2ittodr_req_valid = 1;
    }
  }
  if (!top->c1_l2d_0todr_req_retry) {
    top->c1_l2d_0todr_req_paddr = rand();
    if (inp_list_c1_l2d_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2d_0todr_req_valid = 0;
    }else{
      top->c1_l2d_0todr_req_valid = 1;
    }
  }
  if (!top->c1_l2dt_0todr_req_retry) {
    top->c1_l2dt_0todr_req_paddr = rand();
    if (inp_list_c1_l2dt_req.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2dt_0todr_req_valid = 0;
    }else{
      top->c1_l2dt_0todr_req_valid = 1;
    }
  }

  //req
  if (top->c0_l2itodr_req_valid && !top->c0_l2itodr_req_retry) {
    if (inp_list_c0_l2i_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }


    InputPacket_c0_l2itodr_req inp = inp_list_req.back();
    top->l2todr_req_paddr = inp.paddr;
    top->l2todr_req_nid = inp.nid;
    top->l2todr_req_l2id = inp.l2id;
#ifdef DEBUG_TRACE
    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
#endif
   
    OutputPacket_l2todr0_req out1;
    out1.paddr = inp2.paddr;
    out_list_req.push_front(out2);
    

    inp_list_req.pop_back();
  }
#endif
}

void error_found(Vnet_2core2dr_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Vnet_2core2dr_wp *top) {
  ;
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vnet_2core2dr_wp* top = new Vnet_2core2dr_wp;

  int t = (int)time(0);
#if 0
  srand(1477809920);
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

  for(int niters=0 ; niters < 50; niters++) {
    //-------------------------------------------------------

#ifdef DEBUG_TRACE
    printf("reset\n");
#endif
    top->reset = 1;

    inp_list_c0_l2i_req.clear();
    inp_list_c0_l2it_req.clear();
    inp_list_c0_l2d_req.clear();
    inp_list_c0_l2dt_req.clear();
    inp_list_c1_l2i_req.clear();
    inp_list_c1_l2it_req.clear();
    inp_list_c1_l2d_req.clear();
    inp_list_c1_l2dt_req.clear();
    out_list_d0_req.clear();
    out_list_d1_req.clear();

    top->c0_l2itodr_req_valid = 1;
    top->c0_l2ittodr_req_valid = 1;
    top->c0_l2d_0todr_req_valid = 1;
    top->c0_l2dt_0todr_req_valid = 1;
    top->c1_l2itodr_req_valid = 1;
    top->c1_l2ittodr_req_valid = 1;
    top->c1_l2d_0todr_req_valid = 1;
    top->c1_l2dt_0todr_req_valid = 1;

    int ncycles= rand() & 0xFF;
    ncycles++; // At least one cycle reset
    for(int i =0;i<ncycles;i++) {
      advance_clock(top,1);
    }

#ifdef DEBUG_TRACE
    printf("no reset\n");
#endif
    //-------------------------------------------------------
    top->reset = 0;
    top->c0_l2itodr_req_nid = rand() & 0x1F;
    top->c0_l2itodr_req_l2id = rand() & 0x3;
    top->c0_l2itodr_req_cmd = 0;
    top->c0_l2itodr_req_paddr = 0;
    top->l2todr1_req_retry = 1;
    top->l2todr0_req_retry = 1;
    advance_clock(top,1);
    top->c0_l2itodr_req_nid = rand() & 0x1F;
    top->c0_l2itodr_req_l2id = rand() & 0x3;
    top->c0_l2itodr_req_cmd = 0;
    top->c0_l2itodr_req_paddr = 1;
    top->l2todr1_req_retry = 1;
    top->l2todr0_req_retry = 1;
    advance_clock(top,1);

#if 0
    for(int i =0;i<1024;i++) {
      //try_send_packet(top);
      advance_half_clock(top);
     // try_recv_packet(top);
      advance_half_clock(top);
      
      /*
      if (((rand() & 0x3)==0) && inpa_list.size() < 3 && inpb_list.size() < 3 ) {
        InputPacketA ia;
        InputPacketB ib;
        ia.inp_a = rand() & 0xFF;
        ib.inp_b = rand() & 0xFF;
        inpa_list.push_front(ia);
        inpb_list.push_front(ib);

        OutputPacket o;
        o.sum = (ia.inp_a + ib.inp_b) & 0xFF;
        o.inp_a = ia.inp_a;
        o.inp_b = ib.inp_b;

        out_list.push_front(o);
      }
      */
      //advance_clock(top,1);
    }
#endif
  }

  printf("performed %lld test in %lld cycles\n",ntests,(long long)global_time/2);

  sim_finish(true);
}

