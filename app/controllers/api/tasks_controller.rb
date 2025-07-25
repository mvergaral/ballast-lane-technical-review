class Api::TasksController < Api::ApplicationController
  before_action :set_task, only: [ :show, :update, :destroy ]

  def index
    @tasks = current_user.tasks
    authorize @tasks

    render json: @tasks
  end

  def show
    authorize @task
    render json: @task
  end

  def create
    @task = current_user.tasks.build(task_params)
    authorize @task

    if @task.save
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @task

    if @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task
    @task.destroy
    head :no_content
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :due_date)
  end
end
