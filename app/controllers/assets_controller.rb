# frozen_string_literal: true

class AssetsController < ApplicationController
  def show
    # TODO: Remove fallback once all extensions are migrated to namespaces
    gem = Gem.loaded_specs["mirros-#{params[:extension_type].singularize}-#{params[:extension]}"] || Gem.loaded_specs[params[:extension]]
    return head :not_found if gem.nil?

    if params[:version]
      return head :not_found unless gem.version.to_s.eql?(params[:version])
    end

    extension_path = gem.full_gem_path
    file_path = "#{extension_path}/app/assets/#{params[:asset_type]}/#{params[:file]}"

    return head :not_found unless Pathname.new(file_path).exist?

    if request.head?
      head :ok
    else
      expires_in 1.month, public: true
      send_file(file_path)
    end
  end
end
