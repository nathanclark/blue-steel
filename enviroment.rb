# connect to the database (sqlite in this case)
require 'rubygems'
require 'active_record'
ActiveRecord::Base.establish_connection({
                                          :adapter => "mysql",
                                          :database =>  "shorts_development",
                                          :username => "root",
                                          :password => "",
                                          :host => "localhost"
                                        })

class Site < ActiveRecord::Base
  has_many :snapshots
end

class Snapshot < ActiveRecord::Base
  belongs_to :site
  attr_accessor :new_checksum
end

  
