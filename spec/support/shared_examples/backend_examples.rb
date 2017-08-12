shared_examples_for "Mobility backend" do |backend_class, model_class, attribute="title"|
  let(:backend) do
    model_class = model_class.constantize if model_class.is_a?(String)

    options = { model_class: model_class }
    backend_class.configure(options) if backend_class.respond_to?(:configure)
    backend_class.setup_model(model_class, [attribute], options)

    Class.new(backend_class).new(model_class.new, attribute, options)
  end

  describe "accessors" do
    it "can be called without options hash" do
      backend.write(Mobility.locale, "foo")
      backend.read(Mobility.locale)
      expect(backend.read(Mobility.locale)).to eq("foo")
    end
  end

  describe "iterators" do
    it "iterates through locales" do
      backend.write(:en, "foo")
      backend.write(:ja, "bar")
      backend.write(:ru, "baz")

      expect { |b| backend.each_locale &b }.to yield_successive_args(:en, :ja, :ru)
      expect { |b| backend.each &b }.to yield_successive_args(
        Mobility::Backend::Translation.new(backend, :en),
        Mobility::Backend::Translation.new(backend, :ja),
        Mobility::Backend::Translation.new(backend, :ru))
      expect(backend.locales).to eq([:en, :ja, :ru])
    end
  end
end
