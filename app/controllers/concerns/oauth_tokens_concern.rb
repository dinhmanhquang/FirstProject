# frozen_string_literal: true

module OauthTokensConcern
  extend ActiveSupport::Concern

  def current_resource_owner
    doorkeeper_token&.resource_owner
  end

  alias current_admin current_resource_owner
  alias current_user current_resource_owner

  def current_user_authenticate
    head :unauthorized if current_user.blank?
  end

  def current_admin_authenticate
    head :unauthorized if current_admin.blank?
  end
end
