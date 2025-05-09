class SessionsController < ApplicationController
    skip_before_action :authorize_request, only: [:create]
    def create
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
            token = generate_jwt_token(user)
            render json: { message: "Login realizado con exito", user: user, token: token}, status: :ok
        else
            render json: {message: "Credenciales incorrectas"}, status: :unauthorized
        end
    end

  def destroy
  
    head :no_content
  end

    private 

    def generate_jwt_token(user)
        JsonWebToken.encode(user_id: user.id)
    end
end
