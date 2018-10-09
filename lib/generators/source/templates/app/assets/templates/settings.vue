<%- mapping = { string: "text", int: "number", integer: "number", default: "string" } -%>
<template>
  <div>
    <%- fields.each do |key, type| -%>
    <label for="<%= key %>"">{{ t("<%= name %> <%= key %>") }}</label>
    <input type="<% unless mapping[type.to_sym].nil? %><%= mapping[type.to_sym] %><% else %><%= mapping[:default] %><% end %>" id="<%= key %>" name="<%= key %>" :value="conf.<%= key %>">
    <%- end -%>
  </div>
</template>

<script>
module.exports = {
  name: "<%= name.downcase %>",
  props: {
    currentSettings: {
      type: Object,
      required: true
    }
  },
  data: function() {
    return {
      defaults: {
        <%- fields.each do |key, type| -%>
        <%= key %>: ""<% if fields.to_a.last.last != key %>,<%end %>
        <%- end -%>
      },
      urlRequiresAuth: false
    };
  },
  computed: {
    conf: function() {
      return { ...this.defaults, ...this.currentSettings };
    }
  },
  locales: {
    deDe: {
      "<%= name %> title": "<%= name.capitalize %>",
      "<%= name %> description": "<%= name.capitalize %> Beschreibung"<% if fields.to_a.any? %>,<% end %>
      <%- fields.each do |key, type| -%>
      "<%= name %> <%= key %>": "<%= name.capitalize %> <%= key %>"<% if fields.to_a.last.last != key %>,<%end %>
      <%- end -%>
    }
  }
};
</script>
