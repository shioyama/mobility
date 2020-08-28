shared_examples_for "dupable model"  do |model_class_name, attribute=:title|
  let(:model_class) { constantize(model_class_name) }

  it "dups persisted model" do
    skip_if_duping_not_implemented
    instance = model_class.new
    instance_backend = backend_for(instance, attribute)
    instance_backend.write(:en, "foo")
    instance_backend.write(:ja, "ほげ")
    save_or_raise(instance)

    dupped_instance = instance.dup
    dupped_backend = backend_for(dupped_instance, attribute)
    expect(dupped_backend.read(:en)).to eq("foo")
    expect(dupped_backend.read(:ja)).to eq("ほげ")

    save_or_raise(dupped_instance)
    expect(dupped_instance.send(attribute)).to eq(instance.send(attribute))

    if ENV['ORM'] == 'active_record'
      # Ensure duped instances are pointing to different objects
      instance_backend.write(:en, "bar")
      expect(dupped_backend.read(:en)).to eq("foo")
    end

    # Ensure we haven't mucked with the original instance
    instance.reload

    expect(instance_backend.read(:en)).to eq("foo")
    expect(instance_backend.read(:ja)).to eq("ほげ")
  end

  it "dups new record" do
    skip_if_duping_not_implemented
    instance = model_class.new(attribute => "foo")
    dupped_instance = instance.dup

    expect(instance.send(attribute)).to eq("foo")
    expect(dupped_instance.send(attribute)).to eq("foo")

    save_or_raise(instance)
    save_or_raise(dupped_instance)

    if ENV['ORM'] == 'active_record'
      instance.send("#{attribute}=", "bar")
      expect(dupped_instance.send(attribute)).to eq("foo")
    end

    # Ensure we haven't mucked with the original instance
    instance.reload
    dupped_instance.reload

    expect(instance.send(attribute)).to eq("foo")
    expect(dupped_instance.send(attribute)).to eq("foo")
  end

  def save_or_raise(instance)
    if instance.respond_to?(:save!)
      instance.save!
    else
      instance.save
    end
  end

  def skip_if_duping_not_implemented
    if ENV['ORM'] == 'sequel'
      require "mobility/backends/key_value"
      skip "Duping has not been properly implemented" if described_class < Mobility::Backends::KeyValue
    end
  end
end
