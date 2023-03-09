import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = false
import  'jquery';
import 'bootstrap';
import railsUjs from '@rails/ujs'
import activestorage from '@rails/activestorage'
import '@hotwired/turbo-rails'
import flatpickr from 'flatpickr'
import * as Japanese from 'flatpickr/japanese'

import moment from 'moment'
import Pikaday from 'pikaday'

railsUjs.start()
activestorage.start()

moment.locale('ja')

$(document).on('turbo:load', () => {
  const initializeFlatpicker = () => {
    const defaultOptions = { locale: Japanese, altFormat: 'y年m月d日', allowInput: true }
    flatpickr('[data-toggle="flatpickr"]', defaultOptions)
    flatpickr('[data-toggle="flatpickr-datetime"]', {
      ...defaultOptions,
      enableTime: true,
      altFormat: 'Y年m月d日 H時i分'
    })
  }
  const i18n = {
    previousMonth: '前の月',
    nextMonth: '次の月',
    months: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
    weekdays: ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'],
    weekdaysShort: ['日', '月', '火', '水', '木', '金', '土']
  }
  $('.js-datepicker').each((i, el) => {
    return new Pikaday({ field: $(el)[0], format: 'Y/M/D', i18n })
  })

  initializeFlatpicker()
  $(window).on('cocoon:after-insert', initializeFlatpicker)

  const sendSortRequest = (element) => {
    let orderDirection = element.dataset.orderDirection,
      orderColumn = element.dataset.orderColumn,
      uri = element.dataset.url,
      params = JSON.parse(element.dataset.params)
    params['query']['order_column'] = orderColumn
    params['query']['order_direction'] = orderDirection
    window.location.href = `..${uri}?${$.param(params)}`
  }

  $('.js-dashboard-sort').on('click', function() {
    sendSortRequest(this)
  })
})
