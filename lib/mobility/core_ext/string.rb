=begin

Add String methods +camelize+ and +present?+ to +String+ if activesupport
cannot be loaded.

=end
class String
  # paraphrased from activesupport
  def camelize
    sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/'.freeze, '::'.freeze)
  end

  def present?
    !blank?
  end
end
