# cmpe220fall16

[![Build Status](https://travis-ci.org/masc-ucsc/cmpe220fall16.svg?branch=master)](https://travis-ci.org/masc-ucsc/cmpe220fall16)

Public repository of the UCSC CMPE220 class project


# Commit directives

Commit your code as often as possible. Remember that only committed code can be
evaluated and used by others.

Before committing, try to make sure your code at least builds (for now), and
passes basic testing (once you have coded the tests).
 
When pushing remember to:
* Before pushing, do ```make lint``` to check if the code passes lint
* After pushing, click on the status button (on top of this page) to check the
  status of your build

If you have a piece of code that needs to be committed, or you do want to
commit, but does not meet these standards, you can always use ````ifdef 0```
type of statement, this will make the code available for others but without
breaking the build/tests of others.

# Wrapper modules

Wrapper modules are used for integration with C++ tests, therefore they should
not be included in the rtl/ directory, but rather in the tests/ directory. 
Make sure to commit your code to the appropriated place, to avoid issues in the
future.

# Passthrough

Remember that the passthroughs are supposed to be activated through a flag
(define statement), this will make it easier to debug errors during integration.
If you are unsure about it, check the example on rtl/l2cache_pipe.v file.
Also, name your passthrough identifying which block it is. A good example is
```L2_PASSTHROUGH```, since this allows to activate the passthrough of
individual modules. Avoid names like ```PASSTHROUGH``` since this will make it
harder to track each module uses each name and will increase the likelihood of
collisions. 

