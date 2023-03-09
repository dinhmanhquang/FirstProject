# frozen_string_literal: true

class TokensController < Doorkeeper::TokensController
  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :check_if_resource_confirmed, only: :create
  before_action :check_if_resource_locked, only: :create
  # rubocop:enable Rails/LexicallyScopedActionFilter

  private

  def check_if_resource_confirmed
    return unless resource_owner_inactive?

    render json: { error: I18n.t('devise.failure.inactive'), message: I18n.t('devise.failure.inactive') },
           status: :forbidden
  end

  def check_if_resource_locked
    return unless resource_owner_locked?

    render json: { error: I18n.t('devise.failure.locked'), message: I18n.t('devise.failure.locked') },
           status: :forbidden
  end

  def resource_owner
    return nil unless authorize_response.respond_to?(:token)

    authorize_response&.token&.resource_owner
  end

  # jitera-hook-for-resource-owner-inactive
  def resource_owner_inactive?
    return admins_inactive? if resource_owner.is_a?(Admin)

    return users_inactive? if resource_owner.is_a?(User)
  end

  def admins_inactive?
    return !resource_owner&.confirmed? if resource_owner.is_a?(Admin)
  end

  def users_inactive?
    return !resource_owner&.confirmed? if resource_owner.is_a?(User)
  end

  # jitera-hook-for-resource-owner-locked
  def resource_owner_locked?
    return admins_locked? if resource_owner.is_a?(Admin)

    return users_locked? if resource_owner.is_a?(User)
  end

  def admins_locked?
    return resource_owner&.access_locked? if resource_owner.is_a?(Admin)
  end

  def users_locked?
    return resource_owner&.access_locked? if resource_owner.is_a?(User)
  end
end
