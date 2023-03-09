# typed: strict

module ConstantValidatable
  HIRAGANA_VALIDATION_FORMAT = %r{\A[ぁ-んー－ ]+\z} # rubocop:disable Style/RegexpLiteral
  KATAKANA_VALIDATION_FORMAT = %r{\A[ァ-ヶー－ ]+\z} # rubocop:disable Style/RegexpLiteral
  URL_VALIDATION_FORMAT = %r{\A(http|https)://[a-z0-9]+([\-.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}
  PHONE_NUMBER_VALIDATION_FORMAT = %r{\A[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}\z} # rubocop:disable Style/RegexpLiteral
end
