# Controller for Widget actions.
class WidgetsController < ApplicationController
  include JSONAPI::ActsAsResourceController
  before_action :set_widget, only: %i[update destroy]

  # POST /widgets
  def create
    return unless verify_content_type_header

    attributes = params[:data][:attributes]
    @widget = Widget.new
    @widget.install(attributes[:name], attributes[:version])

    process_request
  end

  # PATCH/PUT /widgets/1
  def update
    render plain: update
  end

  # DELETE /widgets/1
  def destroy

    # TODO: RecordNotFound errors need to be handled.
  rescue ActiveRecord::RecordNotFound
    render json: render_errors('TODO')

    if @widget.uninstall(@widget.name)
      process_request
    else
      render_errors('widget not found')
    end
  end


  private

  def set_widget
    @widget = Widget.find(params[:id])
  end

end
