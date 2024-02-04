# frozen_string_literal: true


class ParkingSnapshotHandler
  def initialize(server, parking_1_queue)
    @server = server
    @parking_1_queue = parking_1_queue
    @recv_size = 1024
  end

  def listen_and_serve
      handle(@server.server.accept)
  end

  def handle(socket)
    @driver = ::WebSocket::Driver.server(socket, protocols: ['websocket'])

    Thread.new do
      setup_driver_handlers(@driver)

      @driver.start
      loop do
        sleep(1)
        @driver.text(snapshot.to_json)
        break if quit?
      end

      @driver.close
    end

    Thread.new do
      process_socket_data(socket, @driver)
    end
  end

  def snapshot
    @parking_1_queue.snapshot
  end

  private

  def setup_driver_handlers(driver)
    driver.on(:connect) { driver.start }
    driver.on(:message) { |event| driver.text(listen_and_serve) }
    driver.on(:close) { |event| handle_close_event(event) }
  end

  def handle_close_event(event)
    @logger.info("gui server finished listening on #{@port}, after #{Time.now-@t0}s")
    driver = event.instance_variable_get(:@driver)
    socket = driver.instance_variable_get(:@socket)

    connection_msg = "Connection #{socket ? "with #{socket.addr[2]}" : ''} closed. Code: #{event.code}, Reason: #{event.reason}"

    @logger.info(connection_msg)
  end

  def process_socket_data(socket, driver)
    loop do
      begin
        IO.select([socket], [], [], 30) or raise Errno::EWOULDBLOCK
        data = socket.recv(@recv_size)
        break if data.empty?
        driver.parse(data)
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN
        # Resource temporarily unavailable, continue the loop
        next
      rescue Errno::ECONNRESET
        @logger.error("Connection reset by the client")
        break # exit the loop or add your logic for handling the reset
      end
    end
  end
end