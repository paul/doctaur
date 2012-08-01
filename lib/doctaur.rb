module Doctaur
  class << self
    def registered(app)
      app.set :githubv3, "application/vnd.github.v3+json"

      app.before_configuration do
	template_extensions :doctaur => :html
      end

      app.after_configuration do
	sitemap.register_resource_list_manipulator(:doctaur,
						   Doctaur::Manipulator.new(self),
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

      partial "templates/representation", locals: {rep: representation}
    end

    def api(method, endpoint, &block)
      api = Doctaur::Api.new(self, method, endpoint, &block)
    end

  end

  class Manipulator

    def initialize(app)
      @app = app
    end

    def manipulate_resource_list(resources)
      resources.each do |resource|
        next unless resource.mime_type =~ /text\/html/

	resource.extend PageExtensions

	if resource.source_file =~ /doctaur$/
          if resource.source_file =~ /representation/
            resource.extend RepresentationResource
          else
            resource.extend ApiResource
          end
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

    def category
      # foo/bar/baz.html.mkd #-> "bar"
      data["category"] || File.split(path).first.split(File::Separator).last
    end

    def anchor
      title.parameterize
    end
  end

  module RepresentationResource

    def title
      "Representation"
    end

    def anchor
      "#{category}-representation"
    end

  end

  module ApiResource

    def title
      api.title
    end

    def endpoint
      api.endpoint
    end

    def api
      @api = render layout: false
    end

    def anchor
      api.anchor
    end

    def methods
      api.methods
    end

  end

  class Representation
    attr_reader :name

    def initialize(name, options, &block)
      @name = name
      @options = options

      instance_eval &block
    end

    def anchor
      "#{name}-representation"
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
        :anchor => "#{name}_representation"
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

  class Api
    attr_reader :endpoint, :method, :requirements, :examples, :methods
    attr_accessor :title, :request_content, :response_content, :desc

    def initialize(app, method, endpoint, &block)
      @app = app
      @method = method
      @endpoint = endpoint
      @requirements = []
      @methods = Array.wrap(@method)
      @examples = []
      yield self
    end

    def anchor
      title.parameterize
    end

    def requires(*tags)
      @requirements.push *tags
    end

    def requires?(tag)
      @requirements.include? tag
    end

    def example(flavor, code)
      @examples.push Example.new flavor, code
    end

    def to_s
      @app.partial("templates/api", locals: {api: self})
    end

    class Example
      attr_reader :flavor, :code

      def initialize(flavor, code)
        @flavor, @code = flavor, code
      end

      def title
        flavor.to_s.titlecase
      end
    end


  end
end

