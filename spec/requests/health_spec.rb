require 'swagger_helper'

RSpec.describe '/health', type: :request do
  path '/health' do
    get 'System Health' do
      tags 'system'
      consumes 'application/json'
      response '200', 'index' do
        examples 'application/json' => {
        }

        let(:params) {}
        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end
    end
  end
end
