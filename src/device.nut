@include "bgm113.class.nut"

mayor <- null;
minor <- null;
patch <- null;
build <- null;
bootloader <- null;
hw <- null;
address <- null;

server.log("Device booted.");
m_bgm113 <- BGM113(hardware.uart0, hardware.pinN);

m_bgm113.log("APP", "Booted ...");

m_bgm113.on("dfu_boot", function (event) {

	server.log("Booted in DFU mode");
	bootloader = format("%u", event.payload.bootloader);
	server.log("Bootloader version: " + bootloader);
})

m_bgm113.on("system_boot", function(event) {

	major = format("%u", event.payload.major);
	server.log("Major release version: " + major);
	minor = format("%u", event.payload.minor);
	server.log("Minor release version: " + minor);
	patch = format("%u", event.payload.patch);
	server.log("Patch release number: " + patch);
	build = format("%u", event.payload.build);
	server.log("Build number: " + build);
	bootloader = format("%u", event.payload.bootloader);
	server.log("Bootloader version: " + bootloader);
	hw = format("%u", event.payload.hw);
	server.log("Hardware type: " + hw);

	m_bgm113.system_get_bt_address(function (response) {
		if (response.result == 0 || response.result == "timeout") { 
			address = format("%s", response.payload.address);
			server.log("Address: " + address);
		} else {
	    	m_bgm113.log("ERR", "Error detecting the BMG113");
		}
	})
});

function say_hello() {

	m_bgm113.system_hello(function(response) {
		if (response.result == 0 || response.result == "timeout") {
			server.log("Hello back from BMG113");
		} else {
			m_bgm113.log("ERR", "Error communicating with BMG113");
		}
	});

	imp.wakeup(5, say_hello);
}

say_hello();