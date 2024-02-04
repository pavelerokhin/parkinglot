# frozen_string_literal: true

require 'json'
require 'socket'
require 'websocket/driver'

require_relative 'parking_snapshot_handler'


class GuiServer
  attr_reader :server, :logger, :gui_path

  def initialize(parking_1_queue, port = nil, gui_path = './gui/frontend/index.html')
    @host = "0.0.0.0"
    @gui_path = gui_path

    @logger = Logger.new(STDOUT, progname: 'gui')
    @server = start_server(port)
    @handler = ParkingSnapshotHandler.new(self, parking_1_queue)
  end

  def open_browser
    @gui_path = File.expand_path('./gui/frontend/index.html')
    system("open -a 'Google Chrome' #{@gui_path}")
    @logger.info("#{GREEN}GUI opened in Google Chrome: #{@gui_path}#{RESET}")
  end

  def listen_and_serve
    @handler.listen_and_serve
  end

  private

  def start_server(port)
    ::TCPServer.open(port || 0)
  end
end

