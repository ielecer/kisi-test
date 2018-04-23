address <- null;
agent_url <- "";
scans_array <- [];
limit <- 0;

agent_url = format("%s", http.agenturl());


// Function to handle the address comming 
// from the device
device.on("location", function(location) {
    address = location.address;
    server.log("Address: " + address);
})

// Function to handle the parsed advertisement packets
// comming from the device. 
device.on("scans" function (scans) {
    scans_array.clear();
    foreach(beacon_id, data in scans) {
        local scans_array_elem = {};
        scans_array_elem.uuid <- data.uuid;
        scans_array_elem.major <- data.major;
        scans_array_elem.minor <- data.minor;
        scans_array_elem.rssi <- data.rssi[address].rssi;
        scans_array.push(scans_array_elem);
    }
});

function sort_scans_function(first, second) {
    if (first.rssi > second.rssi) return -1;
    if (first.rssi < second.rssi) return 1;
    return 0;
}

function request_handler(request, response) {
    if (request.path == "/") {
        try {
            // GET at / returns the UI
            response.send(200, agent_url); 
        } catch (ex) {
            // Send 500 response if error occurred
            response.send(500, ("Agent Error: " + ex)); 
        }
    }
    // GET at /closestIBeacons provides the API to get the closest beacons
    else if (request.path == "/closestIBeacons") {
        // closestIBeacons?limit=x is the only possible query.
        if ("limit" in request.query) {
          server.log("Limit requested");
          server.log(request.query.limit);
          //if limit is not an integer we throw a bad request.
          try {
              limit = request.query.limit.tointeger();
              // If limit is less or equal than zero, we throw a bad request.
              if (limit <= 0) {
                  try {
                      server.log("Negative or zero");
                      response.send(400, "Bad request");
                  } catch (ex) {
                      // Send 500 response if error occurred
                      response.send(500, ("Agent Error: " + ex))
                  }
              }  else {
                  scans_array.sort(sort_scans_function);
                  local data = {};
                  // If the limit is less than the total available beacons, we slice the array
                  if (limit < scans_array.len()) {
                      data = http.jsonencode(scans_array.slice(0, limit));
                  } else {
                      // If not we send the whole array.
                      data  = http.jsonencode(scans_array);
                  }

                  try {
                      response.send(200, data);
                  } catch (ex) {
                      response.send(500, ("Agent Error: " + ex));
                  }
              }
          } catch (ex) {
              server.log("Not an Integer");
              // Not valid query
              response.send(400, "Bad request");
          }
        } 
        // For all other queries we throw a bad request
        else {
            try {
                // Not valid query
                response.send(400, "Bad request"); 
            } catch (ex) {
                // Send 500 response if error occurred
                response.send(500, ("Agent Error: " + ex)); 
            }            
        }
    } else {
        try {
            // Not valid query
            response.send(400, "Bad request"); 
        } catch (ex) {
            // Send 500 response if error occurred
            response.send(500, ("Agent Error: " + ex)); 
        }      
    }
}

// Register the callback function that will be triggered by incoming HTTP requests
http.onrequest(request_handler);

server.log("Agent started, URL is " + agent_url);