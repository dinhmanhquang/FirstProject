# typed: strict
class ApplicationController < ActionController::Base
  include ActionController::Cookies
  include Pundit

  # basic_auth
end
