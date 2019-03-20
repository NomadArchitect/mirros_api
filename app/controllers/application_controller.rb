class ApplicationController < ActionController::API
  rescue_from NotImplementedError, with: :not_implemented_error_renderer

  def not_implemented_error_renderer(e)
    render json: {
      errors: [
        JSONAPI::Error.new(
          title: "Functionality not implemented",
          detail: e.message,
          code: 501,
          status: :not_implemented
        )
      ]
    }, status: 501
  end
end
