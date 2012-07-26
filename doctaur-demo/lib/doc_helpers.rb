module DocHelpers

  def render_inline(pages)
    sort_pages(pages).map { |page| render_individual_file(page.source_file) }.join
  end

  def all_pages
    sitemap.resources.select do |page|
      page.mime_type =~ /^text\/html/
    end
  end

  def pages_by_category

    pages_by_category = {}
    sitemap.resources.group_by { |page| page.data["category"] }.each do |category, pages|
      next if category.nil? # Skip pages that don't have "category" metadata
      pages_by_category[category] = sort_pages(pages).select { |p| p.path !~ /index/ }
    end

    pages_by_category
  end

  def pages_for_quick_ref
    pages_for_quick_ref = {}

    sitemap.resources.group_by { |page| page.data["category"] }.each do |category, pages|
      next if category.nil? # Skip pages that don't have "category" metadata
      next if category == "summary"
      pages_for_quick_ref[category] = sort_pages(pages).select { |p| p.path !~ /index/ && p.path !~ /representation/ }
    end

    pages_for_quick_ref

  end

  HTTP_METHOD_SORT_ORDER = %w[GET POST PUT PATCH DELETE]


  def sort_pages(pages)
    pages.sort_by do |page|
      [ page.data["category"],
      if page.path =~ /index/
        # Index always comes first
        -10

      elsif page.path =~ /representation/
        # Representation comes next
        -5

      elsif page.data["sort_order"]
        # If the page metadata specifies a sort order, do that
        page.data["sort_order"]

      else
        # Otherwise, guess by url length and http method
        endpoint = page.data["endpoint"].length
        method   = HTTP_METHOD_SORT_ORDER.index(page.data["method"] || page.data["methods"].first)

        endpoint * 10 + method
      end
    ]

    end
  end
end

