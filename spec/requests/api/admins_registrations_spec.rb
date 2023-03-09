require 'swagger_helper'

RSpec.describe 'api/admins_registrations', type: :request do
  before do
    create(:admin)
  end

  # jitera-hook-for-rswag-example

  path '/api/admins_registrations' do
    post 'Create admins' do
      tags 'authentication'
      consumes 'application/json'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          admin: {
            type: :object,
            properties: {
              password: {
                type: :string,
                example: 'string'
              },

              password_confirmation: {
                type: :string,
                example: 'string'
              },

              email: {
                type: :string,
                example: 'string'
              }

            }
          }
        }
      }
      response '200', 'auth_registration' do
        examples 'application/json' => {
        }

        let(:resource) { build(:admin) }

        let(:params) { { admin: resource.attributes.to_hash } }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end
    end
  end
end
