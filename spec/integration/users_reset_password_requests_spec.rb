# frozen_string_literal: true

require 'swagger_helper'

describe 'Reset password request API' do
  path '/api/users_reset_password_requests' do
    post 'Reset password request' do
      tags 'Reset password request'
      consumes 'application/json'

      parameter name: :owner_fields, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@jitera.com' }
        }
      }

      response '204', 'request sent' do
        before { User.find_by(email: 'user@jitera.com') || create(:user, email: 'user@jitera.com') }

        examples 'application/json' => {
        }

        let(:owner_fields) do
          {
            email: 'user@jitera.com'
          }
        end

        run_test! do |response|
          expect(response.status).to be(204)
        end
      end
    end
  end
end
