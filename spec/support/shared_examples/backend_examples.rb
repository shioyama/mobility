shared_examples_for "Mobility backend" do |backend_class, model_class, attribute="title"|
  describe "accessors" do
    it "can be called without options hash" do
      model_class = model_class.constantize if model_class.is_a?(String)

      # Reproduce backend setup in Mobility::Attributes
      options = { model_class: model_class }
      backend_class.configure(options) if backend_class.respond_to?(:configure)
      backend_class.setup_model(model_class, [attribute], options)
      backend = Class.new(backend_class).new(model_class.new, attribute, options)
      # end

      backend.write(Mobility.locale, "foo")
      backend.read(Mobility.locale)
      expect(backend.read(Mobility.locale)).to eq("foo")
    end
  end
end
