require '<%= name.downcase %>/engine'
require '<%= name.downcase %>/fetcher'
require 'httparty'

module <%= name.camelcase %>
  class Hooks
    REFRESH_INTERVAL = '5m'.freeze

    # @return [String]
    def self.refresh_interval
      REFRESH_INTERVAL
    end

    # @param [Hash] configuration
    def initialize(instance_id, configuration)
      @instance_id = instance_id
      <%- fields.each do |key, type| -%>
      @<%= key %> = configuration['<%= key %>']
      <%- end -%>
      @fetcher = Fetcher.new(@url)
    end

    def default_title
      "<%= name.capitalize %>"
    end

    def configuration_valid?
      # TODO: Add credential validation if present.
      res = HTTParty.head(@url)
      res.success?
    rescue ArgumentError
      false
    end

    def list_sub_resources
      []
    end

    def fetch_data(group, sub_resources)
      records = []
      # Fetch the data
      records
    end

  end
end
