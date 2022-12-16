# frozen_string_literal: true

# Base class for file uploads. Inherit from this class to scope uploads by
# controller name.
# TODO: Render keys in camelCase
class UploadsController < ApplicationController
  # include JSONAPI::ActsAsResourceController
  before_action :set_upload_type, :set_host

  rescue_from StandardError, with: :render_error

  def index
    render json: @type.all, methods: %i[file_url content_type filename]
  end

  def create
    render json: @type.create!(upload_params),
           methods: %i[file_url content_type filename],
           status: :created
  end

  def show
    render json: @type.find(params[:id]),
           methods: %i[file_url content_type filename]
  end

  def update
    render json: @type.find(params[:id]).update(upload_params),
           methods: %i[file_url content_type filename]
  end

  def destroy
    @type.find(params[:id]).purge_and_destroy
  end

  private

  def upload_params
    params.require(:upload).permit(:file).merge(type: @type)
  end

  def set_upload_type
    @type = controller_path.classify.safe_constantize ||= Upload
  end

  def set_host
    ActiveStorage::Current.host = request.base_url
  end

  # Renders a generic exception as JSON with status code 422.
  # @param [Exception] exception The exception object raised during operations.
  def render_error(exception)
    render json: exception, status: :unprocessable_entity
  end
end
