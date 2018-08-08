class TemplatesController < ApplicationController

  def show
    gem = Gem.loaded_specs[params[:extension]]
    return head :not_found if gem.nil?

    extension_path = gem.full_gem_path
    file_path = "#{extension_path}/app/assets/#{params[:application]}.vue"

    if Pathname.new(file_path).exist?
      send_file(file_path)
    else
      head :not_found
    end

  end
end
