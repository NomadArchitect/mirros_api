class ExtensionParser
  # @return [String] the gem's name
  attr_reader :gem_name
  # @return [String] the extension's name without the namespace; used in the database.
  attr_reader :internal_name
  # @return [Widget, DataSource] the mirr.OS extension class
  attr_reader :extension_class

  # @param [Gem::Specification] spec
  # @raise [JSON::JSONError] if the spec's metadata JSON cannot be parsed
  # @raise [NameError] if no class constant was found for the extension type
  def initialize(spec)
    @spec = spec
    @gem_name = spec.name
    @internal_name = spec.name.split('-').last
    @meta = JSON.parse(@spec.metadata['json'], symbolize_names: true)
    @type = @meta[:type].to_sym
    @extension_class = @type.to_s.singularize.classify.constantize
  end

  # @return [TrueClass, FalseClass] whether the metadata is valid.
  def meta_valid?
    case @type
    when :widgets
      true
    when :sources
      @meta[:groups].present?
    else
      false
    end
  end

  # Assembles the extension's type model attributes from the gemspec.
  # @return [Hash] attributes for the extension's type model.
  def extension_attributes
      # FIXME: We can probably get rid of the icon and download properties.
      type_specifics = if @type.equal? :widgets
                         attrs = {
                           icon: "http://server.tld/icons/#{@spec.name}.svg",
                           sizes: @meta[:sizes],
                           languages: @meta[:languages],
                           single_source: @meta[:single_source]
                         }
                         if @meta[:group].nil?
                           attrs
                         else
                           attrs.merge(group_id: Group.find_by(name: @meta[:group]))
                         end
                       else
                         {
                           groups: @meta[:groups].map { |g| Group.find_by(name: g) }
                         }
                       end
      {
        name: @internal_name,
        title: @meta[:title],
        description: @meta[:description],
        version: @spec.version.to_s,
        creator: @spec.author,
        homepage: @spec.homepage,
        download: 'http://my-gemserver.local',
        active: true
      }.merge(type_specifics)
  end

end
