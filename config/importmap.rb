# typed: false
# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@rails/actioncable', to: 'https://ga.jspm.io/npm:@rails/actioncable@6.1.5/app/assets/javascripts/action_cable.js'
pin '@rails/activestorage', to: 'https://ga.jspm.io/npm:@rails/activestorage@6.1.5/app/assets/javascripts/activestorage.js'
pin '@rails/ujs', to: 'https://ga.jspm.io/npm:@rails/ujs@6.1.5/lib/assets/compiled/rails-ujs.js'
pin 'bootstrap', to: 'https://cdn.jsdelivr.net/npm/bootstrap@4.6.1/dist/js/bootstrap.min.js'
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.2/lib/index.js'
pin 'cocoon-js', to: 'https://ga.jspm.io/npm:cocoon-js@0.0.5/index.js'
pin 'jquery', to: 'https://code.jquery.com/jquery-3.6.0.min.js', preload: true
pin 'dayjs', to: 'https://ga.jspm.io/npm:dayjs@1.11.0/dayjs.min.js'
pin 'flatpickr', to: 'https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js'
pin 'i18next', to: 'https://ga.jspm.io/npm:i18next@21.6.16/dist/esm/i18next.js'
pin '@babel/runtime/helpers/esm/assertThisInitialized', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/assertThisInitialized.js'
pin '@babel/runtime/helpers/esm/classCallCheck', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/classCallCheck.js'
pin '@babel/runtime/helpers/esm/createClass', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/createClass.js'
pin '@babel/runtime/helpers/esm/defineProperty', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/defineProperty.js'
pin '@babel/runtime/helpers/esm/getPrototypeOf', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/getPrototypeOf.js'
pin '@babel/runtime/helpers/esm/inherits', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/inherits.js'
pin '@babel/runtime/helpers/esm/possibleConstructorReturn', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/possibleConstructorReturn.js'
pin '@babel/runtime/helpers/esm/toArray', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/toArray.js'
pin '@babel/runtime/helpers/esm/typeof', to: 'https://ga.jspm.io/npm:@babel/runtime@7.17.9/helpers/esm/typeof.js'
pin 'i18next-browser-languagedetector', to: 'https://ga.jspm.io/npm:i18next-browser-languagedetector@6.1.4/dist/esm/i18nextBrowserLanguageDetector.js'
pin 'moment', to: 'https://ga.jspm.io/npm:moment@2.29.1/moment.js'
pin 'pikaday', to: 'https://ga.jspm.io/npm:pikaday@1.8.2/pikaday.js'
pin 'popper.js', to: 'https://ga.jspm.io/npm:popper.js@1.16.1/dist/umd/popper.js'
pin 'selectize', to: 'vendor/selectize.min.js'
pin 'theme', to: 'vendor/theme.js'
pin 'flatpickr/japanese', to: 'https://npmcdn.com/flatpickr/dist/l10n/ja.js'
pin 'moment/locale/ja', to: 'https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/locale/ja.min.js'
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
