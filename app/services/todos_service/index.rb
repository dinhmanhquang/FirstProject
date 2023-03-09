# rubocop:disable Style/ClassAndModuleChildren
class TodosService::Index
  attr_accessor :params, :records, :query

  def initialize(params, _current_user = nil)
    @params = params

    @records = Todo

    @query = records
  end

  def execute
    todos_title_start_with_like

    todos_description_start_with_like

    order
    paginate

    records
  end

  def todos_title_start_with_like
    return if params.dig(:todos, :title).blank?

    where_clause = query.where('todos.title like ?', "%#{params.dig(:todos, :title)}")

    @records = where_clause
  end

  def todos_description_start_with_like
    return if params.dig(:todos, :description).blank?

    where_clause = query.where('todos.description like ?', "%#{params.dig(:todos, :description)}")

    # Notes - The reason for doing this is as below
    # If suppose there is OR condition, and previous 1 filter is nil, params, not present?
    # in such case there will be records.or(second_condition)
    # OR will return all records and break logic
    # ideally if previous condition nil it should retrun with current second condition and not perform OR
    @records = if records.is_a?(Class)
                 where_clause
               else
                 records.or(query)
               end
  end

  def order
    @records = records.order('todos.created_at desc')
  end

  def paginate
    @records = records.page(params[:pagination_page] || 1).per(params[:pagination_limit] || 20)
  end
end
# rubocop:enable Style/ClassAndModuleChildren
