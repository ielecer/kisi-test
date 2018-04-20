class BGM113 {

	_uart = null; // UART hardware instance
    _reset_l = null; // Reset pin hardware instance
    _baud = null; // Baudrate
    _response_callbacks = null; //  Command responses callback queue
    _event_callbacks = null; // Event callback queue
	_uart_buffer = null; // RX char buffer	
}