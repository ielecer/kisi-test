

device.on("scans" function (scans) {
	foreach(beacon_id, data in scans) {
		server.log(beacon_id);
		server.log(data.samples)
		server.log(data.rssi);
		delete data.rssi;
	}
});


server.log("Agent started, URL is " + http.agenturl());
