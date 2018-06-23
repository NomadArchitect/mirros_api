class SettingOptions

  def self.getOptionsForSetting(combined_key)
    options_map = {
      :display_orientation =>  ['1', '2', '3', '4']
    }
    options_map[combined_key.to_sym]
  end
end
