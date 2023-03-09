require 'rails_helper'

RSpec.describe Todo, type: :model do
  let(:todo) do
    build(:todo)
  end

  describe 'Valid subject' do
    it 'valid todo' do
      expect(todo).to be_valid
    end
  end

  describe 'Invalid length validations' do
    it 'validates title max length' do
      todo.title = 'a' * 256
      expect(todo).not_to be_valid
    end

    it 'validates description max length' do
      todo.description = 'a' * 65_536
      expect(todo).not_to be_valid
    end
  end
end
