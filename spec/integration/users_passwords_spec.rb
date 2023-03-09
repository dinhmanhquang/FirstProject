# frozen_string_literal: true

require 'swagger_helper'

describe 'User change password API' do
  path '/api/users_passwords' do
    post 'change password' do
      tags 'Change password'
      consumes 'application/json'
      security [bearerAuth: []]

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          new_password: { type: :string, example: 'B5LCHbY7N6C9+egEfg==' },
          old_password: { type: :string, example: 'B5LCHbY7N6C9+egEfg==' }
        }
      }

      let(:password) do
        Faker::Internet.password(min_length: 13, max_length: 13, mix_case: true, special_characters: true)
      end
      let(:resource_owner) { create(:user, password: password) }
      let(:token) { create(:access_token, resource_owner: resource_owner).token }
      let(:Authorization) { "Bearer #{token}" }
      let(:id) { resource_owner.id }
      let(:params) do
        { new_password: Faker::Internet.password(min_length: 13, max_length: 13, mix_case: true, special_characters: true),
          old_password: password }
      end

      response '200', 'Password updated' do
        examples 'application/json' => {
          success: true
        }
        run_test! do |response|
          expect(response.status).to be(200)
        end
      end

      response '200', 'Cannot update password' do
        examples 'application/json' => {
          success: false
        }

        let(:new_password) do
          {
            new_password: '1'
          }
        end

        run_test! do |response|
          expect(response.status).to be(200)
        end
      end
    end
  end
end
