#include "Vl2cache_pipe_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vl2cache_pipe_wp *top) {
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

void advance_clock(Vl2cache_pipe_wp *top, int nclocks=1) {

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

// Define stimulus struct
struct L1tol2ReqPacket {
    uint8_t dcid;
    uint8_t cmd;
    uint16_t pcsign;
    uint64_t laddr;
    uint64_t sptbr;
};

struct L2todrReqPacket {
    uint8_t nid;
    uint8_t l2id;
    uint8_t cmd;
    uint64_t paddr;
};
//

std::list<L1tol2ReqPacket> l1tol2_req_list;
std::list<L2todrReqPacket> l2todr_req_list;
int count_l1tol2_req = 0;
int count_l2todr_req = 0;

void error_found(Vl2cache_pipe_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_send_packet (Vl2cache_pipe_wp *top) {
    top->l2todr_req_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l1tol2_req_retry ) {
        top->l1tol2_req_dcid = rand();
        top->l1tol2_req_cmd = rand();
        top->l1tol2_req_pcsign = rand();
        top->l1tol2_req_laddr = rand();
        top->l1tol2_req_sptbr = rand();
        if (l1tol2_req_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l1tol2_req_valid = 0;
        }else{
          top->l1tol2_req_valid = 1;
        }
    }
    
    if (top->l1tol2_req_valid && !top->l1tol2_req_retry){
        if (l1tol2_req_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l1tol2_req_list\n");
        }
        L1tol2ReqPacket l1tol2_reqp = l1tol2_req_list.back();
        count_l1tol2_req++;
        top->l1tol2_req_dcid = l1tol2_reqp.dcid;
        top->l1tol2_req_cmd = l1tol2_reqp.cmd;
        top->l1tol2_req_pcsign = l1tol2_reqp.pcsign;
        top->l1tol2_req_laddr = l1tol2_reqp.laddr;
        top->l1tol2_req_sptbr = l1tol2_reqp.sptbr;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_req dcid:%x cmd:%x pcsign:%d laddr:%x sptbr:%x\n",global_time, l1tol2_reqp.dcid, 
            l1tol2_reqp.cmd, l1tol2_reqp.pcsign, l1tol2_reqp.laddr, l1tol2_reqp.sptbr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2todrReqPacket l2todr_reqp;
          l2todr_reqp.nid = rand();
          l2todr_reqp.l2id = rand();
          l2todr_reqp.cmd = l1tol2_reqp.cmd;
          l2todr_reqp.paddr = l1tol2_reqp.laddr;
          l2todr_req_list.push_front(l2todr_reqp);
        }
        l1tol2_req_list.pop_back();
    }
}

void try_receive_packet (Vl2cache_pipe_wp *top) {
    if(top->l2todr_req_valid && l2todr_req_list.empty()){
        printf("ERROR: unexpected l2todr_req nid:%x l2id:%x cmd:%x  paddr:%x\n",top->l2todr_req_nid, 
                top->l2todr_req_l2id, top->l2todr_req_cmd, top->l2todr_req_paddr);
        error_found(top);
        return;
    }

    if (top->l2todr_req_retry) {
        return;
    }

    if (!top->l2todr_req_valid) {
        return;
    }
    
    if (l2todr_req_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2todr_req nid:%x l2id:%x cmd:%x  paddr:%x\n",global_time, top->l2todr_req_nid, top->l2todr_req_l2id, 
            top->l2todr_req_cmd, top->l2todr_req_paddr);

    #endif
    L2todrReqPacket l2todr_reqp = l2todr_req_list.back();
    if (top->l2todr_req_cmd != l2todr_reqp.cmd ||
          top->l2todr_req_paddr != l2todr_reqp.paddr) {
        printf("ERROR: expected l2todr_req_cmd:%x but actual l2todr_req_cmd is %x\n", l2todr_reqp.cmd,top->l2todr_req_cmd);
        printf("ERROR: expected l2todr_req_paddr:%x but actual l2todr_req_paddr is %x\n", l2todr_reqp.paddr,top->l2todr_req_paddr);
        error_found(top);
      }
    l2todr_req_list.pop_back();
    count_l2todr_req++;
}

double sc_time_stamp() {
  return 0;
}

int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vl2cache_pipe_wp* top = new Vl2cache_pipe_wp;

  int t = (int)time(0);
  srand(t);
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
  top->l2todr_req_retry = 1;

  advance_clock(top,1);

#if 1
  for(int i =0;i<50;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_receive_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && l1tol2_req_list.size() < 3 ) {
      //L1tol2ReqPacket l1tol2_reqp = L1tol2ReqPacket();
      L1tol2ReqPacket l1tol2_reqp;
      l1tol2_reqp.dcid = rand() & 0x1F;
      l1tol2_reqp.cmd = rand() & 0x7;
      l1tol2_reqp.pcsign = rand() & 0x7FF;
      l1tol2_reqp.laddr = rand() & 0x7FFFFFFFFF;
      l1tol2_reqp.sptbr = rand() & 0x3FFFFFFFFF;
      l1tol2_req_list.push_front(l1tol2_reqp);
    }
  }
#endif
  printf("Test Statistics: l1tol2_req count: %d\n l2todr_req count: %d\n",count_l1tol2_req, count_l2todr_req);
  sim_finish(true);

}
