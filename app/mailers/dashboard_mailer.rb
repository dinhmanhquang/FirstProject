class DashboardMailer < ApplicationMailer
  def dashboard_index_summary
    attachments['index_csv.csv'] = File.read(params[:file_path])
    mail(to: params[:receiver], subject: I18n.t(".dashboard_mailer.#{params[:table_name]}.table_data_exported_label"))
  end
end
