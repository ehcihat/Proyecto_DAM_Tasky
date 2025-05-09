class UsersController < ApplicationController
    skip_before_action :authorize_request, only: [:create]
    def create
        user_params = params.require(:user).permit(:name, :email, :password, :password_confirmation)
        if user_params[:password] != user_params[:password_confirmation]
            return render json: { error: 'Las contraseñas no coinciden'}, status: :unprocessable_entity
        end 
       
        user = User.new(name: user_params[:name], email: user_params[:email], password: user_params[:password])

        if user.save
            render json: { message: "Usuario creado", user: user}, status: :created
        else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
end

    def profile
        render json: {message: "Acceso autorizado al perfil", user: current_user.name}
    end
private

    def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
