shared_examples_for "AR Model validation" do |model_class_name, attribute1=:title, attribute2=:content|
  let(:model_class) do
    model_class = model_class_name.constantize
    model_class.class_eval do
      validates attribute1, uniqueness: true
    end
    model_class
  end

  describe "Uniqueness validation" do
    it "is valid if no other record has same attribute value in same locale" do
      Mobility.with_locale(:ja) do
        @instance1 = model_class.create(attribute1 => "foo")
      end
      Mobility.with_locale(:'pt-BR') do
        @instance2 = model_class.new(attribute1 => "foo")
      end
      expect(@instance2).to be_valid
    end

    it "is invalid if other record has same attribute value in same locale" do
      @instance1 = model_class.create(attribute1 => "foo")
      @instance2 = model_class.new(attribute1 => "foo")
      expect(@instance2).not_to be_valid
    end
  end
end
