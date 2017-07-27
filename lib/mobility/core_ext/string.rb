=begin

Add String methods +camelize+ and +present?+ to +String+ if activesupport
cannot be loaded.

=end
class String
  def present?
    !blank?
  end
end
