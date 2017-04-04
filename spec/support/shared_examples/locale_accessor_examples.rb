shared_examples_for "locale accessor" do |attribute, locale|
  it "handles getters and setters in any locale in I18n.available_locales" do
    instance = model_class.new

    aggregate_failures "getter" do
      expect(instance).to receive(attribute).with(these: "options") do
        expect(Mobility.locale).to eq(locale)
      end.and_return("foo")
      expect(instance.send(:"#{attribute}_#{locale}", options)).to eq("foo")
    end

    aggregate_failures "presence" do
      expect(instance).to receive(:"#{attribute}?").with(these: "options") do
        expect(Mobility.locale).to eq(locale)
      end.and_return(true)
      expect(instance.send(:"#{attribute}_#{locale}?", options)).to eq(true)
    end

    aggregate_failures "setter" do
      expect(instance).to receive(:"#{attribute}=").with("value", these: "options") do
        expect(Mobility.locale).to eq(locale)
      end.and_return("value")
      expect(instance.send(:"#{attribute}_#{locale}=", "value", options)).to eq("value")
    end
  end
end
