require "spec_helper"

describe Mobility::Plugin do
  let(:pluggable) { Class.new(Module) }

  describe 'dependencies' do
    def self.define_plugin(name)
      let!(name) do
        Module.new.tap do |mod|
          mod.extend Mobility::Plugin
          Mobility::Plugins.register_plugin(name, mod)
          stub_const(name.to_s.capitalize, mod)
        end
      end
    end

    define_plugin(:foo)
    define_plugin(:bar)
    define_plugin(:baz)

    after do
      plugins = Mobility::Plugins.instance_variable_get(:@plugins)
      plugins.delete(:foo)
      plugins.delete(:bar)
      plugins.delete(:baz)
    end

    describe '.configure' do
      it 'includes plugin' do
        described_class.configure(pluggable) do
          __send__ :foo
        end
        expect(pluggable.included_modules).to include(foo)
      end

      it 'detects before dependency conflict between two plugins' do
        foo.depends_on :bar, include: :before
        bar.depends_on :foo, include: :before
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency)
      end

      it 'detects after dependency conflict between two plugins' do
        foo.depends_on :bar, include: :after
        bar.depends_on :foo, include: :after
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency)
      end

      it 'detects before dependency conflict between three plugins' do
        foo.depends_on :baz, include: :before
        bar.depends_on :foo, include: :before
        baz.depends_on :bar, include: :before
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
            __send__ :baz
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency)
      end

      it 'detects after dependency conflict between three plugins' do
        foo.depends_on :baz, include: :after
        bar.depends_on :foo, include: :after
        baz.depends_on :bar, include: :after
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
            __send__ :baz
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency)
      end

      it 'correctly includes plugins with no dependency conflicts' do
        foo.depends_on :bar, include: :before
        baz.depends_on :foo, include: :before
        bar.depends_on :baz, include: :after

        expect {
          described_class.configure(pluggable) do
            __send__ :baz
            __send__ :bar
            __send__ :foo
          end
        }.not_to raise_error

        expect(pluggable.included_modules.grep(Mobility::Plugin)).to eq([baz, foo, bar])
      end

      it 'raises CyclicDependency error if plugin has after dependency on previously included plugin' do
        bar.depends_on :foo, include: :after

        described_class.configure(pluggable) do
          __send__ :foo
        end

        expect {
          described_class.configure(pluggable) do
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency)
      end
    end
  end
end
