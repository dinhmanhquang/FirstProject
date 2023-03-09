# typed: true

class DatetimeTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_nil]

    record.errors.add(attribute, (options[:message] || :datetime_type)) unless valid_type?(value)
    record.errors.add(attribute, (options[:message] || :in_past)) unless past?(options, value)
    record.errors.add(attribute, (options[:message] || :in_future)) unless future?(options, value)
  end

  def valid_type?(value)
    value.present? && (value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone))
  end

  def past?(options, value)
    return true if options[:past].blank?

    value.present? && value < Time.zone.now
  end

  def future?(options, value)
    return true if options[:future].blank?

    value.present? && value > Time.zone.now
  end
end
