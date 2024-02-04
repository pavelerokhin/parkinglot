# frozen_string_literal: true

require_relative './models/parking'
require_relative './models/parking_queue'
require_relative './models/vehicle'
require_relative './utils'


class Parking1Queue
  def initialize(levels,
                 rows_in_level,
                 places_in_row,
                 queue_max_size,
                 vehicles_arrive_hours_distribution,
                 leave_parking_hours_distribution)
    @logger = Logger.new(STDOUT, progname: 'model')

    @vehicles_arrive_hours_distribution = vehicles_arrive_hours_distribution
    @leave_parking_hours_distribution = leave_parking_hours_distribution

    @parking_1_queue = Parking.new(levels, rows_in_level, places_in_row)
    @queue = ParkingQueue.new(queue_max_size)

    @logger.info("#{GREEN}parking with one queue is ready#{RESET}")
  end

  def run
    loop do
      # vehicles coming from the outside world and enter the queue
      unless @queue.push(random_type_vehicle_or_nothing(@leave_parking_hours_distribution))
        break
      end
      vehicle = @queue.pop

      refused = @parking_1_queue.park_or_refuse(vehicle)
      @queue.push(refused)

      @logger.info("#{RED}quit simulation with Q pressed#{RESET}") && break if quit?

      wait_for_next_vehicle = rand(@vehicles_arrive_hours_distribution)
      sleep wait_for_next_vehicle
      @logger.info("next time iteration of the outside world in #{wait_for_next_vehicle.round(2)} hours")
    end

    sleep(2) # wait while the browser is opening
    display_statistics
  end

  def snapshot
    {
      'time': Time.now,
      'parking': @parking_1_queue.snapshot,
      'queue': @queue.snapshot,
    }
  end

  private

  def display_statistics
    @logger.info("#{LIGHT_YELLOW}*******************************")
    @logger.info(" - Total money: #{@parking_1_queue.money}")
    @logger.info(" - Vehicles served: #{@parking_1_queue.out_times.length}")
    @logger.info("*******************************#{RESET}")

  end
end
