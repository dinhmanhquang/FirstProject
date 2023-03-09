require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) do
    build(:user)
  end

  describe 'Valid subject' do
    it 'valid user' do
      expect(user).to be_valid
    end
  end

  describe 'Format option validations' do
    it { expect(user.email).to match(URI::MailTo::EMAIL_REGEXP) }
    it { expect(Faker::Lorem.sentence).not_to match(URI::MailTo::EMAIL_REGEXP) }
  end

  describe 'Invalid length validations' do
    it 'validates email max length' do
      user.email = 'a' * 256
      expect(user).not_to be_valid
    end
  end

  describe 'Validate uniqueness' do
    subject { build(:user) }

    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe 'Validate presence' do
    it { is_expected.to validate_presence_of(:email) }
  end
end
