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
  name: "<%= name.underscore %>",
  props: {
    currentSettings: {
      type: Object,
      required: true
    },
    locale: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      defaults: {
        <%- fields.each do |key, type| -%>
        <%= key %>: ""<% if fields.to_a.last.last != key %>,<%end %>
        <%- end -%>
      }
    };
  },
  computed: {
    conf: function() {
      return { ...this.defaults, ...this.currentSettings };
    }
  },
  locales: {
    deDe: {
      "<%= name %> title": "<%= name.camelcase %>",
      "<%= name %> description": "<%= name.camelcase %> Beschreibung"<% if fields.to_a.any? %>,<% end %>
      <%- fields.each do |key, type| -%>
      "<%= name %> <%= key %>": "<%= name.camelcase %> <%= key %>"<% if fields.to_a.last.last != key %>,<%end %>
      <%- end -%>
    }
  }
};
</script>
<style scoped>
  /* your styles here */
</style>
