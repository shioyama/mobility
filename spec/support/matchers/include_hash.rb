RSpec::Matchers.define :include_hash do |expected|
  match do |actual|
    return false if actual.nil?
    expected.values == actual.values_at(*expected.keys)
  end
end
