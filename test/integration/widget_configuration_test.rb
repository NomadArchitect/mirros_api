require 'test_helper'

class WidgetConfigurationTest < ActionDispatch::IntegrationTest
   test "widgets implement a configuration class" do
     widgets = Bundler.load
            .current_dependencies
            .select { |dep| dep.groups.include?(:widget) }
            .map(&:name)

     widgets.each do |widget|
      assert "#{widget.classify}::Configuration".constantize.present?
     end
   end
end
