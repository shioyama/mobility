# frozen_string_literal: true

module Mobility
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 1
    MINOR = 0
    TINY = 0
    PRE = "beta1"

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end
end
