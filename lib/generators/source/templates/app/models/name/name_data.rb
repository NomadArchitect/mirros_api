module <%= name.camelcase %>

  # TODO: you need to lookup the right GroupSchema and make this class inherit from it
  class <%= name.camelcase %>Data < ::GroupSchemas::<%= name.camelcase %>Schema
  end

end
