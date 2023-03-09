require 'swagger_helper'

RSpec.describe 'api/todos', type: :request do
  before do
    create(:todo)
  end

  # jitera-hook-for-rswag-example

  path '/api/todos/{id}' do
    put 'Update todos' do
      tags 'todos'
      consumes 'application/json'
      parameter name: 'id', in: :path, type: 'string', description: 'id'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          todos: {
            type: :object,
            properties: {
              title: {
                type: :string,
                example: 'string'
              },

              description: {
                type: :text,
                example: 'text'
              }

            }
          }
        }
      }
      response '200', 'update' do
        examples 'application/json' => {
          'todo' => {
            'id' => 'integer',

            'created_at' => 'datetime',

            'updated_at' => 'datetime',

            'title' => 'string',

            'description' => 'text'

          },

          'error_object' => {}

        }

        let(:resource) { create(:todo) }

        let(:id) { resource.id }

        let(:params) { { id: id, todos: { id: id } } }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end
    end
  end

  path '/api/todos/{id}' do
    get 'Show todos' do
      tags 'todos'
      consumes 'application/json'
      parameter name: 'id', in: :path, type: 'string', description: 'id'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
        }
      }
      response '200', 'show' do
        examples 'application/json' => {
          'todo' => {
            'id' => 'integer',

            'created_at' => 'datetime',

            'updated_at' => 'datetime',

            'title' => 'string',

            'description' => 'text'

          }

        }

        let(:resource) { create(:todo) }

        let(:params) {}

        let(:id) { resource.id }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end
    end
  end

  path '//api/todos' do
    post 'Create todos' do
      tags 'todos'
      consumes 'application/json'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          todos: {
            type: :object,
            properties: {
              title: {
                type: :string,
                example: 'string'
              },

              description: {
                type: :text,
                example: 'text'
              }

            }
          }
        }
      }
      response '200', 'create' do
        examples 'application/json' => {
          'todo' => {
            'id' => 'integer',

            'created_at' => 'datetime',

            'updated_at' => 'datetime',

            'title' => 'string',

            'description' => 'text'

          },

          'error_object' => {}

        }

        let(:resource) { build(:todo) }

        let(:params) { { todos: resource.attributes.to_hash } }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end
    end
  end

  path '/api/todos' do
    get 'List todos' do
      tags 'todos'
      consumes 'application/json'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          pagination_page: {
            type: :pagination_page,
            example: 'pagination_page'
          },
          pagination_limit: {
            type: :pagination_limit,
            example: 'pagination_limit'
          },
          todos: {
            type: :object,
            properties: {
              title: {
                type: :string,
                example: 'string'
              },

              description: {
                type: :text,
                example: 'text'
              }

            }
          }
        }
      }
      response '200', 'index' do
        examples 'application/json' => {
          'total_pages' => 'integer',

          'todos' =>
        [
          {

            'id' => 'integer',

            'created_at' => 'datetime',

            'updated_at' => 'datetime',

            'title' => 'string',

            'description' => 'text'

          }
        ]

        }

        let(:resource) { create(:todo) }

        let(:params) {}
        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end
    end
  end
end
