class SystemController < ApplicationController

  def status
    render json: {meta: System.info }
  end

  def apply_setting
    executor = "SettingExecution::#{params[:category].capitalize}::".safe_constantize
    result = if executor.respond_to?(params[:setting])
               executor.send(params[:setting], params[:value])
             else
               false
             end
    render json: { success: result }
  end
end
