# Parking Lot

This is a parking lot model, designed in Ruby with no frameworks. It includes a backend of the model and a GUI, which are connected by a websocket. 
The model has a 3D parking space and a queue. There are three types of vehicles that can arrive from the outside world: motorcycles, cars, and buses. They occupy different spaces and pay different prices. Vehicles leave the parking lot asynchronously after a random time. The time distributions of arriving to the queue and leaving the parking lot vehicles are uniform.

The GUI displays parking levels and the queue. It includes two plots: a line chart showing the completeness of the queue and a phase diagram of the saturation of the first two parking lot levels. It displays also the following measures: time, money gained until the present moment, number of served vehicles. 

User can set the following parameters: 
- `levels`: number of levels of the parking lot,
- `rows_in_level`: number of rows in the parking lot's level
- `places_in_row`: number of places in a row; 
- `queue_max_size`: maximun queue capacity;
- `vehicles_arrive_hours_distribution`: 
- `leave_parking_hours_distribution`: 


## Installation

To run the model:

```bash
ruby main.rb
```
The GUI should run automatically in Google Chrome. If not, open `./gui/frontend/index.html`.