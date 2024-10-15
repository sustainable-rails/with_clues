module WithClues
  module Private
    class CustomClueMethodAnalysis

      def self.from_method(unbound_method)

        params = unbound_method.parameters.map { |param_array| Param.new(param_array) }

        if params.size == 2
          two_arg_method = TwoArgMethod.new(params)
          if two_arg_method.valid?
            return StandardImplementation.new
          end

          return BadParams.new(two_arg_method.errors)

        elsif params.size == 4
          three_arg_method = FourArgMethod.new(params)
          if three_arg_method.valid?
            return RequiresPageObject.new
          end
          return BadParams.new(three_arg_method.errors)
        end

        BadParams.new([
          "dump (#{unbound_method.owner}) accepted #{params.size} arguments, not 2 or 4. Got: #{params.map(&:to_s).join(", ")}, should be one positional and either one keyword arg named 'context:' or three keyword args named 'context:', 'page:', and 'captured_logs:'"
        ])
      end

      def standard_implementation?
        false
      end

      def requires_page_object?
        false
      end

      def raise_exception!
        raise StandardError.new("Unimplemented condition found inside #from_method")
      end

      class Param

        def initialize(method_param_array)
          @type = method_param_array[0]
          @name = method_param_array[1]

        end

        def required?
          @type == :req
        end
        def keyword_required?
          @type == :keyreq
        end

        def named?(*allowed_names)
          allowed_names.include?(@name)
        end
        def name
          if self.keyword_required?
            "#{@name}:"
          else
            @name
          end
        end
        def to_s
          "#<#{self.class} #{name}/#{@type}"
        end
      end

      class TwoArgMethod
        attr_reader :errors
        def initialize(params)
          @errors = []
          if !params[0].required?
            @errors << "Param 1, #{params[0].name}, is not required"
          end
          require_keyword(2,params[1])
        end

        def valid?
          @errors.empty?
        end
      private

        def require_keyword(param_number, param)
          if !param.keyword_required?
            @errors << "Param #{param_number}, #{param.name}, is not a required keyword param"
          end
          if !param.named?(*allowed_names)
            @errors << "Param #{param_number}, #{param.name}, should be one of #{allowed_names.join(',')}"
          end
        end

        def allowed_names
          [ :context ]
        end
      end

      class FourArgMethod < TwoArgMethod
        def initialize(params)
          super(params)
          require_keyword(3,params[2])
          require_keyword(4,params[3])
        end
      private
        def allowed_names
          [ :context, :page, :captured_logs ]
        end
      end

    end

    class GoodParams < CustomClueMethodAnalysis
      def raise_exception!
        raise StandardError.new("You should not have called .exception on a #{self.class.name}")
      end
    end

    class RequiresPageObject < CustomClueMethodAnalysis
      def requires_page_object?
        true
      end
    end

    class StandardImplementation < CustomClueMethodAnalysis
      def standard_implementation?
        true
      end
    end

    class BadParams < CustomClueMethodAnalysis
      def initialize(errors)
        if errors.empty?
          raise ArgumentError,"BadParams requires errors"
        else
          @message = errors.map(&:to_s).join(", ")
        end
      end

      DEFAULT_ERROR = "dump must take one required param, one keyword param named context: and an optional keyword param named page:"

      def raise_exception!
        raise NameError.new(@message)
      end
    end
  end
end
