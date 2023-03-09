# frozen_string_literal: true

require 'swagger_helper'

describe 'Verify Confirmation API' do
  path '/api/admins_verify_confirmation_token' do
    post 'Verify confirmation token' do
      tags 'Verify confirmation token'
      consumes 'application/json'

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          confirmation_token: { type: :string, example: '77uw+3l4HnqnmZ2eNw==' }
        }
      }

      response '200', 'request sent' do
        examples 'application/json' => {
          success: true
        }
        let(:admin) { create(:admin, email: 'admin@jitera.com') }
        before do
          admin.send_confirmation_instructions
        end

        let(:token) { admin.confirmation_token }
        let(:params) do
          {
            confirmation_token: token
          }
        end

        run_test! do |response|
          expect(response.status).to be(200)
        end
      end
    end
  end
end
