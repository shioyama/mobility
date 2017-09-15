shared_examples_for "AR integration" do |model_class_name, attribute=:title|
  let(:model_class) { model_class_name.constantize }

  it "persits with update_attribute" do
    model = model_class.create(attribute => "foo")
    expect(model.update_attribute(attribute, "bar")).to eq(true)
    expect(model.send(attribute)).to eq("bar")
    expect(model.reload.send(attribute)).to eq("bar")
  end
end
