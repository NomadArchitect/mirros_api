class SourcesController < ApplicationController
  include JSONAPI::ActsAsResourceController

  def update
    Source.find(params[:id]).source_instances.each(&:destroy) if params[:data][:attributes][:active].eql? false
    super
  end
end
