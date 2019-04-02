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

  def self.s
    singleton
  end

  def [](key)
    @cache[key]
  end

  def []=(key, value)
    @cache[key] = value
  end
end
