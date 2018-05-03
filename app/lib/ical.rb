module Ical
  class Engine

    REFRESH_INTERVAL = '5m'.freeze

    # @return [String]
    def self.refresh_interval
      REFRESH_INTERVAL
    end

# @param [Hash] configuration
# @param [Hash] subresources
    def initialize(configuration, subresources = {})
      @username = configuration['user']
      @password = configuration['password']
      @url = configuration['url']
      @ical = CalendarTest.new(@url)
    end

    def config_valid?
      # Public calendars do not need credentials.
      res = HTTParty.head(@url)
      true unless res.code != 200
    end

    def list_subresources
      @ical.calendars
    end

    def fetch_data(subresources)
      map = Hash.new
      subresources.each do |subresource|
        map[subresource] = @ical.events(subresource)
      end
      return map
    end
  end

  class CalendarTest
    def initialize(url)
      @cal_map = Hash.new
      content = HTTParty.get(url)
      Icalendar::Parser.new(content).parse.map do |cal|
        calendar_name = cal.x_wr_calname.empty? ? cal.name : cal.x_wr_calname.first.value
        @cal_map[calendar_name] = cal
      end
    end

    def calendars
      @cal_map.keys
    end

    def events(calendar)
      subset = @cal_map[calendar].events.select do |event|
        event.dtstart >= Date.today && event.dtstart <= Date.today + 14
      end

      unless subset.empty?
        event_hashes = subset.map do |event|
          {
            dtstart: event.dtstart.value,
            dtend: event.dtend.value,
            summary: event.summary.value,
            description: event.description.value
          }
        end
        event_hashes
      end
    end
  end

end
