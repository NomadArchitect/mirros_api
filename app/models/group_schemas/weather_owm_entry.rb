module GroupSchemas
  class WeatherOwmEntry < ApplicationRecord
    belongs_to :weather_owm

    def serializable_hash(options = nil)
      base = super({ except: %i[id weather_owm_id dt_txt] }.merge(options || {}))
      base.merge(
        dt_txt: dt_txt&.iso8601
      )
    end
  end
end
