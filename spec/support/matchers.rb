RSpec::Matchers.define :have_stash do |expected|
  match do |actual|
    actual.to_s == expected
  end
end
