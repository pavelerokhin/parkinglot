# frozen_string_literal: true


require 'securerandom'

require_relative 'parking_receipt'

class Vehicle
  attr_accessor :cashier
  attr_reader :id, :type, :size, :receipt

  def initialize(leave_parking_hours_distribution)
    @id = self.class.next_id
    @state = :in_queue
    @receipt = ParkingReceipt.new
    @leave_parking_hours_distribution = leave_parking_hours_distribution
  end

  def park(parking_place, in_time = Time.now)
    @state = :parked
    receipt.in_time = in_time
    receipt.parking_place = parking_place
    receipt.parking_hours = rand(@leave_parking_hours_distribution).round(2)

    Thread.new do
      sleep receipt.parking_hours
      pay_and_exit
    end
  end

  def pay_and_exit(out_time = Time.now)
    @state = :out
    receipt.out_time = out_time
    cashier.pay_and_exit(self)
  end

  def self.next_id
    @last_id ||= 0
    @last_id += 1
  end

  def snapshot
    {
      'id': @id,
      'type': @type,
      'size': @size,
      'state': @state,
    }
  end
end

class Moto < Vehicle
  def initialize(leave_parking_hours_distribution)
    super(leave_parking_hours_distribution)
    @id = "moto-#{@id}"
    @type = :moto
    @size = 1
    receipt.price = 1
  end
end

class Auto < Vehicle
    def initialize(leave_parking_hours_distribution)
      super(leave_parking_hours_distribution)
      @id = "auto-#{@id}"
      @type = :auto
      @size = 4
      receipt.price = 2
    end
end

class Bus < Vehicle
  def initialize(leave_parking_hours_distribution)
    super(leave_parking_hours_distribution)
    @id = "bus-#{@id}"
    @type = :bus
    @size = 8
    receipt.price = 4
  end
end

def random_type_vehicle_or_nothing(leave_parking_hours_distribution)
  if rand(0..1) == 0
    nil
  else
    random_type_vehicle(leave_parking_hours_distribution)
  end
end

def random_type_vehicle(leave_parking_hours_distribution)
  [Moto, Auto, Bus].sample.new(leave_parking_hours_distribution)
end

