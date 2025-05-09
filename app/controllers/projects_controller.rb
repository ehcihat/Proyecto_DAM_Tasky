class ProjectsController < ApplicationController
    before_action :authorize_request
    def index
        if current_user
          projects = current_user.projects
          render json: projects
        else
          render json: { error: 'Usuario no autenticado' }, status: :unauthorized
        end
    end

    def show
        project = current_user.projects.find(params[:id])
        render json: project.as_json(include: {
            lists: {
                include: :tasks
            }
        })
      
    end

    def create
        project = current_user.projects.build(project_params)
        if project.save
            render json: project, status: :created
        else
            render json: { errors: project.errors.full_messages}, status: :unprocessable_entity
        end
    end

    def update
        project = current_user.projects.find(params[:id])
        if project.update(project_params)
            render json: project
        else
            render json: {errors: project.errors.full_messages}, status: :unprocessable_entity
        end
    end

    def destroy
        project = current_user.projects.find(params[:id])
        if project.destroy
            render json: {message: 'Proyecto eliminado correctamente'}
        else
            render json: {errors: 'Error al eliminar el proyecto'}, status: :unprocessable_entity
        end
    end

    def project_params
        params.require(:project).permit(:title, :description)
    end

end
