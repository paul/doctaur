require 'lib/resultifier'
module Doctaur
  class << self
    def registered(app)
      app.set :githubv3, "application/vnd.github.v3+json"
      app.set :markdown_engine, Doctaur::GitHubMarkdown

      app.before_configuration do
	template_extensions :doctaur => :html
      end

      app.after_configuration do
	sitemap.register_resource_list_manipulator(:doctaur,
						   Doctaur::Manipulator.new(self),
						   false)

        ::Tilt.register Doctaur::GitHubMarkdown, 'mkd'
        ::Tilt.prefer   Doctaur::GitHubMarkdown
      end

      app.helpers Doctaur::Helpers
    end
    alias included registered
  end

  class GitHubMarkdown < Tilt::Template
    CODE_FENCE_RE = /(\r?\n)```(\w+)\n(.+?)```(?=\r?\n)/m

    def prepare
    end

    def evaluate(scope, locals, &block)
      p data
      code = data.gsub(CODE_FENCE_RE) do |match|
        flavor, code = $2, $3
        Resultifier.resultify(flavor, code)
      end
      @output = GitHub::Markdown.render_gfm(code)
    end
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
          resource.extend RepresentationResource
	end

        if resource.data.has_key?("endpoint")
          resource.extend ApiResource
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
      data["title"]
    end

    def endpoint
      data["endpoint"]
    end

    def api
      @api = render layout: false
    end

    def anchor
      title.parameterize
    end

    def methods
      data["http_methods"] || Array.wrap(data["method"])
    end

    def requires_auth?
      data["requires_auth"]
    end

    def render(opts = {}, locals = {}, &block)
      content = super

      app.partial "templates/api", locals: {api: self, content: content}
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

end

