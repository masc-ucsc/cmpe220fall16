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
    uint8_t l1tol2_req_dcid;
    uint8_t l1tol2_req_cmd;
    uint16_t l1tol2_req_pcsign;
    uint64_t l1tol2_req_laddr;
    uint64_t l1tol2_req_sptbr;
};

struct L2todrReqPacket {
    uint8_t l2todr_req_nid;
    uint8_t l2todr_req_l2id;
    uint8_t l2todr_req_cmd;
    uint64_t    l2todr_req_paddr;
};
//

std::list<L1tol2ReqPacket> l1tol2_req_list;
std::list<L2todrReqPacket> l2todr_req_list;
/*
void try_send_packet (Vl2cache_pipe_wp *top) {
    top->l2todr_req_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l1tol2_req_retry ) {
        top->
    }
}
*/
double sc_time_stamp() {
  return 0;
}
