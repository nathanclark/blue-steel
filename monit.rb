require 'logger'
class Monit
  attr_accessor :logfile, :log
  attr_accessor :sites_enabled, :sites_changed
  attr_accessor :intervals
  
  
  def initialize(&block)  
    yield self if block_given?
    init_log
    self
    setup_db
    loop do
      check_sites
      puts "1"
      sleep @intervals
    end
  end
  
  def init_log
    @log = Logger.new('log/monitor.log')
    ActiveRecord::Base.logger = @log 
  end
  

  def setup_db
    # connect to the database (sqlite in this case)
    ActiveRecord::Base.establish_connection({
                                              :adapter => "mysql",
                                              :database =>  "shorts_development",
                                              :username => "root",
                                              :password => "",
                                              :host => "localhost"
                                            })
    @sites_enabled = {}
    @sites_enabled = Site.all(:include => :snapshots)
  end
  
  # This will check if the sites have changed.
  def check_sites
    @sites_changed = []
    @sites_changed.replace @sites_enabled
  
    @sites_enabled.each do |site|
      old_checksum = ""
      old_checksum = site.snapshots.last.checksum if site.snapshots.size > 0
      @log.info "[check_sites] Checking #{site.name}"
      @log.info "[check_sites] Checksum for  #{site.name} is #{old_checksum}"
      checksum = %x(curl -s #{site.url} | md5).chomp
    
      if checksum != old_checksum 
        @log.info "[check_sites] new: #{checksum}  old:#{old_checksum}"
        site.snapshots.build(:checksum => checksum, :alert_sent => false)
        site.save!
      else
        @log.info "[check_sites] MATCH: #{checksum}  old:#{old_checksum}"
        sites_changed.delete site
      end 
    end 
    send_alert if sites_changed.size > 0  
  end
    
  
  def send_alert
    @log.info "[send_alert] #{@sites_changed.inspect}"
    %x(curl -s http://shorts.local/snapshots/grab_screenshots)
  end

end