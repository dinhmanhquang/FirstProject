json.todo do
  json.id @todo.id
  json.created_at @todo.created_at
  json.updated_at @todo.updated_at
  json.title @todo.title
  json.description @todo.description
end
