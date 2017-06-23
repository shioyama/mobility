# Match structure of hash, disregarding whether keys are symbols or strings
RSpec::Matchers.define :match_hash do |expected|
  match do |actual|
    stringify_keys(actual) == stringify_keys(expected)
  end
end
