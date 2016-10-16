#!/bin/env ruby

error_found = false
ARGV.each { |x|
  IO.popen("obj_dir/V#{x}") { |fd|
    pass_found = false
    fail_found = false
    while line = fd.gets
      if line =~/PASS/ 
        pass_found = true
      elsif line =~ /FAIL/ or line =~/ERROR/
        fail_found = true
      end
    end

    if fail_found
      error_found = true
      puts "FAIL: testbench #{x} failed"
      if pass_found
        puts "WEIRD: testbench #{x} failed but a pass was also detected"
      end
    else
      if pass_found
        puts "PASS: testbench #{x} passed"
      else
        puts "FAIL?: testbench #{x} neither pass or fail? fix it"
      end
    end
  }
}

if error_found
  exit 32
else
  exit 0
end

