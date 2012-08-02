module Doctaur

  class Resultifier

    def self.resultify(flavor, code)
      resultifier_klass_for(flavor).new(flavor, code).result_mkd
    end

    def self.resultifier_klass_for(flavor)
      case flavor.to_s
      when "bash" then CurlResultifier
      else             NullResultifier
      end
    end

    class NullResultifier
      attr_reader :flavor, :code

      def initialize(flavor, code)
        @flavor, @code = flavor, code
      end

      def result_mkd
        <<-RESULT
```#{flavor}
#{code}
-- No result, because I don't know what to do with #{flavor.inspect}
```
RESULT
      end
    end

    class CurlResultifier < NullResultifier

      def subbed_code
        code.gsub('{{password}}', ENV['GH_PASSWORD'])
      end

      def result
        result = `#{subbed_code}`
      end

      def result_mkd
        <<-RESULT
```#{flavor}
#{code}
#{result}
```
RESULT
      end
    end

  end
end

