# frozen_string_literal: true

require 'swagger_helper'

describe 'Verify reset password request API' do
  path '/api/users_verify_reset_password_requests' do
    post 'Verify reset password request' do
      tags 'Verify reset password request'
      consumes 'application/json'

      parameter name: :owner_fields, in: :body, schema: {
        type: :object,
        properties: {
          reset_token: { type: :string, example: 'dummy_reset_token' },
          password: { type: :string, example: '2+A7cqBiDpltgk+g0g==' },
          password_confirmation: { type: :string, example: 'Q8HkG4vN56E0ulAFPA==' }
        }
      }

      response '200', 'request sent' do
        let(:user) { User.find_by(email: 'user@jitera.com') || create(:user, email: 'user@jitera.com') }
        let(:token) { user.generate_reset_password_token }

        examples 'application/json' => {
          success: true
        }

        let(:owner_fields) do
          {
            reset_token: token,
            password: 'WRi/mSqXCatEvBC4DQ==',
            password_confirmation: 'JqbobWoLz7FDDqGcqQ=='
          }
        end

        run_test! do |response|
          expect(response.status).to be(200)
        end
      end
    end
  end
end
