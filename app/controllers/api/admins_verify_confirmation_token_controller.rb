module Api
  class AdminsVerifyConfirmationTokenController < Api::BaseController
    # jitera-anchor-dont-touch: before_action_filter

    # jitera-index-anchor-dont-touch: actions

    # jitera-show-anchor-dont-touch: actions

    # jitera-create-anchor-dont-touch: actions
    def create
      resource = Admin.find_by(confirmation_token: params[:confirmation_token])

      if resource.blank? || params[:confirmation_token].blank?
        render error_message: I18n.t('errors.messages.invalid.confirmation_token'),
               status: :unprocessable_entity and return
      end

      if (resource.confirmation_sent_at + Admin.confirm_within) < Time.now.utc
        resource.resend_confirmation_instructions
        render json: { error_message: I18n.t('errors.messages.expired.confirmation_token') },
               status: :unprocessable_entity
      else
        resource.confirm
        head :ok
      end
    end

    # jitera-update-anchor-dont-touch: actions

    # jitera-destroy-anchor-dont-touch: actions

    # jitera-anchor-dont-touch: actions
  end
end
