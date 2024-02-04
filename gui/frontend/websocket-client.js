const data = []
const display = document.getElementById("display");
const queue = document.getElementById("queue");
const money = document.getElementById("money");
const vehicles = document.getElementById("vehicles");
const time = document.getElementById("time");


document.addEventListener("DOMContentLoaded", function (x) {
    const messagesDiv = document.getElementById("messages");
    const socket = new WebSocket("ws://localhost:51282");

    // Connection opened
    socket.addEventListener("open", function (event) {
        console.log("WebSocket connection opened");
        setQueuePlot();
        setPhaseDiagram();
    });

    // Listen for messages
    socket.addEventListener("message", function (event) {
        console.log("Message from server:", event.data);
        const message = JSON.parse(event.data);
        data.push(message);
        displayMessage(message);
        updateQueuePlot(message);
        updatePhaseDiagram(message);
    });

    // Connection closed
    socket.addEventListener("close", function (event) {
        console.log("WebSocket connection closed");
        finalPointPhaseDiagram();
    });

    // Connection error
    socket.addEventListener("error", function (event) {
        console.error("WebSocket error:", event);
    });

    // Function to display a message on the webpage
    function displayMessage(message) {
        try {
            const msg_parking = message["parking"];
            const msg_queue = message["queue"];
            const msg_time = message["time"];

            const display_content = getDisplay(msg_parking);
            display.innerHTML = "";
            display.appendChild(display_content);

            const queue_content = getQueue(msg_queue);
            queue.innerHTML = "";
            queue.appendChild(queue_content);

            // add statistics
            // Check if properties exist before updating the inner text
            if (msg_parking && "money" in msg_parking) {
                money.innerText = (Math.round(msg_parking["money"] * 100) / 100).toFixed(2);
            }

            if (msg_parking && "vehicles" in msg_parking) {
                vehicles.innerText = msg_parking["vehicles"];
            }

            if (msg_time) {
                const messageTime = new Date(msg_time);
                const t0 = new Date(data[0]["time"]);

                const differenceInMilliseconds =  messageTime - t0;
                time.innerText = Math.floor(differenceInMilliseconds / 1000);
            }
            
        } catch (error) {
            console.error("Error displaying message:", error);
            // Handle the error appropriately, e.g., show an error message to the user
        }
    }
});

function getDisplay(message) {
    const spaceData = message["parking_space"];

    const parkingLot = document.createElement('div');
    parkingLot.classList.add('parking-lot');

    for (let i = 0; i < spaceData.length; i++) {
        const level = spaceData[i];
        parkingLot.appendChild(makeLabel('level-name', `Level ${i + 1}`));
        parkingLot.appendChild(makeLevel(level));
    }

    return parkingLot;
}

function getQueue(msg_queue) {
    const queueData = msg_queue["queue"];
    const max_queue_size = msg_queue["max_size"];

    const queue_content = document.createElement('div');
    queue_content.classList.add('queue-content');

    if (!queueData) {
        return getEmptyQueue(max_queue_size);
    }

    for (let i=0; i < queueData.length; i++) {
        const vehicle = queueData[i];
        const place_in_queue = makeQueuePlace(vehicle, i)
        queue_content.appendChild(place_in_queue);
    }
    if (queueData.length >= max_queue_size) {
        return queue_content;
    }

    for (let i=queueData.length; i < max_queue_size; i++) {
        const place_in_queue = getEmptyQueuePlace(i)
        queue_content.appendChild(place_in_queue);
    }

    return queue_content;
}

function getEmptyQueue(max_queue_size) {
    const empty_queue_content = document.createElement('div');
    empty_queue_content.classList.add('queue-content');

    for (let i=0; i < max_queue_size; i++) {
        const place_in_queue = getEmptyQueuePlace(i)
        empty_queue_content.appendChild(place_in_queue);
    }

    return empty_queue_content;
}

function getEmptyQueuePlace(i) {
    const place = document.createElement('div');
    place.classList.add('queue-place');
    place.classList.add('free');
    place.innerText = "Pl. " + ++i;

    return place;
}

function setQueuePlot(max_queue_size=10) {
    const queuePlot = document.getElementById("queue-plot");
    const data = [
        {
            x: [],
            y: [],
            mode: 'lines',
            yaxis: 'queue size',
            line: {
                color: '#DF56F1',
                size: 2,
            }
        }
    ];

    const layout = {
        height: 250, // Adjust the height as needed
        xaxis: {
            range: [0, 'auto']  // Set the x-axis to start from 0
        },
        yaxis: {
            range: [0, max_queue_size]  // Set the y-axis to start from 0
        },
        margin: {
            l: 10, // left margin
            r: 1, // right margin
            t: 1, // top margin
            b: 20  // bottom margin
        },
    };

    const config = {responsive: true}

    Plotly.newPlot(queuePlot, data, layout, config);
}

function updateQueuePlot(message) {
    const msg_queue = message["queue"];
    const msg_time = message["time"];

    // parse time
    const time = new Date(msg_time);

    const queuePlot = document.getElementById("queue-plot");
    const update = {
        x: [[time]],
        y: [[msg_queue["size"]]],
    };
    Plotly.relayout(queuePlot, {
        yaxis: {
            range: [0, msg_queue["max_size"]]
        },
    });
    Plotly.extendTraces(queuePlot, update, [0]);
}

function setPhaseDiagram() {
    const phasesDiagramPlot = document.getElementById("phases-diagram-plot");
    const data = [
        {
            x: [],
            y: [],
            mode: 'lines+markers',
            xaxis: 'level 1 saturation',
            yaxis: 'level 2 saturation',
            line: {
                color: 'rgba(255,0,0,0.8)' ,
                width: 3
            },
            name: 'saturation',
        }
    ];

    const layout = {
        width: 400,
        height: 400,
        margin: {
            l: 50, // left margin
            r: 70, // right margin
            t: 50, // top margin
            b: 50,  // bottom margin
        },
        xaxis: {
            range: [0, 100]
        },
        yaxis: {
            range: [0, 100]
        },
    }

    Plotly.newPlot(phasesDiagramPlot, data, layout);
}

function updatePhaseDiagram(message) {
    const msg_saturation = message["parking"]["levels_saturation"];
    const level_1_saturation = msg_saturation[0];
    let level_2_saturation = 0;
    if (msg_saturation.length >= 2) {
        level_2_saturation = msg_saturation[1];
    }
    const time = message["time"];

    const phasesDiagramPlot = document.getElementById("phases-diagram-plot");
    const update = {
        x: [[level_1_saturation]],
        y: [[level_2_saturation]],
    };

    Plotly.extendTraces(phasesDiagramPlot, update, [0]);
}

function finalPointPhaseDiagram() {
    const msg_saturation = data[data.length-1]["parking"]["levels_saturation"];
    debugger;
    const level_1_saturation = msg_saturation[0];
    let level_2_saturation = 0;
    if (msg_saturation.length >= 2) {
        level_2_saturation = msg_saturation[1];
    }

    const finalMarker = {
        x: [level_1_saturation],
        y: [level_2_saturation],
        mode: 'markers',
        marker: {
            size: 10, 
            color: 'green' 
        },
        name: 'final phase',
    };

    Plotly.addTraces('phases-diagram-plot', finalMarker);

}

function makePlace(data) {
    const place = document.createElement('div');
    place.classList.add('place');
    if (!data) {
        place.classList.add('free');
        return place;
    }

    if (data.startsWith("auto")) {
        place.classList.add('auto');
    } else if (data.startsWith("bus")) {
        place.classList.add('bus');
    } else if (data.startsWith("moto")) {
        place.classList.add('moto');
    } else {
        place.classList.add('free');
    }

    place.innerText = data;

    return place;
}

function makeRow(data) {
    const row = document.createElement('div');
    row.classList.add('row');

    for (const place of data) {
        const p = makePlace(place);
        row.appendChild(p);
    }

    return row;
}

function makeLabel(_class, text) {
    const label = document.createElement('div');
    label.classList.add(_class);
    label.classList.add('label');
    label.innerText = text;

    return label;
}

function makeLevel(data) {
    const level = document.createElement('div');
    level.classList.add('level');

    for (let i = 0; i < data.length; i++) {
        const row = data[i];
        level.appendChild(makeLabel('row-name', `row ${i + 1}`));
        level.appendChild(makeRow(row));
    }

    return level;
}

function makeQueuePlace(data, i) {
    const place = document.createElement('div');
    place.classList.add('queue-place');
    if (!data) {
        place.classList.add('free');
        return place;
    }

    switch (data["type"]) {
        case "auto":
            place.classList.add('auto');
            break;
        case "bus":
            place.classList.add('bus');
            break;
        case "moto":
            place.classList.add('moto');
            break;
        default:
            place.classList.add('free');
            break;
    }

    place.innerText = "Pl. " + ++i;

    return place;
}
