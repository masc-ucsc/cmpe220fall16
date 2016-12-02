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

// reqs
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

// disps
struct InputPacket_c0_l2itodr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c0_l2ittodr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c0_l2d_0todr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c0_l2dt_0todr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c1_l2itodr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c1_l2ittodr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c1_l2d_0todr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct InputPacket_c1_l2dt_0todr_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct OutputPacket_l2todr0_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

struct OutputPacket_l2todr1_disp {
  uint8_t nid;
  uint8_t drid;
  uint8_t l2id;
  uint8_t dcmd;
  uint64_t mask;
  uint64_t line;
  uint64_t paddr;
};

// pfreqs 

struct InputPacket_c0_l2itodr_pfreq {
  uint8_t nid;
  uint64_t paddr;
};

struct InputPacket_c0_l2d_0todr_pfreq {
  uint8_t nid;
  uint64_t paddr;
};

struct InputPacket_c1_l2itodr_pfreq {
  uint8_t nid;
  uint64_t paddr;
};

struct InputPacket_c1_l2d_0todr_pfreq {
  uint8_t nid;
  uint64_t paddr;
};

struct OutputPacket_l2todr0_pfreq {
  uint8_t nid;
  uint64_t paddr;
};

struct OutputPacket_l2todr1_pfreq {
  uint8_t nid;
  uint64_t paddr;
};

double sc_time_stamp() {
  return 0;
}

void error_found(Vnet_2core2dr_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

std::list<InputPacket_c0_l2itodr_req>  inp_list_c0_l2i_req;
std::list<InputPacket_c0_l2ittodr_req>  inp_list_c0_l2it_req;
std::list<InputPacket_c0_l2d_0todr_req>  inp_list_c0_l2d_req;
std::list<InputPacket_c0_l2dt_0todr_req>  inp_list_c0_l2dt_req;
std::list<InputPacket_c1_l2itodr_req>  inp_list_c1_l2i_req;
std::list<InputPacket_c1_l2ittodr_req>  inp_list_c1_l2it_req;
std::list<InputPacket_c1_l2d_0todr_req>  inp_list_c1_l2d_req;
std::list<InputPacket_c1_l2dt_0todr_req>  inp_list_c1_l2dt_req;
std::list<OutputPacket_l2todr0_req>  out_list_d0_req[8]; // One index per source(each L2 cache and TLB)
std::list<OutputPacket_l2todr1_req>  out_list_d1_req[8];

void try_send_packet_req(Vnet_2core2dr_wp *top)
{
  // req

  top->l2todr0_req_retry =0; // randomizing the retries not working for some reason...
  top->l2todr1_req_retry =0; 

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
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
      error_found(top);
    }


    InputPacket_c0_l2itodr_req inp = inp_list_c0_l2i_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[0].push_front(out); 
	    inp_list_c0_l2i_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[0].push_front(out); 
	    inp_list_c0_l2i_req.pop_back();
    }
  } else if (top->c0_l2ittodr_req_valid && !top->c0_l2ittodr_req_retry) {
  	if (inp_list_c0_l2it_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
      error_found(top);
    }


    InputPacket_c0_l2ittodr_req inp = inp_list_c0_l2it_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[1].push_front(out); 
	    inp_list_c0_l2it_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[1].push_front(out); 
	    inp_list_c0_l2it_req.pop_back();
    }
  } else if(top->c0_l2d_0todr_req_valid && !top->c0_l2d_0todr_req_retry) {
  	if (inp_list_c0_l2d_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
      error_found(top);
    }


    InputPacket_c0_l2d_0todr_req inp = inp_list_c0_l2d_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[2].push_front(out); 
	    inp_list_c0_l2d_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[2].push_front(out); 
	    inp_list_c0_l2d_req.pop_back();
    }
  } else if(top->c0_l2dt_0todr_req_valid && !top->c0_l2dt_0todr_req_retry) {
		if (inp_list_c0_l2dt_req.empty()) {
		  fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
		  error_found(top);
		}


    InputPacket_c0_l2dt_0todr_req inp = inp_list_c0_l2dt_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[3].push_front(out); 
	    inp_list_c0_l2dt_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[3].push_front(out); 
	    inp_list_c0_l2dt_req.pop_back();
		}
  } else if (top->c1_l2itodr_req_valid && !top->c1_l2itodr_req_retry) {
    if (inp_list_c1_l2i_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
      error_found(top);
    }


    InputPacket_c1_l2itodr_req inp = inp_list_c1_l2i_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[4].push_front(out); 
	    inp_list_c1_l2i_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[4].push_front(out); 
	    inp_list_c1_l2i_req.pop_back();
    }
  } else if (top->c1_l2ittodr_req_valid && !top->c1_l2ittodr_req_retry) {
  	if (inp_list_c1_l2it_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
      error_found(top);
    }


    InputPacket_c1_l2ittodr_req inp = inp_list_c1_l2it_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[5].push_front(out); 
	    inp_list_c1_l2it_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[5].push_front(out); 
	    inp_list_c1_l2it_req.pop_back();
    }
  } else if(top->c1_l2d_0todr_req_valid && !top->c1_l2d_0todr_req_retry) {
  	if (inp_list_c1_l2d_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
      error_found(top);
    }


    InputPacket_c1_l2d_0todr_req inp = inp_list_c1_l2d_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[6].push_front(out); 
	    inp_list_c1_l2d_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[6].push_front(out); 
	    inp_list_c1_l2d_req.pop_back();
    }
  } else if(top->c1_l2dt_0todr_req_valid && !top->c1_l2dt_0todr_req_retry) {
		if (inp_list_c1_l2dt_req.empty()) {
		  fprintf(stderr,"ERROR: Internal error, could not be empty l2i reqs\n");
		  error_found(top);
		}


    InputPacket_c1_l2dt_0todr_req inp = inp_list_c1_l2dt_req.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_req_paddr = inp.paddr;
	    top->l2todr1_req_nid = inp.nid;
	    top->l2todr1_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_req[7].push_front(out); 
	    inp_list_c1_l2dt_req.pop_back();
    }
    else
    {
    	top->l2todr0_req_paddr = inp.paddr;
	    top->l2todr0_req_nid = inp.nid;
	    top->l2todr0_req_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr req paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_req out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_req[7].push_front(out); 
	    inp_list_c1_l2dt_req.pop_back();
		}
  }
}

void try_recv_packet_req(Vnet_2core2dr_wp *top) {
	if (top->l2todr0_req_retry && out_list_d0_req[0].empty() && out_list_d0_req[1].empty() && out_list_d0_req[2].empty() && out_list_d0_req[3].empty()
		&& out_list_d0_req[4].empty() && out_list_d0_req[5].empty() && out_list_d0_req[6].empty() && out_list_d0_req[7].empty()) {
	    printf("ERROR: unexpected result %d, retry: %d \n",top->l2todr0_req_paddr,top->l2todr0_req_retry); // I am just choosing paddr because it should be pretty unique
	    error_found(top);
	    return;
	}

	if (top->l2todr1_req_retry && out_list_d1_req[0].empty() && out_list_d1_req[1].empty() && out_list_d1_req[2].empty() && out_list_d1_req[3].empty()
		&& out_list_d1_req[4].empty() && out_list_d1_req[5].empty() && out_list_d1_req[6].empty() && out_list_d1_req[7].empty()) {
	    printf("ERROR: unexpected result %d, retry: %d \n",top->l2todr1_req_paddr,top->l2todr1_req_retry); // I am just choosing paddr because it should be pretty unique
	    error_found(top);
	    return;
	}

	for(int i=0;i<8;i++)
	{
		//dir 0 reqs
	  if (top->l2todr0_req_retry)
	    return;

	  if (!top->l2todr0_req_valid)
	    return;

	  if (out_list_d0_req[i].empty())
	    return;

	#ifdef DEBUG_TRACE
	    printf("@%lld sum=%d\n",global_time, top->l2todr0_req_paddr);
	#endif
	  OutputPacket_l2todr0_req o1 = out_list_d0_req[i].back();
	  if (top->l2todr0_req_paddr != o1.paddr) {
	    printf("ERROR: expected %d but paddr is %d\n",o1.paddr,top->l2todr0_req_paddr);
	    error_found(top);
	  }

	  out_list_d0_req[i].pop_back();

	  // dir 1 reqs
	  if (top->l2todr1_req_retry)
	    return;

	  if (!top->l2todr1_req_valid)
	    return;

	  if (out_list_d1_req[i].empty())
	    return;

	#ifdef DEBUG_TRACE
	    printf("@%lld sum=%d\n",global_time, top->l2todr1_req_paddr);
	#endif
	  OutputPacket_l2todr1_req o2 = out_list_d1_req[i].back();
	  if (top->l2todr1_req_paddr != o2.paddr) {
	    printf("ERROR: expected %d but paddr is %d\n",o2.paddr,top->l2todr1_req_paddr);
	    error_found(top);
	  }

	  out_list_d1_req[i].pop_back();
	  ntests++;
	}
}
 
 // DISPS 
std::list<InputPacket_c0_l2itodr_disp>  inp_list_c0_l2i_disp;
std::list<InputPacket_c0_l2ittodr_disp>  inp_list_c0_l2it_disp;
std::list<InputPacket_c0_l2d_0todr_disp>  inp_list_c0_l2d_disp;
std::list<InputPacket_c0_l2dt_0todr_disp>  inp_list_c0_l2dt_disp;
std::list<InputPacket_c1_l2itodr_disp>  inp_list_c1_l2i_disp;
std::list<InputPacket_c1_l2ittodr_disp>  inp_list_c1_l2it_disp;
std::list<InputPacket_c1_l2d_0todr_disp>  inp_list_c1_l2d_disp;
std::list<InputPacket_c1_l2dt_0todr_disp>  inp_list_c1_l2dt_disp;
std::list<OutputPacket_l2todr0_disp>  out_list_d0_disp[8]; // One index per source(each L2 cache and TLB)
std::list<OutputPacket_l2todr1_disp>  out_list_d1_disp[8];

void try_send_packet_disp(Vnet_2core2dr_wp *top)
{
  // disp

  top->l2todr0_disp_retry =0; // randomizing the retries not working for some reason...
  top->l2todr1_disp_retry =0; 

  if (!top->c0_l2itodr_disp_retry) {
    top->c0_l2itodr_disp_paddr = rand();
    if (inp_list_c0_l2i_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2itodr_disp_valid = 0;
    }else{
      top->c0_l2itodr_disp_valid = 1;
    }
  }
  if (!top->c0_l2ittodr_disp_retry) {
    top->c0_l2ittodr_disp_paddr = rand();
    if (inp_list_c0_l2it_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2ittodr_disp_valid = 0;
    }else{
      top->c0_l2ittodr_disp_valid = 1;
    }
  }
  if (!top->c0_l2d_0todr_disp_retry) {
    top->c0_l2d_0todr_disp_paddr = rand();
    if (inp_list_c0_l2d_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2d_0todr_disp_valid = 0;
    }else{
      top->c0_l2d_0todr_disp_valid = 1;
    }
  }
  if (!top->c0_l2dt_0todr_disp_retry) {
    top->c0_l2dt_0todr_disp_paddr = rand();
    if (inp_list_c0_l2dt_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2dt_0todr_disp_valid = 0;
    }else{
      top->c0_l2dt_0todr_disp_valid = 1;
    }
  }
  if (!top->c1_l2itodr_disp_retry) {
    top->c1_l2itodr_disp_paddr = rand();
    if (inp_list_c1_l2i_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2itodr_disp_valid = 0;
    }else{
      top->c1_l2itodr_disp_valid = 1;
    }
  }
  if (!top->c1_l2ittodr_disp_retry) {
    top->c1_l2ittodr_disp_paddr = rand();
    if (inp_list_c1_l2it_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2ittodr_disp_valid = 0;
    }else{
      top->c1_l2ittodr_disp_valid = 1;
    }
  }
  if (!top->c1_l2d_0todr_disp_retry) {
    top->c1_l2d_0todr_disp_paddr = rand();
    if (inp_list_c1_l2d_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2d_0todr_disp_valid = 0;
    }else{
      top->c1_l2d_0todr_disp_valid = 1;
    }
  }
  if (!top->c1_l2dt_0todr_disp_retry) {
    top->c1_l2dt_0todr_disp_paddr = rand();
    if (inp_list_c1_l2dt_disp.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2dt_0todr_disp_valid = 0;
    }else{
      top->c1_l2dt_0todr_disp_valid = 1;
    }
  }

  //disp
  if (top->c0_l2itodr_disp_valid && !top->c0_l2itodr_disp_retry) {
    if (inp_list_c0_l2i_disp.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
      error_found(top);
    }


    InputPacket_c0_l2itodr_disp inp = inp_list_c0_l2i_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[0].push_front(out); 
	    inp_list_c0_l2i_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[0].push_front(out); 
	    inp_list_c0_l2i_disp.pop_back();
    }
  } else if (top->c0_l2ittodr_disp_valid && !top->c0_l2ittodr_disp_retry) {
  	if (inp_list_c0_l2it_disp.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
      error_found(top);
    }


    InputPacket_c0_l2ittodr_disp inp = inp_list_c0_l2it_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[1].push_front(out); 
	    inp_list_c0_l2it_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[1].push_front(out); 
	    inp_list_c0_l2it_disp.pop_back();
    }
  } else if(top->c0_l2d_0todr_disp_valid && !top->c0_l2d_0todr_disp_retry) {
  	if (inp_list_c0_l2d_disp.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
      error_found(top);
    }


    InputPacket_c0_l2d_0todr_disp inp = inp_list_c0_l2d_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[2].push_front(out); 
	    inp_list_c0_l2d_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[2].push_front(out); 
	    inp_list_c0_l2d_disp.pop_back();
    }
  } else if(top->c0_l2dt_0todr_disp_valid && !top->c0_l2dt_0todr_disp_retry) {
		if (inp_list_c0_l2dt_disp.empty()) {
		  fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
		  error_found(top);
		}


    InputPacket_c0_l2dt_0todr_disp inp = inp_list_c0_l2dt_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[3].push_front(out); 
	    inp_list_c0_l2dt_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[3].push_front(out); 
	    inp_list_c0_l2dt_disp.pop_back();
		}
  } else if (top->c1_l2itodr_disp_valid && !top->c1_l2itodr_disp_retry) {
    if (inp_list_c1_l2i_disp.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
      error_found(top);
    }


    InputPacket_c1_l2itodr_disp inp = inp_list_c1_l2i_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[4].push_front(out); 
	    inp_list_c1_l2i_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[4].push_front(out); 
	    inp_list_c1_l2i_disp.pop_back();
    }
  } else if (top->c1_l2ittodr_disp_valid && !top->c1_l2ittodr_disp_retry) {
  	if (inp_list_c1_l2it_disp.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
      error_found(top);
    }


    InputPacket_c1_l2ittodr_disp inp = inp_list_c1_l2it_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[5].push_front(out); 
	    inp_list_c1_l2it_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[5].push_front(out); 
	    inp_list_c1_l2it_disp.pop_back();
    }
  } else if(top->c1_l2d_0todr_disp_valid && !top->c1_l2d_0todr_disp_retry) {
  	if (inp_list_c1_l2d_disp.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
      error_found(top);
    }


    InputPacket_c1_l2d_0todr_disp inp = inp_list_c1_l2d_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[6].push_front(out); 
	    inp_list_c1_l2d_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[6].push_front(out); 
	    inp_list_c1_l2d_disp.pop_back();
    }
  } else if(top->c1_l2dt_0todr_disp_valid && !top->c1_l2dt_0todr_disp_retry) {
		if (inp_list_c1_l2dt_disp.empty()) {
		  fprintf(stderr,"ERROR: Internal error, could not be empty l2i disps\n");
		  error_found(top);
		}


    InputPacket_c1_l2dt_0todr_disp inp = inp_list_c1_l2dt_disp.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_disp_paddr = inp.paddr;
	    top->l2todr1_disp_nid = inp.nid;
	    top->l2todr1_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr1_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_disp[7].push_front(out); 
	    inp_list_c1_l2dt_disp.pop_back();
    }
    else
    {
    	top->l2todr0_disp_paddr = inp.paddr;
	    top->l2todr0_disp_nid = inp.nid;
	    top->l2todr0_disp_l2id = inp.l2id;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr disp paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid, inp.l2id);
	#endif
	   
	    OutputPacket_l2todr0_disp out;
	    out.l2id = inp.l2id;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_disp[7].push_front(out); 
	    inp_list_c1_l2dt_disp.pop_back();
		}
  }
}

void try_recv_packet_disp(Vnet_2core2dr_wp *top) {
	if (top->l2todr0_disp_retry && out_list_d0_disp[0].empty() && out_list_d0_disp[1].empty() && out_list_d0_disp[2].empty() && out_list_d0_disp[3].empty()
		&& out_list_d0_disp[4].empty() && out_list_d0_disp[5].empty() && out_list_d0_disp[6].empty() && out_list_d0_disp[7].empty()) {
	    printf("ERROR: unexpected result %d, retry: %d \n",top->l2todr0_disp_paddr,top->l2todr0_disp_retry); // I am just choosing paddr because it should be pretty unique
	    error_found(top);
	    return;
	}

	if (top->l2todr1_disp_retry && out_list_d1_disp[0].empty() && out_list_d1_disp[1].empty() && out_list_d1_disp[2].empty() && out_list_d1_disp[3].empty()
		&& out_list_d1_disp[4].empty() && out_list_d1_disp[5].empty() && out_list_d1_disp[6].empty() && out_list_d1_disp[7].empty()) {
	    printf("ERROR: unexpected result %d, retry: %d \n",top->l2todr1_disp_paddr,top->l2todr1_disp_retry); // I am just choosing paddr because it should be pretty unique
	    error_found(top);
	    return;
	}

	for(int i=0;i<8;i++)
	{
		//dir 0 disps
	  if (top->l2todr0_disp_retry)
	    return;

	  if (!top->l2todr0_disp_valid)
	    return;

	  if (out_list_d0_disp[i].empty())
	    return;

	#ifdef DEBUG_TRACE
	    printf("@%lld sum=%d\n",global_time, top->l2todr0_disp_paddr);
	#endif
	  OutputPacket_l2todr0_disp o1 = out_list_d0_disp[i].back();
	  if (top->l2todr0_disp_paddr != o1.paddr) {
	    printf("ERROR: expected %d but paddr is %d\n",o1.paddr,top->l2todr0_disp_paddr);
	    error_found(top);
	  }

	  out_list_d0_disp[i].pop_back();

	  // dir 1 disps
	  if (top->l2todr1_disp_retry)
	    return;

	  if (!top->l2todr1_disp_valid)
	    return;

	  if (out_list_d1_disp[i].empty())
	    return;

	#ifdef DEBUG_TRACE
	    printf("@%lld sum=%d\n",global_time, top->l2todr1_disp_paddr);
	#endif
	  OutputPacket_l2todr1_disp o2 = out_list_d1_disp[i].back();
	  if (top->l2todr1_disp_paddr != o2.paddr) {
	    printf("ERROR: expected %d but paddr is %d\n",o2.paddr,top->l2todr1_disp_paddr);
	    error_found(top);
	  }

	  out_list_d1_disp[i].pop_back();
	  ntests++;
	}
}

std::list<InputPacket_c0_l2itodr_pfreq>  inp_list_c0_l2i_pfreq;
std::list<InputPacket_c0_l2d_0todr_pfreq>  inp_list_c0_l2d_pfreq;
std::list<InputPacket_c1_l2itodr_pfreq>  inp_list_c1_l2i_pfreq;
std::list<InputPacket_c1_l2d_0todr_pfreq>  inp_list_c1_l2d_pfreq;
std::list<OutputPacket_l2todr0_pfreq>  out_list_d0_pfreq[4]; // One index per source(each L2 cache and TLB)
std::list<OutputPacket_l2todr1_pfreq>  out_list_d1_pfreq[4];

void try_send_packet_pfreq(Vnet_2core2dr_wp *top)
{
  // pfreq

  top->l2todr0_pfreq_retry =0; // randomizing the retries not working for some reason...
  top->l2todr1_pfreq_retry =0; 

  if (!top->c0_l2itodr_pfreq_retry) {
    top->c0_l2itodr_pfreq_paddr = rand();
    if (inp_list_c0_l2i_pfreq.empty() || (rand() & 0x3)) { // Once every 4
      top->c0_l2itodr_pfreq_valid = 0;
    }else{
      top->c0_l2itodr_pfreq_valid = 1;
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
  if (!top->c1_l2itodr_pfreq_retry) {
    top->c1_l2itodr_pfreq_paddr = rand();
    if (inp_list_c1_l2i_pfreq.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2itodr_pfreq_valid = 0;
    }else{
      top->c1_l2itodr_pfreq_valid = 1;
    }
  }
  if (!top->c1_l2d_0todr_pfreq_retry) {
    top->c1_l2d_0todr_pfreq_paddr = rand();
    if (inp_list_c1_l2d_pfreq.empty() || (rand() & 0x3)) { // Once every 4
      top->c1_l2d_0todr_pfreq_valid = 0;
    }else{
      top->c1_l2d_0todr_pfreq_valid = 1;
    }
  }

  //pfreq
  if (top->c0_l2itodr_pfreq_valid && !top->c0_l2itodr_pfreq_retry) {
    if (inp_list_c0_l2i_pfreq.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty c0l2i pfreqs\n");
      error_found(top);
    }


    InputPacket_c0_l2itodr_pfreq inp = inp_list_c0_l2i_pfreq.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_pfreq_paddr = inp.paddr;
	    top->l2todr1_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr1_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_pfreq[0].push_front(out); 
	    inp_list_c0_l2i_pfreq.pop_back();
    }
    else
    {
    	top->l2todr0_pfreq_paddr = inp.paddr;
	    top->l2todr0_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u, l2id: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr0_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_pfreq[0].push_front(out); 
	    inp_list_c0_l2i_pfreq.pop_back();
    }
  /*} else if(top->c0_l2d_0todr_pfreq_valid && !top->c0_l2d_0todr_pfreq_retry) {
  	if (inp_list_c0_l2d_pfreq.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty c0l2d pfreqs\n");
      error_found(top);
    }


    InputPacket_c0_l2d_0todr_pfreq inp = inp_list_c0_l2d_pfreq.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_pfreq_paddr = inp.paddr;
	    top->l2todr1_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr1_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_pfreq[1].push_front(out); 
	    inp_list_c0_l2d_pfreq.pop_back();
    }
    else
    {
    	top->l2todr0_pfreq_paddr = inp.paddr;
	    top->l2todr0_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr0_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_pfreq[1].push_front(out); 
	    inp_list_c0_l2d_pfreq.pop_back();
    }*/
  } else if (top->c1_l2itodr_pfreq_valid && !top->c1_l2itodr_pfreq_retry) {
    if (inp_list_c1_l2i_pfreq.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty c1l2i pfreqs\n");
      error_found(top);
    }


    InputPacket_c1_l2itodr_pfreq inp = inp_list_c1_l2i_pfreq.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_pfreq_paddr = inp.paddr;
	    top->l2todr1_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr1_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_pfreq[2].push_front(out); 
	    inp_list_c1_l2i_pfreq.pop_back();
    }
    else
    {
    	top->l2todr0_pfreq_paddr = inp.paddr;
	    top->l2todr0_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr0_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_pfreq[2].push_front(out); 
	    inp_list_c1_l2i_pfreq.pop_back();
    }
  } else if(top->c1_l2d_0todr_pfreq_valid && !top->c1_l2d_0todr_pfreq_retry) {
  	if (inp_list_c1_l2d_pfreq.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty c1l2d pfreqs\n");
      error_found(top);
    }


    InputPacket_c1_l2d_0todr_pfreq inp = inp_list_c1_l2d_pfreq.back();
    if (inp.paddr & 0x100) // If bit 9 is high then is to directory 1, else to directory 0
    {
    	top->l2todr1_pfreq_paddr = inp.paddr;
	    top->l2todr1_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr1_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d1_pfreq[3].push_front(out); 
	    inp_list_c1_l2d_pfreq.pop_back();
    }
    else
    {
    	top->l2todr0_pfreq_paddr = inp.paddr;
	    top->l2todr0_pfreq_nid = inp.nid;
	#ifdef DEBUG_TRACE
	    printf("@%lu l2itodr pfreq paddr:%lu, nid: %u\n",global_time, inp.paddr, inp.nid);
	#endif
	   
	    OutputPacket_l2todr0_pfreq out;
	    out.nid = inp.nid;
	    out.paddr = inp.paddr;
	    out_list_d0_pfreq[3].push_front(out); 
	    inp_list_c1_l2d_pfreq.pop_back();
    }
  }
}

void try_recv_packet_pfreq(Vnet_2core2dr_wp *top) {
	if (top->l2todr0_pfreq_retry && out_list_d0_pfreq[0].empty() && out_list_d0_pfreq[1].empty() && out_list_d0_pfreq[2].empty() && out_list_d0_pfreq[3].empty()) {
	    printf("ERROR: unexpected result %d, retry: %d \n",top->l2todr0_pfreq_paddr,top->l2todr0_pfreq_retry); // I am just choosing paddr because it should be pretty unique
	    error_found(top);
	    return;
	}

	if (top->l2todr1_pfreq_retry && out_list_d1_pfreq[0].empty() && out_list_d1_pfreq[1].empty() && out_list_d1_pfreq[2].empty() && out_list_d1_pfreq[3].empty()) {
	    printf("ERROR: unexpected result %d, retry: %d \n",top->l2todr1_pfreq_paddr,top->l2todr1_pfreq_retry);
	    error_found(top);
	    return;
	}

	for(int i=0;i<4;i++)
	{
		//dir 0 pfreqs
	  if (top->l2todr0_pfreq_retry)
	    return;

	  if (!top->l2todr0_pfreq_valid)
	    return;

	  if (out_list_d0_pfreq[i].empty())
	    return;

	#ifdef DEBUG_TRACE
	    printf("@%lld sum=%d\n",global_time, top->l2todr0_pfreq_paddr);
	#endif
	  OutputPacket_l2todr0_pfreq o1 = out_list_d0_pfreq[i].back();
	  if (top->l2todr0_pfreq_paddr != o1.paddr) {
	    printf("ERROR: expected %d but paddr is %d\n",o1.paddr,top->l2todr0_pfreq_paddr);
	    error_found(top);
	  }

	  out_list_d0_pfreq[i].pop_back();

	  // dir 1 pfreqs
	  if (top->l2todr1_pfreq_retry)
	    return;

	  if (!top->l2todr1_pfreq_valid)
	    return;

	  if (out_list_d1_pfreq[i].empty())
	    return;

	#ifdef DEBUG_TRACE
	    printf("@%lld sum=%d\n",global_time, top->l2todr1_pfreq_paddr);
	#endif
	  OutputPacket_l2todr1_pfreq o2 = out_list_d1_pfreq[i].back();
	  if (top->l2todr1_pfreq_paddr != o2.paddr) {
	    printf("ERROR: expected %d but paddr is %d\n",o2.paddr,top->l2todr1_pfreq_paddr);
	    error_found(top);
	  }

	  out_list_d1_pfreq[i].pop_back();
	  ntests++;
	}
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

  for(int niters=0 ; niters < 50; niters++) 
  {
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
    for(int i=0;i<7;i++)
    {
	    out_list_d0_req[i].clear();
	    out_list_d1_req[i].clear();
    }

    inp_list_c0_l2i_disp.clear();
    inp_list_c0_l2it_disp.clear();
    inp_list_c0_l2d_disp.clear();
    inp_list_c0_l2dt_disp.clear();
    inp_list_c1_l2i_disp.clear();
    inp_list_c1_l2it_disp.clear();
    inp_list_c1_l2d_disp.clear();
    inp_list_c1_l2dt_disp.clear();
    for(int i=0;i<7;i++)
    {
	    out_list_d0_disp[i].clear();
	    out_list_d1_disp[i].clear();
    }

    inp_list_c0_l2i_pfreq.clear();
    inp_list_c0_l2d_pfreq.clear();
    inp_list_c1_l2i_pfreq.clear();
    inp_list_c1_l2d_pfreq.clear();
    for(int i=0;i<4;i++)
    {
	    out_list_d0_pfreq[i].clear();
	    out_list_d1_pfreq[i].clear();
    }

    top->c0_l2itodr_req_valid = 1;
    top->c0_l2ittodr_req_valid = 1;
    top->c0_l2d_0todr_req_valid = 1;
    top->c0_l2dt_0todr_req_valid = 1;
    top->c1_l2itodr_req_valid = 1;
    top->c1_l2ittodr_req_valid = 1;
    top->c1_l2d_0todr_req_valid = 1;
    top->c1_l2dt_0todr_req_valid = 1;

    top->c0_l2itodr_disp_valid = 1;
    top->c0_l2ittodr_disp_valid = 1;
    top->c0_l2d_0todr_disp_valid = 1;
    top->c0_l2dt_0todr_disp_valid = 1;
    top->c1_l2itodr_disp_valid = 1;
    top->c1_l2ittodr_disp_valid = 1;
    top->c1_l2d_0todr_disp_valid = 1;
    top->c1_l2dt_0todr_disp_valid = 1;

    top->c0_l2itodr_pfreq_valid = 1;
    top->c0_l2d_0todr_pfreq_valid = 1;
    top->c1_l2itodr_pfreq_valid = 1;
    top->c1_l2d_0todr_pfreq_valid = 1;

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
    top->c0_l2itodr_req_nid = rand() & 0x1f;
    top->c0_l2itodr_req_l2id = rand() & 0x3f;
    top->c0_l2itodr_req_cmd = rand() & 0xFF;
    top->c0_l2itodr_req_paddr = rand() & 0x0002ffffffffffff;
    top->l2todr1_req_retry = 1;
    top->l2todr0_req_retry = 1;
    advance_clock(top,1);
    top->c0_l2itodr_req_nid = rand() & 0x1f;
    top->c0_l2itodr_req_l2id = rand() & 0x3f;
    top->c0_l2itodr_req_cmd = rand() & 0xFF;
    top->c0_l2itodr_req_paddr = rand() & 0x0002ffffffffffff;
    top->l2todr1_req_retry = 1;
    top->l2todr0_req_retry = 1;
    advance_clock(top,1);

// REQS
    top->c0_l2itodr_req_nid = rand() & 0x1f;
    top->c0_l2itodr_req_l2id = rand() & 0x3f;
    top->c0_l2itodr_req_cmd = rand() & 0xFF;
    top->c0_l2itodr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2ittodr_req_nid = rand() & 0x1f;
    top->c0_l2ittodr_req_l2id = rand() & 0x3f;
    top->c0_l2ittodr_req_cmd = rand() & 0xFF;
    top->c0_l2ittodr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2d_0todr_req_nid = rand() & 0x1f;
    top->c0_l2d_0todr_req_l2id = rand() & 0x3f;
    top->c0_l2d_0todr_req_cmd = rand() & 0xFF;
    top->c0_l2d_0todr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2dt_0todr_req_nid = rand() & 0x1f;
    top->c0_l2dt_0todr_req_l2id = rand() & 0x3f;
    top->c0_l2dt_0todr_req_cmd = rand() & 0xFF;
    top->c0_l2dt_0todr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2itodr_req_nid = rand() & 0x1f;
    top->c1_l2itodr_req_l2id = rand() & 0x3f;
    top->c1_l2itodr_req_cmd = rand() & 0xFF;
    top->c1_l2itodr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2ittodr_req_nid = rand() & 0x1f;
    top->c1_l2ittodr_req_l2id = rand() & 0x3f;
    top->c1_l2ittodr_req_cmd = rand() & 0xFF;
    top->c1_l2ittodr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2d_0todr_req_nid = rand() & 0x1f;
    top->c1_l2d_0todr_req_l2id = rand() & 0x3f;
    top->c1_l2d_0todr_req_cmd = rand() & 0xFF;
    top->c1_l2d_0todr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2dt_0todr_req_nid = rand() & 0x1f;
    top->c1_l2dt_0todr_req_l2id = rand() & 0x3f;
    top->c1_l2dt_0todr_req_cmd = rand() & 0xFF;
    top->c1_l2dt_0todr_req_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);

    //DISPS
    top->c0_l2itodr_disp_nid = rand() & 0x1f;
    top->c0_l2itodr_disp_l2id = rand() & 0x3f;
    top->c0_l2itodr_disp_drid = rand() & 0;
    top->c0_l2itodr_disp_mask = rand() & 0;
    //top->c0_l2itodr_disp_line = rand() & 0xFFFF;
    top->c0_l2itodr_disp_dcmd = rand() & 0x7;
    top->c0_l2itodr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2ittodr_disp_nid = rand() & 0x1f;
    top->c0_l2ittodr_disp_l2id = rand() & 0x3f;
    top->c0_l2ittodr_disp_drid = rand() & 0;
    top->c0_l2ittodr_disp_mask = rand() & 0;
    //top->c0_l2ittodr_disp_line = rand() & 0xFFFF;
    top->c0_l2ittodr_disp_dcmd = rand() & 0x7;
    top->c0_l2ittodr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2d_0todr_disp_nid = rand() & 0x1f;
    top->c0_l2d_0todr_disp_l2id = rand() & 0x3f;
    top->c0_l2d_0todr_disp_drid = rand() & 0;
    top->c0_l2d_0todr_disp_mask = rand() & 0;
    //top->c0_l2d_0todr_disp_line = rand() & 0xFFFF;
    top->c0_l2d_0todr_disp_dcmd = rand() & 0x7;
    top->c0_l2d_0todr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2dt_0todr_disp_nid = rand() & 0x1f;
    top->c0_l2dt_0todr_disp_l2id = rand() & 0x3f;
    top->c0_l2dt_0todr_disp_drid = rand() & 0;
    top->c0_l2dt_0todr_disp_mask = rand() & 0;
    //top->c0_l2dt_0todr_disp_line = rand() & 0xFFFF;
    top->c0_l2dt_0todr_disp_dcmd = rand() & 0x7;
    top->c0_l2dt_0todr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2itodr_disp_nid = rand() & 0x1f;
    top->c1_l2itodr_disp_l2id = rand() & 0x3f;
    top->c1_l2itodr_disp_drid = rand() & 0;
    top->c1_l2itodr_disp_mask = rand() & 0;
    //top->c1_l2itodr_disp_line = rand() & 0xFFFF;
    top->c1_l2itodr_disp_dcmd = rand() & 0x7;
    top->c1_l2itodr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2ittodr_disp_nid = rand() & 0x1f;
    top->c1_l2ittodr_disp_l2id = rand() & 0x3f;
    top->c1_l2ittodr_disp_drid = rand() & 0;
    top->c1_l2ittodr_disp_mask = rand() & 0;
    //top->c1_l2ittodr_disp_line = rand() & 0xFFFF;
    top->c1_l2ittodr_disp_dcmd = rand() & 0x7;
    top->c1_l2ittodr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2d_0todr_disp_nid = rand() & 0x1f;
    top->c1_l2d_0todr_disp_l2id = rand() & 0x3f;
    top->c1_l2d_0todr_disp_drid = rand() & 0;
    top->c1_l2d_0todr_disp_mask = rand() & 0;
    //top->c1_l2d_0todr_disp_line = rand() & 0xFFFF;
    top->c1_l2d_0todr_disp_dcmd = rand() & 0x7;
    top->c1_l2d_0todr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2dt_0todr_disp_nid = rand() & 0x1f;
    top->c1_l2dt_0todr_disp_l2id = rand() & 0x3f;
    top->c1_l2dt_0todr_disp_drid = rand() & 0;
    top->c1_l2dt_0todr_disp_mask = rand() & 0;
    //top->c1_l2dt_0todr_disp_line = rand() & 0xFFFF;
    top->c1_l2dt_0todr_disp_dcmd = rand() & 0x7;
    top->c1_l2dt_0todr_disp_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);

    //PFREQ
    top->c0_l2itodr_pfreq_nid = rand() & 0x1f;
    top->c0_l2itodr_pfreq_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c0_l2d_0todr_pfreq_nid = rand() & 0x1f;
    top->c0_l2d_0todr_pfreq_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2itodr_pfreq_nid = rand() & 0x1f;
    top->c1_l2itodr_pfreq_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);
    top->c1_l2d_0todr_pfreq_nid = rand() & 0x1f;
    top->c1_l2d_0todr_pfreq_paddr = rand() & 0x0002ffffffffffff;
    advance_clock(top,1);

    //SNOOP_ACKS
    
    top->c0_l2itodr_snoop_ack_l2id = rand() & 0x3f;
    top->c0_l2itodr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c0_l2ittodr_snoop_ack_l2id = rand() & 0x3f;
    top->c0_l2ittodr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c0_l2d_0todr_snoop_ack_l2id = rand() & 0x3f;
    top->c0_l2d_0todr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c0_l2dt_0todr_snoop_ack_l2id = rand() & 0x3f;
    top->c0_l2dt_0todr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c1_l2itodr_snoop_ack_l2id = rand() & 0x3f;
    top->c1_l2itodr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c1_l2ittodr_snoop_ack_l2id = rand() & 0x3f;
    top->c1_l2ittodr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c1_l2d_0todr_snoop_ack_l2id = rand() & 0x3f;
    top->c1_l2d_0todr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);
    top->c1_l2dt_0todr_snoop_ack_l2id = rand() & 0x3f;
    top->c1_l2dt_0todr_snoop_ack_directory_id = rand() & 0x3;
    advance_clock(top,1);

    for(int i =0;i<1024;i++) 
    {
      try_send_packet_req(top);
      try_send_packet_disp(top);
      try_send_packet_pfreq(top);
    	advance_half_clock(top);
    	try_recv_packet_req(top);
    	try_recv_packet_disp(top);
    	try_recv_packet_pfreq(top);
      advance_half_clock(top);

      if (((rand() & 0x3)==0) && inp_list_c0_l2i_req.size() < 3) {
      	InputPacket_c0_l2itodr_req c0l2i2dr_req;
        InputPacket_c0_l2ittodr_req c0l2it2dr_req;
        InputPacket_c0_l2d_0todr_req c0l2d2dr_req;
        InputPacket_c0_l2dt_0todr_req c0l2dt2dr_req;
        InputPacket_c1_l2itodr_req c1l2i2dr_req;
        InputPacket_c1_l2ittodr_req c1l2it2dr_req;
        InputPacket_c1_l2d_0todr_req c1l2d2dr_req;
        InputPacket_c1_l2dt_0todr_req c1l2dt2dr_req;

        c0l2i2dr_req.nid = rand() & 0x1f;
        c0l2i2dr_req.l2id = rand() & 0x3f;
        c0l2i2dr_req.cmd = rand() & 0xFF;
        c0l2i2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c0l2it2dr_req.nid = rand() & 0x1f;
        c0l2it2dr_req.l2id = rand() & 0x3f;
        c0l2it2dr_req.cmd = rand() & 0xFF;
        c0l2it2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c0l2d2dr_req.nid = rand() & 0x1f;
        c0l2d2dr_req.l2id = rand() & 0x3f;
        c0l2d2dr_req.cmd = rand() & 0xff;
        c0l2d2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c0l2dt2dr_req.nid = rand() & 0x1f;
        c0l2dt2dr_req.l2id = rand() & 0x3f;
        c0l2dt2dr_req.cmd = rand() & 0xff;
        c0l2dt2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c1l2i2dr_req.nid = rand() & 0x1f;
        c1l2i2dr_req.l2id = rand() & 0x3f;
        c1l2i2dr_req.cmd = rand() & 0xFF;
        c1l2i2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c1l2it2dr_req.nid = rand() & 0x1f;
        c1l2it2dr_req.l2id = rand() & 0x3f;
        c1l2it2dr_req.cmd = rand() & 0xFF;
        c1l2it2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c1l2d2dr_req.nid = rand() & 0x1f;
        c1l2d2dr_req.l2id = rand() & 0x3f;
        c1l2d2dr_req.cmd = rand() & 0xff;
        c1l2d2dr_req.paddr = rand() & 0x0002ffffffffffff;
        c1l2dt2dr_req.nid = rand() & 0x1f;
        c1l2dt2dr_req.l2id = rand() & 0x3f;
        c1l2dt2dr_req.cmd = rand() & 0xff;
        c1l2dt2dr_req.paddr = rand() & 0x0002ffffffffffff;

        inp_list_c0_l2i_req.push_front(c0l2i2dr_req);
        inp_list_c0_l2it_req.push_front(c0l2it2dr_req);
        inp_list_c0_l2d_req.push_front(c0l2d2dr_req);
        inp_list_c0_l2dt_req.push_front(c0l2dt2dr_req);
        inp_list_c1_l2i_req.push_front(c1l2i2dr_req);
        inp_list_c1_l2it_req.push_front(c1l2it2dr_req);
        inp_list_c1_l2d_req.push_front(c1l2d2dr_req);
        inp_list_c1_l2dt_req.push_front(c1l2dt2dr_req);
      }
      
      if (((rand() & 0x3)==0) && inp_list_c0_l2i_disp.size() < 3) {
      	InputPacket_c0_l2itodr_disp c0l2i2dr_disp;
        InputPacket_c0_l2ittodr_disp c0l2it2dr_disp;
        InputPacket_c0_l2d_0todr_disp c0l2d2dr_disp;
        InputPacket_c0_l2dt_0todr_disp c0l2dt2dr_disp;
        InputPacket_c1_l2itodr_disp c1l2i2dr_disp;
        InputPacket_c1_l2ittodr_disp c1l2it2dr_disp;
        InputPacket_c1_l2d_0todr_disp c1l2d2dr_disp;
        InputPacket_c1_l2dt_0todr_disp c1l2dt2dr_disp;

        c0l2i2dr_disp.nid = rand() & 0x1f;
        c0l2i2dr_disp.l2id = rand() & 0x3f;
        c0l2i2dr_disp.dcmd = rand() & 0xFF;
        c0l2i2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c0l2i2dr_disp.drid = rand() & 0x3f;
        c0l2i2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c0l2i2dr_disp.mask = 0;             // I'm not sure what this is, but shouldnt matter to the network.
        c0l2it2dr_disp.nid = rand() & 0x1f;
        c0l2it2dr_disp.l2id = rand() & 0x3f;
        c0l2it2dr_disp.dcmd = rand() & 0xFF;
        c0l2it2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c0l2it2dr_disp.drid = rand() & 0x3f;
        c0l2it2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c0l2it2dr_disp.mask = 0;  
        c0l2d2dr_disp.nid = rand() & 0x1f;
        c0l2d2dr_disp.l2id = rand() & 0x3f;
        c0l2d2dr_disp.dcmd = rand() & 0xFF;
        c0l2d2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c0l2d2dr_disp.drid = rand() & 0x3f;
        c0l2d2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c0l2d2dr_disp.mask = 0;  
        c0l2dt2dr_disp.nid = rand() & 0x1f;
        c0l2dt2dr_disp.l2id = rand() & 0x3f;
        c0l2dt2dr_disp.dcmd = rand() & 0xFF;
        c0l2dt2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c0l2dt2dr_disp.drid = rand() & 0x3f;
        c0l2dt2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c0l2dt2dr_disp.mask = 0;  
        c1l2i2dr_disp.nid = rand() & 0x1f;
        c1l2i2dr_disp.l2id = rand() & 0x3f;
        c1l2i2dr_disp.dcmd = rand() & 0xFF;
        c1l2i2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c1l2i2dr_disp.drid = rand() & 0x3f;
        c1l2i2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c1l2i2dr_disp.mask = 0;           
        c1l2it2dr_disp.nid = rand() & 0x1f;
        c1l2it2dr_disp.l2id = rand() & 0x3f;
        c1l2it2dr_disp.dcmd = rand() & 0xFF;
        c1l2it2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c1l2it2dr_disp.drid = rand() & 0x3f;
        c1l2it2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c1l2it2dr_disp.mask = 0;  
        c1l2d2dr_disp.nid = rand() & 0x1f;
        c1l2d2dr_disp.l2id = rand() & 0x3f;
        c1l2d2dr_disp.dcmd = rand() & 0xFF;
        c1l2d2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c1l2d2dr_disp.drid = rand() & 0x3f;
        c1l2d2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c1l2d2dr_disp.mask = 0;  
        c1l2dt2dr_disp.nid = rand() & 0x1f;
        c1l2dt2dr_disp.l2id = rand() & 0x3f;
        c1l2dt2dr_disp.dcmd = rand() & 0xFF;
        c1l2dt2dr_disp.paddr = rand() & 0x0002ffffffffffff;
        c1l2dt2dr_disp.drid = rand() & 0x3f;
        c1l2dt2dr_disp.line = rand() & 0xFFFFFFFFFFFFFFFF;
        c1l2dt2dr_disp.mask = 0;  

        inp_list_c0_l2i_disp.push_front(c0l2i2dr_disp);
        inp_list_c0_l2it_disp.push_front(c0l2it2dr_disp);
        inp_list_c0_l2d_disp.push_front(c0l2d2dr_disp);
        inp_list_c0_l2dt_disp.push_front(c0l2dt2dr_disp);
        inp_list_c1_l2i_disp.push_front(c1l2i2dr_disp);
        inp_list_c1_l2it_disp.push_front(c1l2it2dr_disp);
        inp_list_c1_l2d_disp.push_front(c1l2d2dr_disp);
        inp_list_c1_l2dt_disp.push_front(c1l2dt2dr_disp);
      }

      if (((rand() & 0x3)==0) && inp_list_c0_l2i_pfreq.size() < 3) {
      	InputPacket_c0_l2itodr_pfreq c0l2i2dr_pfreq;
        InputPacket_c0_l2d_0todr_pfreq c0l2d2dr_pfreq;
        InputPacket_c1_l2itodr_pfreq c1l2i2dr_pfreq;
        InputPacket_c1_l2d_0todr_pfreq c1l2d2dr_pfreq;

        c0l2i2dr_pfreq.nid = rand() & 0x1f;
        c0l2i2dr_pfreq.paddr = rand() & 0x0002ffffffffffff;
        c0l2d2dr_pfreq.nid = rand() & 0x1f;
        c0l2d2dr_pfreq.paddr = rand() & 0x0002ffffffffffff;
        c1l2i2dr_pfreq.nid = rand() & 0x1f;
        c1l2i2dr_pfreq.paddr = rand() & 0x0002ffffffffffff;
        c1l2d2dr_pfreq.nid = rand() & 0x1f;
        c1l2d2dr_pfreq.paddr = rand() & 0x0002ffffffffffff;

        inp_list_c0_l2i_pfreq.push_front(c0l2i2dr_pfreq);
        inp_list_c0_l2d_pfreq.push_front(c0l2d2dr_pfreq);
        inp_list_c1_l2i_pfreq.push_front(c1l2i2dr_pfreq);
        inp_list_c1_l2d_pfreq.push_front(c1l2d2dr_pfreq);
      }
      advance_clock(top,1);
    }
  }
  printf("performed %lld test in %lld cycles\n",ntests,(long long)global_time/2);

  sim_finish(true);
}