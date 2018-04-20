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
}