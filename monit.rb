require 'logger'
class Monit
  attr_accessor :logfile, :log
  attr_accessor :sites_enabled, :sites_changed, :sites_updated_cache
  attr_accessor :intervals
  
  
  def initialize(&block)  
    yield self if block_given?
    init_log
    self
    setup_db
    
    loop do
      if File.exist? "#{RAILS_ROOT}/tmp/sites_updated.txt"
        @log.info "[initialize] Sites table updated"
        setup_db
        File.delete "#{RAILS_ROOT}/tmp/sites_updated.txt"
      end
      check_sites
      sleep @intervals
    end
  end
  
  def init_log
    @log = Logger.new('log/monitor.log')
    ActiveRecord::Base.logger = @log 
  end
  

  def setup_db
    @sites_enabled = {}
    @sites_updated_cache = {}
    @sites_enabled = Site.all(:include => :snapshots)
  end
  
  # This will check if the sites have changed.
  def check_sites
    @sites_changed = []
    @sites_changed.replace @sites_enabled
  
    # loop through all the enabled sites to find changes
    @sites_enabled.each do |site|
      
      old_checksum = ""
      old_checksum = site.snapshots.last.checksum if site.snapshots.size > 0
      @log.info "[check_sites] Checksum for  #{site.name} is #{old_checksum}"
      
      # Grab the latest checksum from the site
      checksum = %x(curl -s #{site.url} | md5).chomp
    
      # Compare the checksum with the lastest on record
      if checksum != old_checksum
        
        # Since it didn't match, see if we have seen it in the past
        existing_cs_results = has_past_usage(checksum)
        if existing_cs_results
          existing_cs_results.update_attribute(:updated_at, Time.now)
          # We have seen this change in the past
          #existing_cs_results.alert_sent = false
          sites_changed.delete site
        else
          
          # This is a brand new change to the site. We need to record it.
          @log.info "[check_sites] new: #{checksum}  old:#{old_checksum}"
          site.snapshots.build(:checksum => checksum, :alert_sent => false)
          site.save!
        end
        
      else
        
        # No changes, all is well.
        sites_changed.delete site
      end 
    end 
    send_alert if sites_changed.size > 0  
  end
    
  #returns array
  def has_past_usage(checksum)
    # check cache here
    Snapshot.find_by_checksum checksum
  end
    
  def send_alert
    @log.info "[send_alert] #{@sites_changed.inspect}"
    %x(curl -s http://shorts.local/snapshots/grab_screenshots)
  end
end
