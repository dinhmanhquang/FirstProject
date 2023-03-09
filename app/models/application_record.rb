# typed: ignore

class ApplicationRecord < ActiveRecord::Base
  include ActiveStorage::RetrieveAttachment

  self.abstract_class = true

  scope :csv_body, -> { map(&:attributes).map(&:values).map { |values| values.join(',') }.join("\n") }

  class << self
    def csv
      "#{csv_header}\n#{csv_body}"
    end

    def csv_header
      new.attributes.keys.join(',')
    end

    def send_csv_report_via_email(email)
      file_name = "#{table_name}#{Time.zone.now}.csv"
      file_path = "tmp/#{file_name}"
      fill_up_data_in_csv(file_path, order(created_at: :desc))
      # created tmp file in server and delete it immediately after email sent
      # we can refactor this later
      # we can store in s3 and send s3 link because email has validation on size
      # will refactor in next steps
      DashboardMailer.with(file_path: file_path, receiver: email,
                           table_name: table_name).dashboard_index_summary.deliver_now
      FileUtils.rm_f(file_path)
    end

    def fill_up_data_in_csv(file_path, table_definition_records)
      require 'csv'
      is_file_exist = File.exist?(file_path)
      raise(I18n.t('.file_exists_label')) if is_file_exist

      CSV.open(file_path, 'wb') do |csv|
        csv << fetch_column_names.map { |attr_name| attr_name.humanize&.upcase } unless is_file_exist
        table_definition_records.each do |table_definition_name|
          csv << fetch_column_names.map { |attr_name| table_definition_name.send(attr_name.to_sym) }
        end
        is_file_exist = File.exist?(file_path)
        csv.flush
      end
    end

    def fetch_column_names
      column_names - TableDefinition.default_column_names
    end
  end
end
