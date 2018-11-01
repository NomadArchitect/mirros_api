class AssetsController < ApplicationController

  def show
    gem = Gem.loaded_specs[params[:extension]]
    return head :not_found if gem.nil?

    extension_path = gem.full_gem_path
    file_path = "#{extension_path}/app/assets/#{params[:type]}/#{params[:file]}"

    return head :not_found unless Pathname.new(file_path).exist?

    if request.head?
      head :ok
    else
      send_file(file_path)
    end
  end
end
