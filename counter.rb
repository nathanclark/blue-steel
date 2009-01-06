require 'daemon'
require 'logger'
require 'monit'
require 'enviroment'
class Counter < Daemon::Base
  def self.start
    @log = Logger.new('log/monitor.log')
    @log.info "Starting up"
    Monit.new do |m|
        m.intervals = 60
    end
  end

  def self.stop
     @log = Logger.new('log/monitor.log')
     @log.info "Shutting down"
  end
end

Counter.daemonize