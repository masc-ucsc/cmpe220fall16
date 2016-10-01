
// The l2tlb is the main cache coherent TLB
//
// The l2tlb are address mapped like the L2s, but they support
// cache coherence.
//
// Like the L2, the directory under can send coherence messages.
// This is the same as FUGU did in 1994 ("FUGU: Implementing Translation and
// Protection in a Multiuser, Multimodel Multiprocessor")
//
// The main TLB resides inside the L2, and snoops messages to be consistent.
//
// It has entries for each of the allowed TLB sizes. 
//
// ENTRY: ~160bits entry (~16bytes) ~16KB for a 1024 entry mainTLB
//   SPTBR   (base pointer & thread id ~48-12 bits)
//   VPN     (Virtual Page Number ~38-12 bits)
//   PPN     (Physical Page Number ~48-12 bits)
//   perm    (permissions ~12bits)
//   snoop   (Physical address were entry resides, 48 bits)
//
// Entries must be searchable by VPN (translation) and snoop (invalidate)
// (dctlb just VPN). 
//
// On TLB miss:
//
// 1-Page walk the TLB. Use the SBPTR+laddr[l] (see Priviliege RISCV ISA
// section 4.5.2)
//
// 2-Trigger SNOOP_TLBI with appropiate size and VPN to invalidate
//
// 2-Fill the TLB entry
//
// 3-Check if translated PADDR is in cache. Otherwise trigger cache miss
//
// 4-Reply to DC with perm
