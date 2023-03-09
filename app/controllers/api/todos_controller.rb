module Api
  class TodosController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions
    def index
      @todos = TodosService::Index.new(params.to_unsafe_h, current_user).execute
      @total_pages = @todos.total_pages
    end

    # jitera-show-anchor-dont-touch: actions
    def show
      @todo = Todo.find(params[:id])
      # show-authorization-code
    end

    # jitera-create-anchor-dont-touch: actions
    def create
      @todo = Todo.new(create_params)
      # create-authorization-code
      return if @todo.save

      @error_object = @todo.errors.full_messages
      render status: :unprocessable_entity
    end

    # jitera-update-anchor-dont-touch: actions
    def update
      @todo = Todo.find(params[:id])
      # update-authorization-code
      return  if @todo.update(update_params)

      @error_object = @todo.errors.full_messages
      render status: :unprocessable_entity
    end

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions

    private

    def update_params
      params.require(:todos).permit(:title, :description)
    end

    def create_params
      params.require(:todos).permit(:title, :description)
    end
  end
end
