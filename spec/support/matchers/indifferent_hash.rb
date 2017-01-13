# Match structure of hash, disregarding whether keys are symbols or strings
RSpec::Matchers.define :match_hash do |expected|
  match do |actual|
    actual.stringify_keys == expected.stringify_keys
  end
end
