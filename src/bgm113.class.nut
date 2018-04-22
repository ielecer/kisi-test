class BGM113 {

	_uart = null; // UART hardware instance
    _reset_l = null; // Reset pin hardware instance
    _baud = null; // Baudrate
    _response_callbacks = null; //  Command responses callback queue
    _event_callbacks = null; // Event callback queue
	_uart_buffer = null; // RX char buffer

	constructor(uart, reset_l, baud = 115000) {
		init();

		_uart = uart;
		_reset_l = reset_l;
		_baud = baud;

		_response_callbacks = [];
		_event_callbacks = {};
		_uart_buffer = "";

		// There's no way i was going to forget this ;)
		_uart.setrxfifosize(10000)
		_uart.configure(_baud, 8, PARITY_NONE, 1, 0, read_uart.bindenv(this));

		if(_reset_l) {
			_reset_l.configure(DIGITAL_IN);
		}
	}

	function init() {

		const BLE_TIMEOUT = 20;
		const BLE_MAX_PAYLOAD = 0xFF;
		const BLE_HEADER_SIZE = 4;
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
			MESSAGING 	= 0xFF // User messaging
		}

    	enum BLE_MESSAGE_TYPE {
    		COMMAND = 0x20, // Commands and Command Responses
			EVENT	= 0xA0  // Event notifications
		}

		enum BLE_HEADER_OFFSET {
			MESSAGE_TYPE = 0,
			LENGTH 		 = 1,
			CLASS_ID 	 = 2,
			COMMAND 	 = 3
		}

		enum BLE_ERRORS {
			INVALID_CONNECTION_HANDLE 						= 0x0101,
			WATING_RESPONSE									= 0x0102,
			GATT_CONNECTION_TIMEOUT							= 0x0103,
			INVALID_PARAM									= 0x0180,
			WRONG_STATE										= 0x0181,
			OUT_OF_MEMORY               					= 0x0182,
			NOT_IMPLEMENTED									= 0x0183,
			INVALID_COMMAND									= 0x0184,
			TIMEOUT 										= 0x0185,
			NOT_CONNECTED									= 0x0186,
			FLOW											= 0x0187,
			USER_ATTRIBUTE									= 0x0188,
			INVALID_LICENCE_KEY         					= 0x0189,
			COMMAND_TOO_LONG            					= 0x018A,
			OUT_OF_BONDS									= 0x018B,
			UNSPECIFIED										= 0x018C,
			HARDWARE 										= 0x018D,
			BUFFERS_FULL									= 0x018E,
			DISCONNECTED 									= 0x018F,
			TOO_MANY_REQUESTS								= 0x0190,
			NOT_SUPPORTED									= 0x0191,
			NO_BONDING 										= 0x0192,
			CRYPTO											= 0x0193,
			DATA_CORRUPTED									= 0x0194,
			COMMAND_INCOMPLETE								= 0x0195,
			UNKNOWN_CONNECTION_IDENTIFIER					= 0x0202,
			PAGE_TIMEOUT									= 0x0204,
			AUTHENTICATION_FAILURE							= 0x0205,
			PIN_OR_KEY_MISSING								= 0x0206,
			MEMORY_CAPACITY_EXCEEDED						= 0x0207,
			CONNECTION_TIMEOUT 								= 0x0208,
			CONNECTION_LIMIT_EXCEEDED						= 0x0209,
			SYNCHRONOUS_CONNECTION_LIMIT_EXCEEDED			= 0x020A,
			ACL_CONNECTION_ALREADY_EXISTS					= 0x020B,
			COMMAND_DISALLOWED								= 0x020C
		}

		enum BLE_GATT_ATT_OPCODE {
			READ_BY_TYPE_REQUEST 		= 8,
			READ_BY_TYPE_RESPONSE 		= 9,
			READ_REQUEST 				= 10,
			READ_RESPONSE 				= 11,
			READ_BLOB_REQUEST			= 12, 
			READ_BLOB_RESPONSE			= 13,
			READ_MULTIPLE_REQUEST		= 14,
			READ_MULTIPLE_RESPONSE 		= 15,
			WRITE_REQUEST				= 18,
			WRITE_RESPONSE				= 19,
			WRITE_COMMAND				= 82,
			PREPARE_WRITE_REQUEST		= 22,
			PREPARE_WRITE_RESPONSE 		= 23,
			EXECUTE_WRITE_REQUEST 		= 24,
			EXECUTE_WRITE_RESPONSE 		= 25,
			HANDLE_VALUE_NOTIFICATION 	= 27,
			HANDLE_VALUE_INDICATION 	= 29
		}

		enum BLE_GATT_CLIENT_CONFIG_FLAG {
			GATT_DISABLE 		= 0,
			GATT_NOTIFICATION 	= 1,
			GATT_INDICATION 	= 2
		}


		enum BLE_GATT_EXECUTE_WRITE_FLAG {
			GATT_CANCEL	= 0,
			GATT_COMMIT	= 1
		}

		enum BLE_GATT_SERVER_CHARACTERISTIC_STATUS_FLAG {
			GATT_SERVER_CLIENT_CONFIG = 1,
			GATT_SERVER_CONFIRMATION  = 2
		}

		enum BLE_GAP_ADDRESS_TYPE {
			PUBLIC 			= 0,
			RANDOM 			= 1,
			PUBLIC_IDENTITY = 2,
			RANDOM_IDENTITY = 3
		}

		enum BLE_GAP_ADVERTISING_ADDRESS_TYPE {
			IDENTITY_ADDRESS = 0, 
			NON_RESOLVABLE   = 1,
		}

		enum BLE_GAP_CONNECTABLE_MODE {
			NON_CONNTECTABLE		  = 0,
			DIRECTED_CONNECTABLE	  = 1,
			CONNECTABLE_SCANNABLE 	  = 2,
			SCANNABLE_NON_CONNECTABLE = 3,
			CONNECTABLE_NON_SCANNABLE = 4
		}

		enum BLE_GAP_DISCOVER_MODE {
			DISCOVER_LIMITED 	 = 0,
			DISCOVER_GENERIC 	 = 1,
			DISCOVER_OBSERVATION = 2
		}

		enum BLE_GAP_DISCOVERABLE_MODE {
			NON_DISCOVERABLE 		= 0,
			LIMITED_DISCOVERABLE 	= 1,
			GENERAL_DISCOVERABLE 	= 2,
			BROADCAST 				= 3,
			USER_DATA 				= 4, 
		}

		enum BLE_GAP_PHY_TYPE {
			PHY_1M 		= 1,
			PHY_2M 		= 2,
			PHY_CODED 	= 4,
		}
	}

	function log (type, message) {
		if ("log" in _event_callbacks) {
			_event_callbacks.log(type, message);
		} else if (type == "ERR") {
			server.error(format("%s: %s", type, message));
		} else if (type == "SEND" || type == "RECV") {
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

	function addr_to_string(payload) {
		assert(payload.len() == 6);
        return format("%02x:%02x:%02x:%02x:%02x:%02x", 
                    payload[5],
                    payload[4], 
                    payload[3], 
                    payload[2], 
                    payload[1], 
					payload[0]);
	}

    function addr_type_to_string(addr_type) {
        return (addr_type == 0) ? "public" : "random";
	}

    function string_to_addr_type(addr_type) {
        return (addr_type == "public") ? 0 : 1;
	}

    function halt() {
        if (_reset_l) {
            _reset_l.configure(DIGITAL_OUT);
            _reset_l.write(0);
        }
	}

    function reboot() {
        if (_reset_l) {
            _reset_l.configure(DIGITAL_OUT);
            _reset_l.write(0); 
            imp.wakeup(0.1, function() {
                _reset_l.write(1);
                _reset_l.configure(DIGITAL_IN);
                _uart_buffer = "";
                // Adding this seems to solve the issues
                // of booting in DFU mode
            }.bindenv(this))
        }
	}

	function fire_response (event) {
		local result = "unknown";
		if ("result" in event) {
			switch(event.result) {
				case 0x00: 
					result = "OK";
					break;
				case "timeout":
					result = "timeout";
					break;
				default:
					if (typeof event.result == "integer") {
						result = format("Error 0x%04x", event.result);
					}
					break;
			}
		}

		// Find the original callback in the queue and fire it
		for (local i = 0; i < _response_callbacks.len(); i++) {
			local cb = _response_callbacks[i];

			// If the events and command match, we cancel
			// the timeout, and call the eent callback.
			if(cb.cid == event.cid && cb.cmd == event.cmd) {
				imp.cancelwakeup(cb.timer); 
				cb.timer = null;
				_response_callbacks.remove(i);

				if (cb.callback != null) {
                    log("LOG", format("resp %s: %s", event.name, result)); 
                    result = null;
					cb.callback(event);
				}
				break;
			}
		}

        if (result != null) {
            log("LOG", format("resp %s: %s (unhandled)", event.name, result))
		}
	}

	function fire_event(event) {
		if (event.cid == BLE_CLASS_ID.SYSTEM && event.cmd == 0) {
			// After the device is booted, we have no use for previous callbacks
			// so we clear them. 

			_response_callbacks.clear();
		}

		// Find the event handler registered and fire it
		if (event.name in _event_callbacks) {
			log ("LOG", "event " + event.name);
			_event_callbacks[event.name](event);
		} else {
			log("LOG", "event " + event.name + " (unhandled)");
		}
	}


	function send_command (name, cid, cmd, payload, callback = null) {
		log("LOG", format("call %s", name));

		// Queue the callback, build the packet and send it off
        local command = {name=name, cid=cid, cmd=cmd, callback=callback};
        local timer = imp.wakeup(BLE_TIMEOUT, function() {
            // The timeout has expired. Send an event.
            command.result <- "timeout";
            fire_response(command);
		}.bindenv(this));

		command.timer <- timer;
		_response_callbacks.push(command);

	    local len = payload == null ? 0 : payload.len();
        local header = format("%c%c%c%c", BLE_MESSAGE_TYPE.COMMAND, len, cid, cmd);
		uart_write(header, payload);
	}

	function on(event, callback) {
		if (callback == null) {
			if (event in _event_callbacks) {
				delete _event_callbacks[event];
			}
		} else {
			_event_callbacks[event] <- callback;
		}
	}

	function uart_write(header, payload) {
		log("SEND", payload == null ? header : header + payload);

		// Send header 
		_uart.write(header);
		// Send payload if available. 
		if (payload != null) _uart.write(payload);
	}

	function read_uart() {

		local ch = null;

		// Fetch all the bytes, char by char and store them in
		// our internal buffer
		while ((ch = _uart.read()) != -1) {
			_uart_buffer += format("%c", ch);

			// We should only process one response / event at the time
			// so we check for the maximum size. If there are more 
			// bytes incoming, they'll be buffered by HW flow control.
			if (_uart_buffer.len() >= BLE_HEADER_SIZE + BLE_MAX_PAYLOAD) {
				break;
			}
		}

		if (_uart_buffer.len() == 0) {
			return;
		}

		// If there's enough characters to form a header, we start parsing
		while (_uart_buffer.len() >= BLE_HEADER_SIZE) {

			local event = null;

			try {
				event = parse_packet(_uart_buffer);
			} catch (e) {
				log ("ERR", "Exception parsing the UART buffer: " + e);
				throw "Exception parsing the UART buffer: " + e;
			}

			if (event != null) {
				log("RECV", _uart_buffer.slice(0, event.length + 4));
				_uart_buffer = _uart_buffer.slice(event.length + 4);

				if (event.message_type == BLE_MESSAGE_TYPE.COMMAND) {
					fire_response(event);
				} else {
					fire_event(event);
				}
			} else {
				// If the packet is incomplete, we skip the parsing and wait for it
				// to be complete.
				break;
			}
		}
	}

	function parse_packet(buffer) {
		
		// First, we parse the header;
		local event = {};

		event.message_type <- buffer[BLE_HEADER_OFFSET.MESSAGE_TYPE];
		event.length <- buffer[BLE_HEADER_OFFSET.LENGTH];
		event.cid <- buffer[BLE_HEADER_OFFSET.CLASS_ID]
		event.cmd <- buffer[BLE_HEADER_OFFSET.COMMAND];
		event.name <- "unknown";
		event.result <- 0;
		event.payload <- {};

		local payload = null;
		if (event.length > 0) {
			// Check if the ammount of data in buffer is at least as big as 
			// header + payload indicate in header.
			if (buffer.len() >= BLE_HEADER_SIZE + event.length) {
				// Create the proper payload to be processed; 
				payload = buffer.slice(BLE_HEADER_SIZE, BLE_HEADER_SIZE + event.length);
			} else  {
				// Incomplete packet
				return null;
			}
		}

		// Now we analyse each individual case.
		// At the momment, we only parse System and GAP responses and events 
		switch (event.message_type) {
			// Command responses
			case BLE_MESSAGE_TYPE.COMMAND:
				switch(event.cid) {
					case BLE_CLASS_ID.SYSTEM:
						switch (event.cmd) {
							// system_hello response
							case 0:
								event.name <- "system_hello";
								event.result <- payload[0] + (payload[1] << 8);
								break;
							
							//  system_get_bt_address response
							case 3:
								event.payload.address <- addr_to_string(payload.slice(0, 6));
								event.name <- "system_get_bt_address";
								break;

							// system_halt response
							case 12:
								event.result <- payload[0] + (payload[1] << 8);
								event.name <- "system_halt";
								break;
						}
						break;

					case BLE_CLASS_ID.GAP:
						switch(event.cmd) {
							// gap_end_procedure response
							case 3:
								event.result <- payload[0] + (payload[1] << 8);
								event.name <- "gap_end_procedure";
								break;

							// gap_set_discovery_timing response
							case 22: 
								event.result <- payload[0] + (payload[1] << 8);
								event.name <- "gap_set_discovery_timing";
								break;

							// gap_set_discovery_type response
							case 23:
								event.result <- payload[0] + (payload[1] << 8);
								event.name <- "gap_set_discovery_type";
								break;

							// gap_start_discovery response
							case 24:
								event.result <- payload[0] + (payload[1] << 8);
								event.name <- "gap_start_discovery";
								break;	
						}
						break;	
				}
				break;

			// Events
			case BLE_MESSAGE_TYPE.EVENT:
				switch(event.cid) {
					case BLE_CLASS_ID.DFU:
						switch(event.cmd) {
							case 0:
								event.payload.bootloader <- payload[0] + (payload[1] << 8) + (payload[2] << 16) + (payload[3] << 24);
								event.name <- "dfu_boot";
								break;

							case 1:
								event.reason <- payload[0] + (payload[1] << 8);
								event.name <-"dfu_boot_failure";
								break;
						}
						break;


					case BLE_CLASS_ID.SYSTEM: 
						switch (event.cmd) {
							// system_boot event
							case 0:
								event.payload.major <- payload[0] + (payload[1] << 8);
								event.payload.minor <- payload[2] + (payload[3] << 8);
								event.payload.patch <- payload[4] + (payload[5] << 8);
								event.payload.build <- payload[6] + (payload[7] << 8);
								event.payload.bootloader <- payload[8] + (payload[9] << 8) + (payload[10] << 16) + (payload[11] << 24);
								//event.payload.hw <- payload[12] + (payload[13] << 8);
								//event.payload.hash <- payload[14] + (payload[15] << 8) + (payload[16] << 16) + (payload[17] << 24);
								event.name <- "system_boot";
								break;
						}
						break;

					case BLE_CLASS_ID.GAP:
						switch(event.cmd) {
							// gap_scan_response
							case 0:
								event.payload.rssi <- payload[0] //- 256;
								switch(payload[1] & 0x7) {
									case 0: event.payload.packet_type <- "connectable_scannable"; break;
									case 1: event.payload.packet_type <- "connectable"; break;
									case 2: event.payload.packet_type <- "connectable_scannable"; break;
									case 3: event.payload.packet_type <- "scannable"; break;
									case 4: event.payload.packet_type <- "non_connectable_non_scannable"; break;
									default: event.payload.packet_type <- "unknown"; break;
								}
								event.payload.sender <- addr_to_string(payload.slice(2, 8));
								event.payload.address_type <- addr_type_to_string(payload[8]);
								event.payload.bond <- payload[9];
								event.payload.data <- [];
                                try {
                                    for (local i = 11; i < payload.len(); i++) {
                                        local len = payload[i++];
                                        
                                        local advpart = {};
                                        advpart.type <- payload[i++];
                                        advpart.data <- payload.slice(i, i+len-1);
                                        
                                        event.payload.data.push(advpart);
                                        
                                        i += len-2;
                                    }
                                }  catch (e) {
                                    log("ERR", "Failed to parse advertising packet: " + e);
                                }
                                event.name <- "gap_scan_response";
								break;
						}
						break;
				}
				break;
		}

		return event;
	}

	function dfu_reset(boot_type = 0) {
		local payload = format("%c", boot_type);
		return send_command("dfu_reset", BLE_CLASS_ID.DFU, 0, payload);
	}

    function system_hello(callback = null) {
        return send_command("system_hello", BLE_CLASS_ID.SYSTEM, 0, null, callback);
	}

    function system_get_bt_address(callback = null) {
        return send_command("system_get_bt_address", BLE_CLASS_ID.SYSTEM, 3, null, callback);
	}

	function system_reset(boot_in_dfu = 0) {
        local payload = format("%c", boot_in_dfu);
        return send_command("system_reset", BLE_CLASS_ID.SYSTEM, 0, payload);
	}

	function gap_end_procedure(callback = null) {
		return send_command("gap_end_procedure", BLE_CLASS_ID.GAP, 3, null, callback);
	}

	function gap_set_discovery_timing(phy, scan_interval, scan_window, callback = null) {
		assert(scan_interval >= 0x0004);
		assert(scan_interval <= 0xFFFF);
		assert(scan_interval >= 0x0004);
		assert(scan_interval <= 0xFFFF);

		local converted_scan_interval = scan_interval / 0.625;
		local converted_scan_window = scan_window / 0.625;

		local payload = format ("%c%c%c%c%c",
								phy,
								(converted_scan_interval.tointeger() && 0xFF), 
								((converted_scan_interval.tointeger()) >> 8) && 0xFF,
								(converted_scan_window.tointeger() && 0xFF), 
								(converted_scan_window.tointeger() >> 8) && 0xFF);

		return send_command("gap_set_discovery_timing", BLE_CLASS_ID.GAP, 0x16, payload, callback);
	}

	function gap_set_discovery_type(phy, scan_type, callback = null) {
		local payload = format ("%c%c", phy, scan_type);
		return send_command("gap_set_discovery_type", BLE_CLASS_ID.GAP, 0x17, payload, callback);
	}

	function gap_start_discovery(phy, mode, callback = null) {
		local payload = format("%c%c", phy, mode);
		return send_command("gap_start_discovery", BLE_CLASS_ID.GAP, 0x18, payload, callback);
	}
}


