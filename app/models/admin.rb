class Admin < ApplicationRecord
  include ConstantValidatable
  devise :database_authenticatable, :registerable, :rememberable, :validatable,
         :trackable, :recoverable, :lockable, :confirmable
  # jitera-anchor-dont-touch: relations

  # jitera-anchor-dont-touch: enum

  # jitera-anchor-dont-touch: file

  # jitera-anchor-dont-touch: validation

  PASSWORD_FORMAT = /\A(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}\z/
  validates :password, format: PASSWORD_FORMAT, if: -> { password.present? }

  validates :email, length: { maximum: 255 }

  validates :email, presence: true

  validates :email, uniqueness: true

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # jitera-anchor-dont-touch: reset_password
  def generate_reset_password_token
    raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)
    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc
    save(validate: false)
    raw
  end

  class << self
    def authenticate?(email, password)
      admin = Admin.find_for_authentication(email: email)
      return false if admin.blank?

      if admin&.valid_for_authentication? { admin.valid_password?(password) }
        admin.reset_failed_attempts!
        return admin
      end

      # We will show the error message in TokensController
      return admin if admin&.access_locked?

      false
    end
  end
end
