# The class defined by model_class_name is assumed to have two attributes,
# defaulting to names 'title' and 'content', which are serialized.
#
shared_examples_for "AR Model with serialized translations" do |model_class_name, attribute1=:title, attribute2=:content, column_affix: '%s'|
  let(:model_class) { model_class_name.constantize }
  let(:backend) { instance.mobility_backends[attribute1.to_sym] }
  let(:column1) { column_affix % attribute1 }
  let(:column2) { column_affix % attribute2 }

  describe "#read" do
    let(:instance) { model_class.new }

    context "with nil serialized column" do
      it "returns nil in any locale" do
        expect(backend.read(:en)).to eq(nil)
        expect(backend.read(:ja)).to eq(nil)
      end
    end

    context "with serialized column" do
      it "returns translation from serialized hash" do
        instance.send :write_attribute, column1, { ja: "あああ" }
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
      end
    end

    context "multiple serialized columns have translations" do
      it "returns translation from serialized hash" do
        instance.send :write_attribute, column1, { ja: "あああ" }
        instance.send :write_attribute, column2, { en: "aaa" }
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
        other_backend = instance.mobility_backends[attribute2.to_sym]
        expect(other_backend.read(:ja)).to eq(nil)
        expect(other_backend.read(:en)).to eq("aaa")
      end
    end
  end

  describe "#write" do
    let(:instance) { model_class.create }

    it "assigns to serialized hash" do
      backend.write(:en, "foo")
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo" })
      backend.write(:fr, "bar")
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo", fr: "bar" })
    end

    it "leaves keys with blank values when saving" do
      backend.write(:en, "foo")
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo" })
      instance.save
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo" })
      backend.write(:en, "")
      instance.save

      # Note: Sequel backend and Rails < 5.0 return a blank string here.
      expect(backend.read(:en)).to eq("")

      expect(instance.send(attribute1)).to eq("")
      instance.reload
      expect(backend.read(:en)).to eq("")
      expect(instance.read_attribute(column1)).to match_hash({ en: "" })
    end

    it "correctly stores serialized attributes" do
      backend.write(:en, "foo")
      backend.write(:fr, "bar")
      instance.save
      instance = model_class.first
      backend = instance.mobility_backends[attribute1.to_sym]
      expect(instance.send(attribute1)).to eq("foo")
      Mobility.with_locale(:fr) { expect(instance.send(attribute1)).to eq("bar") }
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo", fr: "bar" })

      backend.write(:en, "")
      instance.save
      instance = model_class.first
      expect(instance.send(attribute1)).to eq("")
      expect(instance.read_attribute(column1)).to match_hash({ en: "", fr: "bar" })
    end
  end

  describe "Model#save" do
    let(:instance) { model_class.new }

    it "saves empty hash for serialized translations by default" do
      expect(instance.send(attribute1)).to eq(nil)
      expect(backend.read(:en)).to eq(nil)
      instance.save
      expect(instance.read_attribute(column1)).to eq({})
    end

    it "saves changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      instance = model_class.first
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo" })
    end
  end

  describe "Model#update" do
    let(:instance) { model_class.create }

    it "updates changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      expect(instance.read_attribute(column1)).to match_hash({ en: "foo" })
      instance = model_class.first
      instance.update(attribute1 => "bar")
      expect(instance.read_attribute(column1)).to match_hash({ en: "bar" })
    end
  end
end

shared_examples_for "Sequel Model with serialized translations" do |model_class_name, attribute1=:title, attribute2=:content, column_affix: "%s"|
  include Helpers

  let(:model_class) { constantize(model_class_name) }
  let(:format) { model_class.mobility_backend_class(attribute1).options[:format] }
  let(:backend) { instance.mobility_backends[attribute1.to_sym] }
  let(:column1) { (column_affix % attribute1).to_sym }
  let(:column2) { (column_affix % attribute2).to_sym }

  def serialize(value)
    format ? value.send("to_#{format}") : stringify_keys(value)
  end

  def assign_translations(instance, column, value)
    instance[column] = serialize(value)
  end

  def get_translations(instance, column)
    if instance.respond_to?(:deserialized_values)
      instance.deserialized_values[column]
    else
      instance[column].to_hash
    end
  end

  describe "#read" do
    let(:instance) { model_class.new }

    context "with nil serialized column" do
      it "returns nil in any locale" do
        expect(backend.read(:en)).to eq(nil)
        expect(backend.read(:ja)).to eq(nil)
      end
    end

    context "serialized column has a translation" do
      it "returns translation from serialized hash" do
        assign_translations(instance, column1, { ja: "あああ" })
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
      end
    end

    context "multiple serialized columns have translations" do
      it "returns translation from serialized hash" do
        assign_translations(instance, column1, { ja: "あああ" })
        assign_translations(instance, column2, { en: "aaa" })
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
        other_backend = instance.mobility_backends[attribute2.to_sym]
        expect(other_backend.read(:ja)).to eq(nil)
        expect(other_backend.read(:en)).to eq("aaa")
      end
    end
  end

  describe "#write" do
    let(:instance) { model_class.create }

    it "assigns to serialized hash" do
      backend.write(:en, "foo")
      expect(get_translations(instance, column1)).to match_hash({ en: "foo" })
      backend.write(:fr, "bar")
      expect(get_translations(instance, column1)).to match_hash({ en: "foo", fr: "bar" })
    end

    it "deletes keys with nil values when saving" do
      backend.write(:en, "foo")
      expect(get_translations(instance, column1)).to match_hash({ en: "foo" })
      backend.write(:en, nil)
      expect(get_translations(instance, column1)).to match_hash({ en: nil })
      instance.save
      expect(backend.read(:en)).to eq(nil)
      expect(instance[column1]).to eq(serialize({}))
    end

    it "leaves keys with blank values when saving" do
      backend.write(:en, "foo")
      expect(get_translations(instance, column1)).to match_hash({ en: "foo" })
      instance.save
      expect(instance[column1]).to eq(serialize({ en: "foo" }))
      backend.write(:en, "")
      instance.save

      expect(backend.read(:en)).to eq("")
      expect(instance.send(attribute1)).to eq("")

      instance.reload
      expect(backend.read(:en)).to eq("")
      expect(instance[column1]).to eq(serialize({ en: "" }))
    end

    it "correctly stores serialized attributes" do
      backend.write(:en, "foo")
      backend.write(:fr, "bar")
      instance.save
      instance = model_class.first
      backend = instance.mobility_backends[attribute1.to_sym]
      expect(instance.send(attribute1)).to eq("foo")
      Mobility.with_locale(:fr) { expect(instance.send(attribute1)).to eq("bar") }
      expect(instance[column1]).to eq(serialize({ en: "foo", fr: "bar" }))

      backend.write(:en, "")
      instance.save
      instance = model_class.first
      expect(instance.send(attribute1)).to eq("")
      expect(instance[column1]).to eq(serialize({ en: "", fr: "bar" }))
    end
  end

  describe "Model#save" do
    let(:instance) { model_class.new }

    it "saves empty hash for serialized translations by default" do
      expect(instance.send(attribute1)).to eq(nil)
      expect(backend.read(:en)).to eq(nil)
      instance.save
      expect(instance[column1]).to eq(serialize({}))
    end

    it "saves changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      instance = model_class.first
      expect(instance[column1]).to eq(serialize({ en: "foo" }))
    end
  end

  describe "Model#update" do
    let(:instance) { model_class.create }

    it "updates changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      expect(instance[column1]).to eq(serialize({ en: "foo" }))
      instance = model_class.first
      instance.update(attribute1 => "bar")
      expect(instance[column1]).to eq(serialize({ en: "bar" }))
    end
  end
end
