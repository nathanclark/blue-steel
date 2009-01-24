require 'logger'
require 'rubygems'
require 'active_record'

class Monitor
  attr_accessor :logfile, :log
  attr_accessor :sites_enabled, :sites_changed
  attr_accessor :intervals
  
  
  def initialize(&block)  
    yield self if block_given?
    init_log
    self
    
    # Kick off the monitoring process
    # begin
      # fork do

        setup_db
        loop do
     
          # Work here
          @log.info "Checking sites."
          check_sites
          sleep @intervals
         
        end
       
      # end
    # rescue ActiveRecord::StatementInvalid => e
    #   if e.to_s =~ /away/
    #      ActiveRecord::Base.establish_connection and retry
    #   else
    #     raise e
    #   end
    end
  end
  
  def init_log
    @log = Logger.new('log/monitor.log')
    ActiveRecord::Base.logger = @log 
  end
  

  def setup_db
    # connect to the database (sqlite in this case)
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
  
  




class Site < ActiveRecord::Base
  has_many :snapshots
end

class Snapshot < ActiveRecord::Base
  belongs_to :site
  attr_accessor :new_checksum
end

