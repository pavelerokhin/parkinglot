class ParkingQueue

  attr_reader :queue, :max_size
  def initialize(max_size)
    @queue = []
    @max_size = max_size

    @logger = Logger.new(STDOUT, progname: 'queue')
    @mutex = Mutex.new
  end

  def push(vehicle)
    @mutex.synchronize do
      if vehicle.nil?
        return true
      end

      @queue.append(vehicle)

      if @queue.size == @max_size
        @logger.info("#{RED}QUEUE IS FULL. No more vehicles from the outside world are allowed.#{RESET}")
        return false # Queue is full, cannot push more elements
      end

      @logger.info("#{vehicle.type} has been refused and pushed is in the queue #{MAGENTA}(size: #{@queue.size})#{RESET}") if @queue.size > 1

      true # Element successfully pushed to the queue
    end
  end

  def pop
    @mutex.synchronize do
      @queue.empty? ? nil : @queue.shift
    end
  end

  def snapshot
    @mutex.synchronize do
      {
        'queue': @queue.empty? ? nil : @queue.map { |v| v.snapshot  },
        'size': @queue.size,
        'max_size': @max_size,
      }
      end
    end
end
