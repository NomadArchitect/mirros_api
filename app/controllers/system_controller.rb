class SystemController < ApplicationController

  def status
    render json: { meta: System.info }
  end

  def setting_execution
    executor = "SettingExecution::#{params[:category].capitalize}".safe_constantize
    if executor.respond_to?(params[:command])
      begin
        result = executor.send(params[:command])
        success = true
      rescue NotImplementedError, Terrapin::ExitStatusError => e
        result = e.message
        success = false
      end
    else
      result = "#{params[:action]} is not a valid action for "\
               "#{params[:category]} settings. Valid actions are: "\
               "#{executor.methods}"
      success = false
    end
    render json: { success: success, result: result.chomp }
  end

  # TODO: Remove once debugging is complete
  def proxy_command
    line = Terrapin::CommandLine.new(params[:command])
    begin
      result = line.run
      success = true
    rescue Terrapin::ExitStatusError => e
      result = e.message
      success = false
    end
    render json: { success: success, result: result.chomp }
  end
end
