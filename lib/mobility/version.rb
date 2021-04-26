# frozen_string_literal: true

module Mobility
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 1
    MINOR = 1
    TINY = 2
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end
end
