
#################################################################
##  Script that creates a top module for the memory hierarchy  ##
##                                                             ##
## this script will create a top module and connect blocks,    ##
## based on an input configuration that includes:              ##
## - number of cores                                           ##
## - number of cache slices per core                            ##
## - number of directories in the network                      ##
#################################################################

require 'optparse'

options = {}
optparse = OptionParser.new do |opts|

  opts.banner = "Usage: top_generator.rb [options]"

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-c#Cores", "--cores=#Cores", "Number of cores to generate") do |c|
    begin
      options[:cores] = c.to_i
    rescue
      puts "expecting an integer number of cores"
    end
  end

  opts.on("-t#slices", "--slices=#slices", "Number of dcache slices per core") do |t|
    begin
      options[:slices] = t.to_i
    rescue
      puts "expecting an integer number of slices"
    end
  end

  opts.on("-d#Directory", "--dir=#Directory", "Number of directories in the network") do |d|
    begin
      options[:directory] = d.to_i
    rescue
      puts "expecting an integer number of directories"
    end
  end

  opts.on("-h", "--help", "Prints this help menu") do 
    puts opts
    exit
  end
end

optparse.parse!

if options[:cores] == nil or options[:slices] == nil or options[:directory] == nil
  p optparse.display
  exit 1
end


$icache_core_interface = [
  ["coretoic_valid        ",  "input ", "                    "], 
  ["coretoic_retry        ",  "output", "                    "], 
  ["coretoic_pc           ",  "input ", "SC_laddr_type       "], 

  ["ictocore_valid        ",  "output", "                    "], 
  ["ictocore_retry        ",  "input ", "                    "], 
  ["ictocore              ",  "output", "I_ictocore_type     "]
];

$icache_l2_interface = [
  ["l1tol2_req_valid      ",  "output", "                    "], 
  ["l1tol2_req_retry      ",  "input ", "                    "], 
  ["l1tol2_req            ",  "output", "I_l1tol2_req_type   "], 

  ["l2tol1_snack_valid    ",  "input ", "                    "], 
  ["l2tol1_snack_retry    ",  "output", "                    "], 
  ["l2tol1_snack          ",  "input ", "I_l2tol1_snack_type "], 

  ["l2tol1_snoop_ack_valid",  "output", "                    "], 
  ["l2tol1_snoop_ack_retry",  "input ", "                    "], 
  ["l2tol1_snoop_ack      ",  "output", "I_l2snoop_ack_type  "], 

  ["l1tol2pf_req_valid    ",  "output", "                    "], 
  ["l1tol2pf_req_retry    ",  "input ", "                    "], 
  ["l1tol2pf_req          ",  "output", "I_pftocache_req_type"]
];

$dcache_core_interface = [
  ["coretodc_ld_valid     ", "input ", "                        "],
  ["coretodc_ld_retry     ", "output", "                        "],
  ["coretodc_ld           ", "input ", " I_coretodc_ld_type     "],

  ["dctocore_ld_valid     ", "output", "                        "],
  ["dctocore_ld_retry     ", "input ", "                        "],
  ["dctocore_ld           ", "output", " I_coretodc_ld_type     "],

  ["coretodc_std_valid    ", "input ", "                        "],
  ["coretodc_std_retry    ", "output", "                        "],
  ["coretodc_std          ", "input ", " I_coretodc_std_type    "],

  ["dctocore_std_ack_valid", "output", "                        "],
  ["dctocore_std_ack_retry", "input ", "                        "],
  ["dctocore_std_ack      ", "output", " I_dctocore_std_ack_type"]
]

$dcache_prefetch_interface = [
  ["pftocache_req_valid   ", "input ", "                        "],
  ["pftocache_req_retry   ", "output", "                        "],
  ["pftocache_req         ", "input ", " I_pftocache_req_type   "],

  ["cachetopf_stats       ", "output", " PF_cache_stats_type    "]
];

$dcache_l2_interface = [
  ["l1tol2_req_valid      ", "output", "                        "],
  ["l1tol2_req_retry      ", "input ", "                        "],
  ["l1tol2_req            ", "output", " I_l1tol2_req_type      "],

  ["l2tol1_snack_valid    ", "input ", "                        "],
  ["l2tol1_snack_retry    ", "output", "                        "],
  ["l2tol1_snack          ", "input ", " I_l2tol1_snack_type    "],

  ["l1tol2_snoop_ack_valid", "output", "                        "],
  ["l1tol2_snoop_ack_retry", "input ", "                        "],
  ["l1tol2_snoop_ack      ", "output", " I_l2snoop_ack_type     "],

  ["l1tol2_disp_valid     ", "output", "                        "],
  ["l1tol2_disp_retry     ", "input ", "                        "],
  ["l1tol2_disp           ", "output", " I_l1tol2_disp_type     "],

  ["l2tol1_dack_valid     ", "input ", "                        "],
  ["l2tol1_dack_retry     ", "output", "                        "],
  ["l2tol1_dack           ", "input ", " I_l2tol1_dack_type     "],

  ["l1tol2_pfreq_valid    ", "output", "                        "],
  ["l1tol2_pfreq_retry    ", "input ", "                        "],
  ["l1tol2_pfreq          ", "output", " I_pftocache_req_type   "]
]

$directory_l2_interface = [
  ["l2todr_pfreq_valid    ", "input ", "                     "],
  ["l2todr_pfreq_retry    ", "output", "                     "],
  ["l2todr_pfreq          ", "input ", " I_l2todr_req_type   "],

  ["l2todr_req_valid      ", "input ", "                     "],
  ["l2todr_req_retry      ", "output", "                     "],
  ["l2todr_req            ", "input ", " I_l2todr_req_type   "],

  ["drtol2_snack_valid    ", "output", "                     "],
  ["drtol2_snack_retry    ", "input ", "                     "],
  ["drtol2_snack          ", "output", " I_drtol2_snack_type "],

  ["l2todr_disp_valid     ", "input ", "                     "],
  ["l2todr_disp_retry     ", "output", "                     "],
  ["l2todr_disp           ", "input ", " I_l2todr_disp_type  "],

  ["drtol2_dack_valid     ", "output", "                     "],
  ["drtol2_dack_retry     ", "input ", "                     "],
  ["drtol2_dack           ", "output", " I_drtol2_dack_type  "],

  ["l2todr_snoop_ack_valid", "output", "                     "],
  ["l2todr_snoop_ack_retry", "input ", "                     "],
  ["l2todr_snoop_ack      ", "output", " I_drsnoop_ack_type  "]
]

$directory_memory_interface = [
  ["drtomem_req_valid     ", "output", "                     "],
  ["drtomem_req_retry     ", "input ", "                     "],
  ["drtomem_req           ", "output", " I_drtomem_req_type  "],

  ["memtodr_ack_valid     ", "input ", "                     "],
  ["memtodr_ack_retry     ", "output", "                     "],
  ["memtodr_ack           ", "input ", " I_memtodr_ack_type  "],

  ["drtomem_wb_valid      ", "output", "                     "],
  ["drtomem_wb_retry      ", "input ", "                     "],
  ["drtomem_wb            ", "output", " I_drtomem_wb_type   "],

  ["drtomem_pfreq_valid   ", "output", " logic               "],
  ["drtomem_pfreq_retry   ", "input ", " logic               "],
  ["drtomem_pfreq         ", "output", " I_drtomem_pfreq_type"]
]

$prefetecher_core_interface = [
  ["pfgtopfe_op_valid", "input ", "logic               "],
  ["pfgtopfe_op_retry", "output", "logic               "],
  ["pfgtopfe_op      ", "input ", "I_pfgtopfe_op_type  "]
]

$prefetcher_cache_interface = [
  ["pftodc_req0_valid", "output", "logic               "],
  ["pftodc_req0_retry", "input ", "logic               "],
  ["pftodc_req0      ", "output", "I_pftocache_req_type"],

  ["pftol2_req0_valid", "output", "logic               "],
  ["pftol2_req0_retry", "input ", "logic               "],
  ["pftol2_req0      ", "output", "I_pftocache_req_type"],


  ["pftodc_req1_valid", "output", "logic               "],
  ["pftodc_req1_retry", "input ", "logic               "],
  ["pftodc_req1      ", "output", "I_pftocache_req_type"],

  ["pftol2_req1_valid", "output", "logic               "],
  ["pftol2_req1_retry", "input ", "logic               "],
  ["pftol2_req1      ", "output", "I_pftocache_req_type"],


  ["pftodc_req2_valid", "output", "logic               ", "SC_4PIPE"],
  ["pftodc_req2_retry", "input ", "logic               ", "SC_4PIPE"],
  ["pftodc_req2      ", "output", "I_pftocache_req_type", "SC_4PIPE"],

  ["pftodc_req3_valid", "output", "logic               ", "SC_4PIPE"],
  ["pftodc_req3_retry", "input ", "logic               ", "SC_4PIPE"],
  ["pftodc_req3      ", "output", "I_pftocache_req_type", "SC_4PIPE"],

  ["pftol2_req2_valid", "output", "logic               ", "SC_4PIPE"],
  ["pftol2_req2_retry", "input ", "logic               ", "SC_4PIPE"],
  ["pftol2_req2      ", "output", "I_pftocache_req_type", "SC_4PIPE"],

  ["pftol2_req3_valid", "output", "logic               ", "SC_4PIPE"],
  ["pftol2_req3_retry", "input ", "logic               ", "SC_4PIPE"],
  ["pftol2_req3      ", "output", "I_pftocache_req_type", "SC_4PIPE"],


  ["pf_dcstats       ", "output", "PF_cache_stats_type "],
  ["pf_l2stats       ", "output", "PF_cache_stats_type "],

  ["pf0_dcstats      ", "input ", "PF_cache_stats_type "],
  ["pf0_l2stats      ", "input ", "PF_cache_stats_type "],

  ["pf1_dcstats      ", "input ", "PF_cache_stats_type "],
  ["pf1_l2stats      ", "input ", "PF_cache_stats_type "],

  ["pf2_dcstats      ", "input ", "PF_cache_stats_type ", "SC_4PIPE"],
  ["pf2_l2stats      ", "input ", "PF_cache_stats_type ", "SC_4PIPE"],

  ["pf3_dcstats      ", "input ", "PF_cache_stats_type ", "SC_4PIPE"],
  ["pf3_l2stats      ", "input ", "PF_cache_stats_type ", "SC_4PIPE"]
];

def icache_ios core_id, f

  f.puts "   // icache core #{core_id}"
  $icache_core_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} core#{core_id}_#{name}"
  end
  f.puts 
end

def slice_ios core_id, slice_id, f

  f.puts "   // dcache core #{core_id}, slice #{slice_id}"
  $dcache_core_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} core#{core_id}_slice#{slice_id}_#{name}"
  end
  f.puts
end

def core_ios core_id, n_slices, f
  f.puts "   //******************************************"
  f.puts "   //*  CORE #{core_id}                       *"
  f.puts "   //******************************************//"
  icache_ios core_id, f
  n_slices.times do |slice|
    slice_ios core_id, slice, f
  end
  f.puts
  f.puts
end


def dr_ios dr_id, f
  f.puts "   //******************************************"
  f.puts "   //*  Directory #{dr_id}                    *"
  f.puts "   //******************************************//"
  $directory_memory_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} dr#{dr_id}_#{name}"
  end 
  f.puts 
end

def pf_ios core_id, f

  f.puts "    // core #{core_id} prefetcher "
  $prefetecher_core_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} core#{core_id}_#{name}"
  end 
  f.puts 
end

def dcache_instance core_id, slice_id, f

  $dcache_l2_interface.each do |name,dir,type|
    f.puts "  wire #{type} core#{coreid}_#{name};"
  end
  $dcache_prefetch_interface.each do |name,dir,type|
    f.puts "  wire #{type} core#{coreid}_#{name};"
  end

  f.puts
  f.puts "  dcache_pipe core#{core_id}_slice#{slice_id}_dcache("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $dcache_l2_interface.each do |name,dir,type|
    f.puts "  .#{name}(core#{coreid}_#{name})"
  end

  f.puts

  $dcache_core_interface.each do |name,dir,type|
    f.puts "  .#{name}(core#{coreid}_#{name})"
  end

  f.puts

  $dcache_prefetch_interface.each do |name,dir,type|
    f.puts "  .#{name}(core#{coreid}_#{name})"
  end

  f.puts ");"
end

def icache_instace core_id, f
  $icache_l2_interface.each do |name,dir,type|
    f.puts "  wire #{type} core#{coreid}_#{name};"
  end

  f.puts "  icache core#{core_id} ("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $icache_l2_interface.each do |name,dir,type|
    f.puts "  .#{name}(core#{coreid}_#{name})"
  end

  f.puts

  $icache_core_interface.each do |name,dir,type|
    f.puts "  .#{name}(core#{coreid}_#{name})"
  end

  f.puts ");"
end

f = STDOUT

f.puts "// file automatically generated by top_generator script"
f.puts "// this is a memory hierarchy done as a class project for CMPE220 at UCSC"
f.puts "// this specific file was generated for:"
f.puts "// #{options[:cores]} core(s), "
f.puts "// #{options[:slices]} data cache slice(s) per core, and"
f.puts "// #{options[:directory]} directory(ies)"
2.times { f.puts }

f.puts "module top_#{options[:cores]}core#{options[:directory]}dr("
f.puts "   input clk"
f.puts "  ,input reset"
f.puts

  options[:cores].times do |core|
    core_ios core, options[:slices], f
    pf_ios core, f
  end

  options[:directory].times do |dir|
    dr_ios dir, f
  end

f.puts ");"




f.puts "endmodule"

