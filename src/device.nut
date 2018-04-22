@include "bgm113.class.nut"

address <- null;
scans <- {};

server.log("Device booted.");
m_bgm113 <- BGM113(hardware.uart0, hardware.pinN);

m_bgm113.log("APP", "Booted ...");

m_bgm113.reboot();

m_bgm113.on("dfu_boot", function (event) {
    server.log("Booted in DFU mode");
    local bootloader = format("%u", event.payload.bootloader);
    server.log("Bootloader version: " + bootloader);
})

m_bgm113.on("system_boot", function(event) {

    local major = format("%u", event.payload.major);
    server.log("Major release version: " + major);
    local minor = format("%u", event.payload.minor);
    server.log("Minor release version: " + minor);
    local patch = format("%u", event.payload.patch);
    server.log("Patch release number: " + patch);
    local build = format("%u", event.payload.build);
    server.log("Build number: " + build);
    local bootloader = format("%u", event.payload.bootloader);
    server.log("Bootloader version: " + bootloader);

    m_bgm113.system_get_bt_address(function (response) {
        if (response.result == 0 || response.result == "timeout") { 
            address = format("%s", response.payload.address);
            server.log("Address: " + address);
            server.log("Starting discovery");

            local location = {};
            location.address <- address;
            location.mac <- imp.getmacaddress();
            location.deviceid <- hardware.getdeviceid();
            agent.send("location", location);
            
            // Start passive scanning
            discover_mode();
        } else {
            m_bgm113.log("ERR", "Error detecting the BMG113");
        }
    })
});

function discover_mode(active = false) {

    // Configure the scanning parameters, and start scanning.
    m_bgm113.gap_set_scan_parameters(75, 50, active ? 1 : 0);
    m_bgm113.gap_discover(BLE_GAP_DISCOVER_MODE.DISCOVER_GENERIC);

    // Here, we'll handle the scan responses
    m_bgm113.on("gap_scan_response", function (event) {

        foreach(advdata in event.payload.data) {
            // First we check if is a manufacturer specific data
            if (advdata.type == 0xFF) {
                // Then we check if is a beacon.
                // First two bytes must be 0x004C (Apple Company ID)
                // Second two bytes must be 0x1502 (iBeacon advertisement indicator)
                if (advdata.data.slice(0, 4) == "\x4c\x00\x02\x15") {

                    // This is a iBeacon
                    local uuid = advdata.data.slice(4, 20);
                    uuid = parse_uuid(uuid);
                    local major = advdata.data.slice(20, 22);
                    major = (major[0] << 8) + (major[1]);
                    local minor = advdata.data.slice(22, 24);
                    minor = (minor[0] << 8) + (minor[1]);
                    local power = advdata.data[24];
                    local beacon_id = format("%s:%d:%d", uuid, major, minor);

                    // If the detected beacon is not in our scan list
                    // we allocate the space for it
                    if (!(beacon_id in scans)) {
                        scans[beacon_id] <- {};
                        scans[beacon_id].rssi <- {};
                        scans[beacon_id].rssi[address] <- {};
                        scans[beacon_id].rssi[address].time <- time();
                        scans[beacon_id].rssi[address].samples <- 0;
                        scans[beacon_id].rssi[address].rssi <- 0.0;
                    }

                    // Update information for a beacon on our list
                    local beacon = scans[beacon_id];
                    beacon.uuid <- uuid;
                    beacon.major <- major;
                    beacon.minor <- minor;
                    beacon.time <- time();
                    beacon.rssi[address].samples++;
                    beacon.rssi[address].rssi += event.payload.rssi;
                    beacon.rssi[address].rssi /= 2;
                }
            }
        }
    })
}

function parse_uuid(uuid) {
    local result = "";
    foreach (ch in uuid) {
        result += format("%02X", ch)
    }
    return result;
}

function idle_updates() {
    imp.wakeup(10, idle_updates);
    if (scans.len() > 0) {
        agent.send("scans", scans);
        scans = {};
    }
}

imp.wakeup(5, idle_updates);
