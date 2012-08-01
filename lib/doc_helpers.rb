module DocHelpers

  def render_inline(pages)
    sort_pages(pages).map { |page| render_individual_file(page.source_file) }.join
  end

  def all_pages
    sitemap.resources.select do |page|
      page.mime_type =~ /^text\/html/
    end
  end

  def pages_for_toc
    pages_by_category = {}
    group_by_sorted_category(all_pages).each do |category, pages|
      next if category.nil? # Skip pages that don't have "category" metadata
      next if category == "."
      pages_by_category[category] = sort_pages(pages).select { |p| p.path !~ /index/ }
    end

    pages_by_category
  end

  def pages_for_quick_ref
    pages_for_quick_ref = {}

    group_by_sorted_category(all_pages).each do |category, pages|
      next if category.nil? # Skip pages that don't have "category" metadata
      next if category == "summary" # Skip the summary pages in the quick reference
      next if category == "."
      pages_for_quick_ref[category] = sort_pages(pages).select { |p| p.is_a? Doctaur::ApiResource }
    end

    pages_for_quick_ref

  end

  HTTP_METHOD_SORT_ORDER = %w[GET POST PUT PATCH DELETE]

  def group_by_sorted_category(pages)
    pages_by_category = {}

    pages.each do |page|
      category = page_category(page)
      next if category.nil?
      pages_by_category[category] ||= []
      pages_by_category[category] << page
    end

    sorted = pages_by_category.sort_by do |key, value|
      key..to_s == "overview" ? -1 : key
    end

    Hash[sorted]
  end


  def sort_pages(pages)
    pages.sort_by do |page|
      filepath, filename = File.split(page.path)
      category = filepath.split(File::Separator).last

      # First, order by category
      [ category,
      if filename =~ /index/
        # Index always comes first
        -10

      elsif filename =~ /representation/
        # Representation comes next
        -5

      elsif page.data["sort_order"]
        # If the page metadata specifies a sort order, do that
        page.data["sort_order"]

      elsif page.data["endpoint"]
        # url length and http method
        endpoint = page.data["endpoint"].length
        method   = HTTP_METHOD_SORT_ORDER.index(page.data["method"] || page.data["methods"].first)

        endpoint * 10 + method

      else
	# Otherwise, alphabetic by filename
	filename.to_i
      end
    ]

    end
  end

  def page_category(page)
    File.split(page.path).first.split(File::Separator).last
  end
end

