require 'bundler/cli'
require 'bundler/cli/show'

class TemplatesController < ApplicationController

  def show
    extension = params[:extension]
    application = params[:application]
    extension_path = Bundler::CLI::Show.new({}, extension).run

    if extension_path
      file_path = "#{extension_path}/app/assets/#{extension}-#{application}.vue"
      send_file(file_path)

    else
      head :not_found
    end

  end
end
