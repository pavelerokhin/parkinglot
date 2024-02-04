# frozen_string_literal: true

require 'logger'

require_relative 'cashier'
require_relative 'parking_receipt'
require_relative 'vehicle'


class Parking < Cashier

  attr_accessor :parking_space, :money, :out_times, :mutex

  def initialize(levels, rows_in_level, places_in_row)
    validate(levels, rows_in_level, places_in_row)
    @parking_space = Array.new(levels) { Array.new(rows_in_level) { Array.new(places_in_row) } }
    @money = 0
    @out_times = []

    @mutex = Mutex.new
    @logger = Logger.new(STDOUT, progname: 'parking')
  end

  def park_or_refuse(vehicle)
    if vehicle.nil?
      return nil
    end
    parking_place = find_parking_place(vehicle.size)
    if parking_place.nil?
      return refuse(vehicle)
    end

    # park
    vehicle.cashier = self
    park(vehicle, parking_place)
    nil
  end

  def pay_and_exit(vehicle)
    @mutex.synchronize do
      @money += vehicle.receipt.how_much_to_pay
      @out_times << vehicle.receipt.out_time
      clear_parking_space(vehicle)
      @logger.info("#{YELLOW}#{vehicle.type} left after #{vehicle.receipt.parking_hours} hours. Money until now: #{@money}#{RESET}")
    end
  end

  def snapshot
    @mutex.synchronize do
      {
        'parking_space': @parking_space,
        'money': @money,
        'vehicles': @out_times.length,
        'levels': @parking_space.length,
        'levels_saturation': parking_space_levels_saturation,
        'rows_in_level': @parking_space[0].length,
        'places_in_row': @parking_space[0][0].length,
      }
    end
  end

  private

  def validate(levels, rows_in_level, places_in_row)
    raise ArgumentError, "#{RED}Not a valid parking size, should be a triple of positive integers#{RESET}" \
      if [levels, rows_in_level, places_in_row].any? { |val| val < 1 and !val.is_a?(Integer) }
  end

  def find_parking_place(vehicle_size)
    parking_size = 0

    @mutex.synchronize do
      @parking_space.each_with_index do |level, level_index|
        level.each_with_index do |row, row_index|
          row.each_with_index do |place, place_index|
            place.nil? ? parking_size += 1 : parking_size = 0
            return [level_index, row_index, place_index, parking_size] if parking_size == vehicle_size
          end
          parking_size = 0
        end
      end
    end
    nil
  end

  def park(vehicle, parking_place)
    vehicle.park(parking_place)
    occupy_parking_space(vehicle)
    @logger.info("#{GREEN}#{vehicle.type} is parked at level #{parking_place[0]}, row #{parking_place[1]}, place #{parking_place[2]}-#{parking_place[2] + vehicle.size}, vehicle size #{vehicle.size}#{RESET}")
  end

  def refuse(vehicle)
    @logger.info("there are no place for a #{vehicle.type}")
    vehicle
  end

  def occupy_parking_space(vehicle)
    @mutex.synchronize do
      sleep(0.2)
      vehicle.receipt.parking_place.last.times do |i|
        @parking_space[vehicle.receipt.parking_place[0]][vehicle.receipt.parking_place[1]][vehicle.receipt.parking_place[2] - i] = vehicle.id
      end
      sleep(0.2)
    end
  end

  def clear_parking_space(vehicle)
      vehicle.receipt.parking_place.last.times do |i|
        @parking_space[vehicle.receipt.parking_place[0]][vehicle.receipt.parking_place[1]][vehicle.receipt.parking_place[2] - i] = nil
      end
  end

  def parking_space_levels_saturation
    @parking_space.map do |level|
      occupied_spaces = level.flatten.count { |place| !place.nil? }
      total_spaces = level.flatten.size
      saturation = (occupied_spaces.to_f / total_spaces) * 100
      saturation.round(2)
    end
  end
end
