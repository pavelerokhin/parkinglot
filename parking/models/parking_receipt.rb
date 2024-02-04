# frozen_string_literal: true

class ParkingReceipt
  attr_accessor :parking_place, :parking_hours, :price, :in_time, :out_time

  def how_much_to_pay
    (parking_hours * price).round(2)
  end

  def snapshot
    {
      'parking_place': @parking_place,
      'parking_hours': @parking_hours,
      'price': @price,
      'in_time': @in_time,
      'out_time': @out_time,
    }
  end
end
