# The class defined by model_class_name is assumed to have two attributes,
# defaulting to names 'title' and 'content', which are serialized.
#
shared_examples_for "AR Model with serialized translations" do |model_class_name, attribute1=:title, attribute2=:content|
  let(:model_class) { model_class_name.constantize }
  let(:backend) { instance.send(:"#{attribute1}_translations") }

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
        instance.write_attribute(attribute1, { ja: "あああ" })
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
      end
    end

    context "multiple serialized columns have translations" do
      it "returns translation from serialized hash" do
        instance.write_attribute(attribute1, { ja: "あああ" })
        instance.write_attribute(attribute2, { en: "aaa" })
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
        other_backend = instance.send(:"#{attribute2}_translations")
        expect(other_backend.read(:ja)).to eq(nil)
        expect(other_backend.read(:en)).to eq("aaa")
      end
    end
  end

  describe "#write" do
    let(:instance) { model_class.create }

    it "assigns to serialized hash" do
      backend.write(:en, "foo")
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo" })
      backend.write(:fr, "bar")
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo", fr: "bar" })
    end

    it "deletes keys with nil values when saving" do
      backend.write(:en, "foo")
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo" })
      backend.write(:en, nil)
      expect(instance.read_attribute(attribute1)).to match_hash({ en: nil })
      instance.save
      expect(backend.read(:en)).to eq(nil)
      expect(instance.read_attribute(attribute1)).to match_hash({})
    end

    it "deletes keys with blank values when saving" do
      backend.write(:en, "foo")
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo" })
      instance.save
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo" })
      backend.write(:en, "")
      instance.save

      # Note: Sequel backend returns a blank string here.
      expect(backend.read(:en)).to eq(nil)

      expect(instance.send(attribute1)).to eq(nil)
      instance.reload
      expect(backend.read(:en)).to eq(nil)
      expect(instance.read_attribute(attribute1)).to eq({})
    end

    it "converts non-string types to strings when saving" do
      backend.write(:en, { foo: :bar } )
      instance.save
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "{:foo=>:bar}" })
    end

    it "correctly stores serialized attributes" do
      backend.write(:en, "foo")
      backend.write(:fr, "bar")
      instance.save
      instance = model_class.first
      backend = instance.send(:"#{attribute1}_translations")
      expect(instance.send(attribute1)).to eq("foo")
      Mobility.with_locale(:fr) { expect(instance.send(attribute1)).to eq("bar") }
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo", fr: "bar" })

      backend.write(:en, "")
      instance.save
      instance = model_class.first
      expect(instance.send(attribute1)).to eq(nil)
      expect(instance.read_attribute(attribute1)).to match_hash({ fr: "bar" })
    end
  end

  describe "Model#save" do
    let(:instance) { model_class.new }

    it "saves empty hash for serialized translations by default" do
      expect(instance.send(attribute1)).to eq(nil)
      expect(backend.read(:en)).to eq(nil)
      instance.save
      expect(instance.read_attribute(attribute1)).to eq({})
    end

    it "saves changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      instance = model_class.first
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo" })
    end
  end

  describe "Model#update" do
    let(:instance) { model_class.create }

    it "updates changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "foo" })
      instance = model_class.first
      instance.update(attribute1 => "bar")
      expect(instance.read_attribute(attribute1)).to match_hash({ en: "bar" })
    end
  end
end

shared_examples_for "Sequel Model with serialized translations" do |model_class_name, attribute1=:title, attribute2=:content|
  let(:model_class) { model_class_name.constantize }
  let(:format) { backend.options[:format] }
  let(:backend) { instance.send(:"#{attribute1}_translations") }

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
        instance.send(:"#{attribute1}_before_mobility=", { ja: "あああ" }.send("to_#{format}"))
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
      end
    end

    context "multiple serialized columns have translations" do
      it "returns translation from serialized hash" do
        instance.send(:"#{attribute1}_before_mobility=", { ja: "あああ" }.send("to_#{format}"))
        instance.send(:"#{attribute2}_before_mobility=", { en: "aaa" }.send("to_#{format}"))
        instance.save
        instance.reload

        expect(backend.read(:ja)).to eq("あああ")
        expect(backend.read(:en)).to eq(nil)
        other_backend = instance.send(:"#{attribute2}_translations")
        expect(other_backend.read(:ja)).to eq(nil)
        expect(other_backend.read(:en)).to eq("aaa")
      end
    end
  end

  describe "#write" do
    let(:instance) { model_class.create }

    it "assigns to serialized hash" do
      backend.write(:en, "foo")
      expect(instance.deserialized_values[attribute1]).to eq(en: "foo")
      backend.write(:fr, "bar")
      expect(instance.deserialized_values[attribute1]).to eq({ en: "foo", fr: "bar" })
    end

    it "deletes keys with nil values when saving" do
      backend.write(:en, "foo")
      expect(instance.deserialized_values[attribute1]).to eq({ en: "foo" })
      backend.write(:en, nil)
      expect(instance.deserialized_values[attribute1]).to eq({ en: nil })
      instance.save
      expect(backend.read(:en)).to eq(nil)
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({}.send("to_#{format}"))
    end

    it "deletes keys with blank values when saving" do
      backend.write(:en, "foo")
      expect(instance.deserialized_values[attribute1]).to eq({ en: "foo" })
      instance.save
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ en: "foo" }.send("to_#{format}"))
      backend.write(:en, "")
      instance.save

      # Backend continues to return a blank string, but does not save it,
      # because deserialized_values holds the value assigned rather than the
      # value as it was actually serialized.
      #
      # This is different from the ActiveRecord backend, where the serialized
      # value is read back, so the backend returns nil.
      # TODO: Make this return nil? (or make AR return a blank string)
      # (In practice this is not an issue since instance.title returns `value.presence`).
      expect(backend.read(:en)).to eq("")

      expect(instance.send(attribute1)).to eq(nil)
      instance.reload
      expect(backend.read(:en)).to eq(nil)
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({}.send("to_#{format}"))
    end

    it "converts non-string types to strings when saving" do
      backend.write(:en, { foo: :bar } )
      instance.save
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ en: "{:foo=>:bar}" }.send("to_#{format}"))
    end

    it "correctly stores serialized attributes" do
      backend.write(:en, "foo")
      backend.write(:fr, "bar")
      instance.save
      instance = model_class.first
      backend = instance.send(:"#{attribute1}_translations")
      expect(instance.send(attribute1)).to eq("foo")
      Mobility.with_locale(:fr) { expect(instance.send(attribute1)).to eq("bar") }
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ en: "foo", fr: "bar" }.send("to_#{format}"))

      backend.write(:en, "")
      instance.save
      instance = model_class.first
      expect(instance.send(attribute1)).to eq(nil)
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ fr: "bar" }.send("to_#{format}"))
    end
  end

  describe "Model#save" do
    let(:instance) { model_class.new }

    it "saves empty hash for serialized translations by default" do
      expect(instance.send(attribute1)).to eq(nil)
      expect(backend.read(:en)).to eq(nil)
      instance.save
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({}.send("to_#{format}"))
    end

    it "saves changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      instance = model_class.first
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ en: "foo" }.send("to_#{format}"))
    end
  end

  describe "Model#update" do
    let(:instance) { model_class.create }

    it "updates changes to translations" do
      instance.send(:"#{attribute1}=", "foo")
      instance.save
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ en: "foo" }.send("to_#{format}"))
      instance = model_class.first
      instance.update(attribute1 => "bar")
      expect(instance.send(:"#{attribute1}_before_mobility")).to eq({ en: "bar" }.send("to_#{format}"))
    end
  end
end
