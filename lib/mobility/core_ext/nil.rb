=begin

Add +blank?+ method to +NilClass+ in case activesupport cannot be loaded.

=end
class NilClass
  def blank?
    true
  end
end
