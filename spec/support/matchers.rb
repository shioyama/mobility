RSpec::Matchers.define :have_stash do |expected|
  match do |actual|
    actual.__mobility_get == expected
  end
end
