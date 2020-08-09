RSpec::Matchers.define :have_plugin do |expected|
  match do |actual|
    raise ArgumentError, "#{actual} should be a Mobility::Pluggable" unless Mobility::Pluggable === actual
    actual.class.ancestors.include? Mobility::Plugins.load_plugin(expected)
  end
end
