class BGM113 {

	_uart = null; // UART hardware instance
    _reset_l = null; // Reset pin hardware instance
    _baud = null; // Baudrate
    _response_callbacks = null; //  Command responses callback queue
    _event_callbacks = null; // Event callback queue
	_uart_buffer = null; // RX char buffer

	constructor(uart, reset_l, baud = 115432) {
		init();

		_uart = uart;
		_reset_l = reset_l;
		_baud = baud;

		_response_callbacks = [];
		_event_callbacks = {};
		_uart_buffer = "";

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
            }.bindenv(this))
        }
	}

}












