class Todo < ApplicationRecord
  include ConstantValidatable

  # jitera-anchor-dont-touch: relations

  # jitera-anchor-dont-touch: enum

  # jitera-anchor-dont-touch: file

  # jitera-anchor-dont-touch: validation

  validates :title, length: { maximum: 255 }

  # jitera-anchor-dont-touch: reset_password

  class << self
  end
end
