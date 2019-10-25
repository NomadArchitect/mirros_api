class UploadsController < ApplicationController
  # include JSONAPI::ActsAsResourceController
  before_action :set_upload_type, :set_host

  def index
    render json: @type.all, methods: %i[file_url content_type]
  end

  def create
    render json: @type.create!(upload_params),
           methods: %i[file_url content_type],
           status: :created
  end

  def show
    render json: @type.find(params[:id]),
           methods: %i[file_url content_type]
  end

  def update
    render json: @type.find(params[:id]).update(upload_params),
           methods: %i[file_url content_type]
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

end
