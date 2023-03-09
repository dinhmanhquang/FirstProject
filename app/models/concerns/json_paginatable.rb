# typed: false

module JsonPaginatable
  def json_pagination
    {
      next_page: next_page,
      prev_page: prev_page,
      total_pages: total_pages,
      is_last_page: last_page? || total_pages.zero?
    }
  end
end
