class TasksController < ApplicationController
    before_action :authorize_request
    before_action :set_list

    def index
        render json: @list.tasks.order_by(:created_at.asc)
    end

    def create
        task = @list.tasks.build(task_params)
        if task.save
            render json: task, status: :created
        else
            render json: {errors: task.errors.full_messages}, status: :unprocessable_entity
        end
    end

    def update
        begin
          task = Task.find(params[:id])
          unless task.list.project.user_id == current_user.id
            return render json: { error: 'No autorizado para modificar esta tarea' }, status: :unauthorized
          end
      
          if task_params[:list_id].present?
            new_list = List.find(task_params[:list_id])
      
            unless new_list.project.user_id == current_user.id
              return render json: { error: 'No autorizado para mover la tarea a esta lista' }, status: :unauthorized
            end
      
      
            task.set(list_id: new_list.id)
            task.reload
          end
      
          if task.update(task_params)
            render json: task
          else
            render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
          end
      
        rescue Mongoid::Errors::DocumentNotFound
          render json: { error: 'Task or List not found' }, status: :not_found
        end
    end
      
    

    def destroy
        task = @list.tasks.find(params[:id])
        if task.destroy
            render json: {message: 'Tarea eliminada correctamente'}
        else
            render json: {errors: 'Error al eliminar la tarea'}, status: :unprocessable_entity
        end
    end

    private 

    def set_list
        @list = List.find(params[:list_id])
        unless @list.project.user_id == current_user.id
            render json: { error: 'No autorizado'}, status: :unauthorized and return
        end
    end

    def task_params
        params.require(:task).permit(:title, :description, :completed, :progress, :due_date, :list_id, comments: [])
    end



end



