require 'singleton'
require 'parseconfig'

module FP
  class Config
    include Singleton
    CONF_PATH = '/opt/nicescale/support/etc/nicescale.conf'
    
    def initialize
      @conf = ParseConfig.new(CONF_PATH)
    end

    def method_missing(m, *args)
      if @conf[m.to_s]
        get(m.to_s)
      else
        super
      end
    end
    
    def get(name, default=nil)
      val = @conf[name]
      val = default.to_s if (val.nil? and !default.nil?)
      val.gsub!(/\\:/,":") if not val.nil?
      val.gsub!(/[ \t]*#[^\n]*/,"") if not val.nil?
      val = val[1..-2] if not val.nil? and val.start_with? "\""
      val = val[1..-2] if not val.nil? and val.start_with? "\'"
      val
    end

  end
end
