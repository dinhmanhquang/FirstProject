class DeliverCsvJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 7

  def perform(class_name, email)
    class_name.send_csv_report_via_email(email)
  end
end
