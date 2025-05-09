class ListsController < ApplicationController
    before_action :authorize_request

    def index
        project = current_user.projects.find(params[:project_id])
        lists = project.lists.includes(:tasks)
        render json: lists.as_json(include: :tasks)
    end

    def create
        project = current_user.projects.find(params[:project_id])
        list = project.lists.build(list_params)
        if list.save
            render json: list, status: :created
        else
            render json: {errors: list.errors.full_messages}, status: :unprocessable_entity
    
        end
    end

    def update 
        project = current_user.projects.find(params[:project_id])
        list = project.lists.find(params[:id])
        if list.update(list_params)
            render json: list
        else
            render json: {errors: list.errors.full_messages}, status: :unprocessable_entity
        end
    end

    def destroy
        project = current_user.projects.find(params[:project_id])
        list = project.lists.find(params[:id])
        if list.destroy
            render json: {message: 'Lista eliminada correctamente'}
        else
            render json: {errors: 'Error al eliminar la lista'}, status: :unprocessable_entity
        end
    end
    


    private 

    def list_params
        params.require(:list).permit(:title, :order)
    end
end