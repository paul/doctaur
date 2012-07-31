module Doctaur
  class << self
    def registered(app)
      app.set :githubv3, "application/vnd.github.v3+json"

      app.before_configuration do
	template_extensions :doctaur => :html
      end

      app.after_configuration do
	sitemap.register_resource_list_manipulator(:representations,
						   Doctaur::RepresentationManipulator.new(self),
						   false)
      end

      app.helpers Doctaur::Helpers
    end
    alias included registered
  end

  class Template < Tilt::Template

    def prepare
      @code = data
    end

    def precompiled_template(locals)
      @code
    end

  end

  ::Tilt.register Template, 'doctaur'

  module Helpers

    def represent(name, options = {}, &block)
      representation = Doctaur::Representation.new(name, options, &block)

      render_individual_file "/templates/representation.html.haml", representation.locals
    end

  end

  class RepresentationManipulator

    def initialize(app)
      @app = app
    end

    def manipulate_resource_list(resources)
      resources.each do |resource|
	resource.extend PageExtensions

	if resource.source_file =~ /doctaur$/
	  resource.extend RepresentationResource
	end

	category = File.split(resource.path).first.split(File::Separator).last
	resource.add_metadata(page: {category: category}) if category
      end
    end
  end

  module PageExtensions
    def title
      data["title"]
    end

    def anchor
      data["title"].underscore
    end

    def category
      # foo/bar/baz.html.mkd #-> "bar"
      data["category"] || File.split(path).first.split(File::Separator).last
    end
  end

  module RepresentationResource

    def title
      "Representation"
    end

    def anchor
      "#{category}_representation"
    end

  end

  class Representation
    attr_reader :name

    def initialize(name, options, &block)
      @name = name
      @options = options

      instance_eval &block
    end

    def attributes(&block)
      if block_given?
	@attributes = AttributeEvaluator.new(&block)
      else
	@attributes
      end
    end

    def links(&block)
      if block_given?
	@links = AttributeEvaluator.new(&block)
      else
	@links
      end
    end

    def example(text = nil, &block)
      if block_given?
	@url = block.call
      else
	if text
	  text
	else
	  `curl #{@url}`
	end
      end
    end

    def locals
      {
	:name => name,
	:attributes => attributes,
	:links => links,
	:example => example,
	:anchor => anchor
      }
    end

    class AttributeEvaluator

      def initialize(&block)
	@attributes = []
	@in_loading_mode = true
	instance_eval &block
	@in_loading_mode = false
      end

      def method_missing(name, *a, &b)
	if @in_loading_mode
	  add_attribute name, *a
	else
	  super
	end
      end

      def add_attribute(name, *tags)
	if tags.last.is_a?(String)
	  desc = tags.pop
	end

	@attributes << [name, tags, desc]
      end

      def each(&b)
	@attributes.each(&b)
      end

    end
  end
end

