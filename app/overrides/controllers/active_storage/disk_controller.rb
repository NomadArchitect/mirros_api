# frozen_string_literal: true

load ActiveStorage::Engine.root.join('app/controllers/active_storage/disk_controller.rb')

ActiveStorage::DiskController.class_eval do
  def show
    if (key = decode_verified_key)
      expires_in 1.year, public: true
      serve_file disk_service.path_for(key[:key]), content_type: key[:content_type], disposition: key[:disposition]
    else
      head :not_found
    end
  rescue Errno::ENOENT
    head :not_found
  end
end
