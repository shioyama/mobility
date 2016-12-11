module Mobility
  module Translates
    %w[accessor reader writer].each do |method|
      class_eval <<-EOM, __FILE__, __LINE__ + 1
        def translation_#{method}(*args, **options)
          attributes = Attributes.new(:#{method}, *args, options.merge(model_class: self))
          yield(attributes.backend) if block_given?
          include attributes
        end
      EOM
    end

    alias :translates :translation_accessor
  end
end
