# cmpe220fall16

[![Build Status](https://travis-ci.org/masc-ucsc/cmpe220fall16.svg?branch=master)](https://travis-ci.org/masc-ucsc/cmpe220fall16)

Public repository of the UCSC CMPE220 class project


# Commit directives

Commit your code as often as possible. Remember that only committed code can be
evaluated and used by others.

Before committing, try to make sure your code at least builds (for now), and
passes basic testing (once you have coded the tests). If you have a piece of
code that needs to be committed but does not meet these standards, use an ifdef,
if or separate module, so it does not break other people work.

When pushing remember to:
* Before pushing, do ```make lint``` to check if the code passes lint
* After puching click on the status button (on top of this page) to check the
  status of your build

# Wrapper modules

Wrapper modules are used for integration with C++ tests, therefore they should
not be included in the rtl/ directory, but rather in the tests/ directory. 
Make sure to commit your code to the appropriated place, to avoid issues in the
future.

