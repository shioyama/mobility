require "spec_helper"

describe Mobility::Plugin do
  let(:pluggable) { Class.new(Module) }
  let(:included_plugins) { pluggable.included_modules.grep(described_class) }

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
    define_plugin(:qux)

    after do
      plugins = Mobility::Plugins.instance_variable_get(:@plugins)
      plugins.delete(:foo)
      plugins.delete(:bar)
      plugins.delete(:baz)
      plugins.delete(:qux)
    end

    describe '.configure' do
      it 'includes plugin' do
        described_class.configure(pluggable) do
          __send__ :foo
        end
        expect(included_plugins).to include(foo)
      end

      it 'detects before dependency conflict between two plugins' do
        foo.depends_on :bar, include: :before
        bar.depends_on :foo, include: :before
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, foo")
      end

      it 'detects after dependency conflict between two plugins' do
        foo.depends_on :bar, include: :after
        bar.depends_on :foo, include: :after
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, foo")
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
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, baz, foo")
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
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, baz, foo")
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

        expect(included_plugins).to eq([baz, foo, bar])
      end

      it 'raises DependencyConflict error if plugin has after dependency on previously included plugin' do
        bar.depends_on :foo, include: :after

        described_class.configure(pluggable) do
          __send__ :foo
        end

        expect {
          described_class.configure(pluggable) do
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::DependencyConflict,
                         "'foo' plugin must come after 'bar' plugin")
      end

      it 'skips mutual before dependencies which have already been included' do
        foo.depends_on :baz, include: :before
        bar.depends_on :foo, include: :before
        bar.depends_on :baz, include: :before

        described_class.configure(pluggable) do
          __send__ :foo
        end

        expect {
          described_class.configure(pluggable) do
            __send__ :bar
          end
        }.not_to raise_error

        expect(included_plugins).to eq([bar, foo, baz])
      end

      it 'handles non-conflicting cyclic dependencies which have already been included' do
        foo.depends_on :baz
        bar.depends_on :foo, include: :before
        bar.depends_on :baz, include: :before

        described_class.configure(pluggable) do
          __send__ :foo
        end

        expect {
          described_class.configure(pluggable) do
            __send__ :bar
          end
        }.not_to raise_error

        last_included, *others = included_plugins
        expect(last_included).to eq(bar)
        expect(others).to match_array([foo, baz])
      end

      it 'handles multiple dependency levels' do
        foo.depends_on :bar
        bar.depends_on :baz, include: :after
        baz.depends_on :qux, include: :before

        expect {
          described_class.configure(pluggable) do
            __send__ :foo
          end
        }.not_to raise_error

        expect(included_plugins).to match_array([foo, bar, baz, qux])
        expect(included_plugins & [baz, bar]).to eq([baz, bar])
        expect(included_plugins & [baz, qux]).to eq([baz, qux])
      end
    end
  end
end
