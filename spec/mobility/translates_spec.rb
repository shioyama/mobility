require "spec_helper"

describe Mobility::Translates, orm: 'none' do
  include Helpers::Backend
  before { stub_const('MyClass', Class.new).extend(Mobility::Translates) }

  let(:attribute_names) { [:title, :content] }
  let(:backend) { double(:backend) }
  let(:backend_class) { backend_listener(backend) }
  let(:instance) { MyClass.new }

  shared_examples_for "reader definer" do
    it "defines reader for attributes on model" do
      Mobility.with_locale(:de) do
        expect(backend).to receive(:read).with(:de, any_args).and_return('foo')
        expect(instance.title).to eq('foo')
        expect(instance.title?).to eq(true)

        expect(backend).to receive(:read).with(:de, any_args).and_return('bar')
        expect(instance.content).to eq('bar')
        expect(instance.content?).to eq(true)
      end
    end
  end

  shared_examples_for "writer definer" do
    it "defines writer for attributes on model" do
      Mobility.with_locale(:de) do
        expect(backend).to receive(:write).with(:de, 'foo', any_args).and_return('foo')
        expect(instance.title = 'foo').to eq('foo')

        expect(backend).to receive(:write).with(:de, 'bar', any_args).and_return('bar')
        expect(instance.content = 'bar').to eq('bar')
      end
    end
  end

  describe ".mobility_accessor" do
    before do
      MyClass.mobility_accessor *attribute_names, backend: backend_class
    end

    it_behaves_like "reader definer"
    it_behaves_like "writer definer"
  end

  describe ".mobility_reader" do
    before do
      MyClass.mobility_reader *attribute_names, backend: backend_class
    end

    it_behaves_like "reader definer"

    it 'does not define writer methods' do
      allow(backend).to receive(:write)
      expect { instance.title = 'foo' }.to raise_error(NoMethodError)
    end
  end

  describe ".mobility_writer" do
    before do
      MyClass.mobility_writer *attribute_names, backend: backend_class
    end

    it_behaves_like "writer definer"

    it 'does not define reader methods' do
      allow(backend).to receive(:read)
      expect { instance.title }.to raise_error(NoMethodError)
    end
  end
end
