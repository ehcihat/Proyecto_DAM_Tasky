class CurrentUserController < ApplicationController
    before_action :authorize_request

    def show
        render json: { name: current_user.name}
    end
end