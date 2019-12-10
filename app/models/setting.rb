class Setting < ApplicationRecord
  self.primary_key = 'slug'
  validates :slug, uniqueness: true
  validates_each :value do |record, attr, value|
    # TODO: Can this be extracted to handle special cases for different entries in a more elegant way?
    if record.slug.eql?('system_timezone')
      if ActiveSupport::TimeZone[value.to_s].nil?
        record.errors.add(
          attr,
          "#{value} is not a valid timezone!"
        )
      end
    elsif record.slug.match?(/system_backgroundcolor|system_fontcolor/)
      unless value.match?(/^#[0-9A-F]{6}$/i)
        record.errors.add(
          attr,
          "#{value} is not a valid CSS color!"
        )
      end
    else
      opts = record.options
      unless opts.key?(value) || opts.empty?
        record.errors.add(
          attr,
          "#{value} is not a valid option for #{attr}, options are: #{opts.keys}"
        )
      end
    end
  end

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  before_update :apply_setting, if: :auto_applicable?
  after_update :update_cache, :check_setup_status

  def category_and_key
    "#{category}_#{key}"
  end

  # Gets a hash of available options for a setting, if defined.
  # @return [ActiveSupport::HashWithIndifferentAccess] Hash of options for this setting.
  def options
    # FIXME: Maybe cleaner to extract?
    if slug.eql? 'system_timezone'
      ActiveSupport::TimeZone.all.map { |tz| {id: tz.tzinfo.identifier, name: tz.to_s} }
    else
      options_file = File.read("#{Rails.root}/app/lib/setting_options.yml")
      # TODO: If we require Ruby logic in the YAML file, use ERB.new(options_file).result instead of options_file
      o = YAML.safe_load(options_file).with_indifferent_access[slug.to_sym]
      o.nil? ? {} : o
    end
  end

  def check_setup_status
    StateCache.refresh_setup_complete System.setup_completed?
  end

  def update_cache
    SettingsCache.s[slug.to_sym] = value
  end

  def auto_applicable?
    [:system_timezone].include?(slug.to_sym)
  end

  def apply_setting
    executor = "SettingExecution::#{category.capitalize}".safe_constantize
    executor.send(key, value) if executor.respond_to?(key)
  end

end
