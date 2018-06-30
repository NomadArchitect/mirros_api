class SettingOptions

  def self.get_options_yaml
    options_file = File.read("#{Rails.root}/app/lib/setting_options.yml")
    settings = YAML.load(ERB.new(options_file).result).with_indifferent_access[:setting_options]
    to_set = [:system_language]

    to_set.each do |key|
      settings[key] = SettingOptions.send(key)
    end

    settings
  end

  def self.system_language
    default = [{ de_DE: I18n.t("Deutsch") }, { en_GB: I18n.t("English")} ]
    from_db = [{ fr_FR: I18n.t("Français") }]

    (default + from_db).uniq
  end

end
