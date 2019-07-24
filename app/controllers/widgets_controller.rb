# Controller for Widget actions.
class WidgetsController < ApplicationController
  include JSONAPI::ActsAsResourceController

  def update
    Widget.find(params[:id]).widget_instances.each(&:destroy) if params[:data][:attributes][:active].eql? false
    super
  end
end
