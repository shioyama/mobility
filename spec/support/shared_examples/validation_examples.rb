shared_examples_for "AR Model validation" do |model_class_name, attribute1=:title, attribute2=:content|
  describe "Uniqueness validation" do
    context "without scope" do
      let(:model_class) do
        model_class = model_class_name.constantize
        model_class.class_eval do
          validates attribute1, uniqueness: true
        end
        model_class
      end

      it "is valid if no other record has same attribute value in same locale" do
        @instance1 = model_class.create(attribute1 => "foo")
        Mobility.with_locale(:ja) do
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

    context "with untranslated scope on translated attribute" do
      let(:model_class) do
        model_class = model_class_name.constantize
        model_class.class_eval do
          validates attribute1, uniqueness: { scope: :published }
        end
        model_class
      end

      it "is valid if no other record has same attribute value in same locale, for the same scope" do
        @instance1 = model_class.create(attribute1 => "foo", published: true)
        @instance2 = model_class.new(attribute1    => "foo", published: false)
        expect(@instance2).to be_valid
      end

      it "is invalid if other record has same attribute value in same locale, for the same scope" do
        @instance1 = model_class.create(attribute1 => "foo", published: true)
        @instance2 = model_class.new(attribute1    => "foo", published: true)
        Mobility.with_locale(:ja) do
          @instance3 = model_class.new(attribute1  => "foo", published: true)
        end
        expect(@instance2).not_to be_valid
        expect(@instance3).to be_valid
      end
    end

    context "with translated scope on translated attribute" do
      let(:model_class) do
        model_class = model_class_name.constantize
        model_class.class_eval do
          validates attribute1, uniqueness: { scope: attribute2 }
        end
        model_class
      end

      it "is valid if no other record has same attribute value in same locale, for the same scope" do
        @instance1 = model_class.create(attribute1 => "foo", attribute2 => "bar")
        @instance2 = model_class.new(attribute1    => "foo", attribute2 => "baz")
        expect(@instance2).to be_valid
      end

      it "is invalid if other record has same attribute value in same locale, for the same scope" do
        @instance1 = model_class.create(attribute1 => "foo", attribute2 => "bar")
        @instance2 = model_class.new(attribute1    => "foo", attribute2 => "bar")
        Mobility.with_locale(:ja) do
          @instance3 = model_class.new(attribute1  => "foo", attribute2 => "bar")
        end
        expect(@instance2).not_to be_valid
        expect(@instance3).to be_valid
      end
    end

    context "with translated scope on untranslated attribute" do
      let(:model_class) do
        model_class = model_class_name.constantize
        model_class.class_eval do
          validates :published, uniqueness: { :scope => attribute1 }
        end
        model_class
      end

      it "is valid if no other record has same attribute value, for the same scope in same locale" do
        @instance1 = model_class.create(published: true, attribute1 => "foo")
        @instance2 = model_class.new(published: true,    attribute1 => "baz")
        expect(@instance2).to be_valid
      end

      it "is invalid if other record has same attribute value in same locale, for the same scope" do
        @instance1 = model_class.create(published: true, attribute1 => "foo")
        @instance2 = model_class.new(published:    true, attribute1 => "foo")
        Mobility.with_locale(:ja) do
          @instance3 = model_class.new(published:  true, attribute1 => "foo")
        end
        expect(@instance2).not_to be_valid
        expect(@instance3).to be_valid
      end
    end

    context "case insensitive validation on translated attribute" do
      let(:model_class) do
        model_class = model_class_name.constantize
        model_class.class_eval do
          validates attribute1, uniqueness: { case_sensitive: true }
        end
        model_class
      end

      it "is invalid if other record has same attribute LOWER(value)" do
        @instance1 = model_class.create(published: true, attribute1 => "foo")
        @instance2 = model_class.new(published: true,    attribute1 => "foO")
        expect(@instance2).not_to be_valid
      end
    end

    context "uniqueness validation on untranslated attribute" do
      let(:model_class) do
        model_class = model_class_name.constantize
        model_class.class_eval do
          validates :published, uniqueness: true
        end
        model_class
      end

      it "is valid if no other record has same attribute value" do
        @instance1 = model_class.create(published: true)
        @instance2 = model_class.new(published: false)
        expect(@instance2).to be_valid
      end

      it "is invalid if other record has same attribute value in same locale" do
        @instance1 = model_class.create(published: true)
        @instance2 = model_class.new(published: true)
        Mobility.with_locale(:ja) do
          @instance3 = model_class.new(published: true)
        end
        expect(@instance2).not_to be_valid
        expect(@instance3).not_to be_valid
      end
    end
  end
end
