# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from NotImplementedError, with: :not_implemented_error_renderer

  def not_implemented_error_renderer(error)
    render json: {
      errors: [
        JSONAPI::Error.new(
          title: 'Functionality not implemented',
          detail: error.message,
          code: 501,
          status: :not_implemented
        )
      ]
    }, status: :not_implemented
  end
end
