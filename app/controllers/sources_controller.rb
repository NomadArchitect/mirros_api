class SourcesController < ApplicationController
  include JSONAPI::ActsAsResourceController

  def update
    if params.dig(:data, :attributes, :active).eql?(false)
      Source.find(params[:id]).source_instances.each(&:destroy)
    end
    super
  end
end
