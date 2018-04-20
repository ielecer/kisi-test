
@include "testclass.class.nut"

server.log("Hello World from Device");

uart <- hardware.uart0;

const BLE_DUMP_MAX = 200;

enum BLE_CLASS_ID {
	DFU 		= 0x00, // Device Firmware updates over UART
	SYSTEM 		= 0x01, // System functions
	GAP			= 0x03, // Generic Access Profile
	CONNECTION 	= 0x08, // Connection management
	GATT_CLIENT	= 0x09,	// Generic Attribute Profile cilent
	GATT_SERVER = 0x0A, // Generic Attribute Profile server
	ENDPOINT 	= 0x0B, // Endpoint (DEPRICATED)
	HARDWARE    = 0x0C, // Hardware functionalities
	PERSISTENT 	= 0x0D, // Persistent store
	TEST		= 0x0E, // Testing Commands
	SECURITY    = 0x0F, // Security manager
	COEXISTANCE = 0x20, // Coexistance Interface
	MESSAGING 	= 0xFF, // User messaging
}



function readUART() {
	server.log("inside readUART");
	local ch  = null;
	local uart_buffer = "";
	while((ch = uart.read()) != -1) {
		uart_buffer += format("%c", ch);
	}

	server.log("Buffer len = %d", uart_buffer.len());
}


function log(type, message) {
	if (type == "ERR") {
		server.error(format("%s: %s", type, message));
	} else if(type == "SEND" || type == "RECV") {
		server.log(format("%s: %s", type, hexdump(message)));
	} else {
		server.log(format("%s: %s", type, message));
	}
}

function hexdump(dump, ascii = true) {
	local dbg = "";
	foreach (ch in dump) {
   		dbg += format("%02x ", ch)
    	if (ch >= 32 && ch <= 126 && ascii) dbg += format("[%c] ", ch);
        	if (dbg.len() > BLE_DUMP_MAX) {
                dbg += "... ";
                break;
           }
  	}
	return (dbg.len() > 0) ? dbg.slice(0, -1) : "";
}

function send_command(name, cid, cmd, payload) {
	log("LOG", format("call %s", name));
	local len = payload == null ? 0 : payload.len();
	local header = format("%c%c%c%c", (len >> 8) & 0x07, len & 0xFF, cid, cmd);
	uart_write(header, payload);
}

function uart_write (header, payload) {
	log("SEND", payload == null ? header : header + payload);
	uart.write(header);
	if (payload != null) uart.write(payload);
}

function system_hello() {
	send_command("system_hello", BLE_CLASS_ID.SYSTEM, 1, null);
	imp.wakeup(5.0, system_hello);
}

// Learn from other's mistakes =)
uart.setrxfifosize(10000);
uart.configure(115432, 8, PARITY_EVEN, 1, 0, readUART);

system_hello();


