#!/bin/env ruby

error_found = false
ARGV.each { |x|
  seed = 0
  IO.popen("obj_dir/V#{x}") { |fd|
    pass_found = false
    fail_found = false
    while line = fd.gets
      if line =~/PASS/ 
        pass_found = true
      elsif line =~ /FAIL/ or line =~/ERROR/
        fail_found = true
      end

      if line =~ /My RAND/
        seed = line
      end
    end

    if fail_found
      error_found = true
      puts "FAIL: testbench #{x} failed"
      if pass_found
        puts "WEIRD: testbench #{x} failed but a pass was also detected"
      end
      puts seed
    else
      if pass_found
        puts "PASS: testbench #{x} passed"
      else
        puts "FAIL?: testbench #{x} neither pass or fail? fix it"
        puts seed
      end
    end
  }
}

if error_found
  exit 32
else
  exit 0
end

