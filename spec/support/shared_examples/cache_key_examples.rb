shared_examples_for "cache key"  do |model_class_name, attribute=:title|
  let(:model_class) { constantize(model_class_name) }

  it "changes cache key when translation updated" do
    model = model_class.create!(attribute => "foo")
    original_cache_key = model.cache_key
    model.update_attributes!(attribute => "bar")
    expect(model.cache_key).to_not eq(original_cache_key)
  end
end
