# Basic test of translated attribute accessors which can be applied to any backend, and (since there
# is no ORM-specific code here) to any ORM.
shared_examples_for "model with translated attribute accessors" do |model_class_name, attribute1=:title, attribute2=:content, **options|
  let(:model_class) { model_class_name.constantize }
  let(:instance) { model_class.new }

  it "gets and sets translations in one locale" do
    aggregate_failures do
      instance.public_send(:"#{attribute1}=", "foo")
      expect(instance.public_send(attribute1)).to eq("foo")

      instance.public_send(:"#{attribute2}=", "bar")
      expect(instance.public_send(attribute2)).to eq("bar")

      instance.save

      instance = model_class.first

      expect(instance.public_send(attribute1)).to eq("foo")
      expect(instance.public_send(attribute2)).to eq("bar")
    end
  end

  it "gets and sets translations in multiple locales" do
    aggregate_failures do
      instance.public_send(:"#{attribute1}=", "foo")
      instance.public_send(:"#{attribute2}=", "bar")
      Mobility.with_locale(:ja) do
        instance.public_send(:"#{attribute1}=", "あああ")
      end

      expect(instance.public_send(attribute1)).to eq("foo")
      expect(instance.public_send(attribute2)).to eq("bar")
      Mobility.with_locale(:ja) do
        expect(instance.public_send(attribute1)).to eq("あああ")
        expect(instance.public_send(attribute2)).to eq(nil)
      end

      instance.save

      instance = model_class.first

      expect(instance.public_send(attribute1)).to eq("foo")
      expect(instance.public_send(attribute2)).to eq("bar")

      Mobility.with_locale(:ja) do
        expect(instance.public_send(attribute1)).to eq("あああ")
        expect(instance.public_send(attribute2)).to eq(nil)
      end
    end
  end

  it "sets translations in multiple locales when creating and saving model" do
    aggregate_failures do
      instance = model_class.create(attribute1 => "foo", attribute2 => "bar")

      expect(instance.send(attribute1)).to eq("foo")
      expect(instance.send(attribute2)).to eq("bar")

      Mobility.with_locale(:ja) { instance.send("#{attribute1}=", "あああ") }
      instance.save

      instance = model_class.first

      expect(instance.send(attribute1)).to eq("foo")
      Mobility.with_locale(:ja) { expect(instance.send(attribute1)).to eq("あああ") }
      Mobility.with_locale(:ja) { expect(instance.send(attribute2)).to eq(nil) }
    end
  end

  it "sets translations in multiple locales when updating model" do
    # TODO: get Sequel serialized + table backends to pass this spec
    model_class.mobility.modules.map(&:backend_name).each do |backend_name|
      skip if %i[table serialized].include?(backend_name)
    end if Mobility::Loaded::Sequel

    aggregate_failures do
      instance = model_class.create

      instance.update(attribute1 => "foo")
      Mobility.with_locale(:ja) { instance.update(attribute1 => "あああ") }

      instance = model_class.first

      expect(instance.send(attribute1)).to eq("foo")
      Mobility.with_locale(:ja) { expect(instance.send(attribute1)) }.to eq("あああ")
    end
  end
end
