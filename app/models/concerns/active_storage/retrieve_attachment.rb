# typed: ignore

module ActiveStorage
  module RetrieveAttachment
    extend ActiveSupport::Concern
    include Rails.application.routes.url_helpers

    def image_url(image)
      return unless public_send(image).attached?

      variant = public_send(image).variant(resize: '500x500')
      rails_representation_url(variant)
    end

    def image_urls(images)
      return [] unless public_send(images).attached?

      public_send(images).map do |image|
        variant = image.variant(resize: '500x500')
        rails_representation_url(variant)
      end
    end
  end
end
