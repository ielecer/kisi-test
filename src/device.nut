
@include "testclass.class.nut"

server.log("Hello World from Device");
server.log("Hello again");

local test = TestClass();

test.print_message();