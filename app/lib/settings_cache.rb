# frozen_string_literal: true

class SettingsCache
  def initialize
    @cache = {}
    Setting.all.each do |setting|
      @cache[setting.slug.to_sym] = setting.value
    end
  end

  def self.singleton
    @singleton ||= new
  end

  #noinspection RubyClassMethodNamingConvention
  def self.s
    singleton
  end

  def [](key)
    @cache[key]
  end

  def []=(key, value)
    @cache[key] = value
  end

  def using_wifi?
    @cache[:network_connectiontype].eql? 'wlan'
  end

  def using_lan?
    @cache[:network_connectiontype].eql? 'lan'
  end
end
