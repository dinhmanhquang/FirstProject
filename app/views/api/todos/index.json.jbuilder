json.total_pages @total_pages
json.todos @todos do |todo|
  json.id todo.id
  json.created_at todo.created_at
  json.updated_at todo.updated_at
  json.title todo.title
  json.description todo.description
end
