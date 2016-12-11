class String
  # paraphrased from activesupport
  def camelize
    sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
  end

  def present?
    !blank?
  end
end
