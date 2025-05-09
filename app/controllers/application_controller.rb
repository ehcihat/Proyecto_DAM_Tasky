class ApplicationController < ActionController::API
    before_action :authorize_request

    private
  
    def authorize_request
      header = request.headers['Authorization']
      header = header.split(' ').last if header
      begin
        decoded = JsonWebToken.decode(header)
        @current_user = User.find(decoded[:user_id])
      rescue Mongoid::Errors::DocumentNotFound, JWT::DecodeError
        render json: { errors: 'Token inválido o usuario no encontrado' }, status: :unauthorized
      end
    end
  
    def current_user
      @current_user
    end
end
