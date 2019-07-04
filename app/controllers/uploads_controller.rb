class UploadsController < ApplicationController
  # include JSONAPI::ActsAsResourceController
  def index
    render json: Upload.all, methods: :file_url
  end

  def create
    render json: Upload.create!(upload_params), methods: :file_url, status: 201
  end

  def show
    render json: Upload.find(params[:id]), methods: :file_url
  end

  def update
    render json: Upload.find(params[:id]).update(upload_params), methods: :file_url
  end

  def destroy
    Upload.find(params[:id]).purge_and_destroy
  end

  private

  def upload_params
    params.require(:upload).permit(:file)
  end

end
