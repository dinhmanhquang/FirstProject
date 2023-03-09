# frozen_string_literal: true

require 'swagger_helper'

describe 'Reset password request API' do
  path '/api/admins_reset_password_requests' do
    post 'Reset password request' do
      tags 'Reset password request'
      consumes 'application/json'

      parameter name: :owner_fields, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'admin@jitera.com' }
        }
      }

      response '204', 'request sent' do
        before { Admin.find_by(email: 'admin@jitera.com') || create(:admin, email: 'admin@jitera.com') }

        examples 'application/json' => {
        }

        let(:owner_fields) do
          {
            email: 'admin@jitera.com'
          }
        end

        run_test! do |response|
          expect(response.status).to be(204)
        end
      end
    end
  end
end
