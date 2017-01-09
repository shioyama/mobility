module Mobility
  module Translates
    %w[accessor reader writer].each do |method|
      class_eval <<-EOM, __FILE__, __LINE__ + 1
        def mobility_#{method}(*args, **options)
          attributes = Attributes.new(:#{method}, *args, options.merge(model_class: self))
          yield(attributes.backend) if block_given?
          attributes.each do |attribute|
            alias_method "\#{attribute}_before_mobility",  attribute        if method_defined?(attribute)        && #{%w[accessor reader].include? method}
            alias_method "\#{attribute}_before_mobility=", "\#{attribute}=" if method_defined?("\#{attribute}=") && #{%w[accessor writer].include? method}
           end
          include attributes
        end
      EOM
    end
  end
end
