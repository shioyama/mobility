require "spec_helper"

describe Mobility::Plugin do
  include Helpers::Plugins
  let(:pluggable) { Class.new(Mobility::Pluggable) }
  let(:included_plugins) { pluggable.included_modules.grep(described_class) }

  describe 'dependencies' do
    define_plugins(:foo, :bar, :baz, :qux)

    describe '.configure' do
      it 'includes plugin' do
        described_class.configure(pluggable) do
          __send__ :foo
        end
        expect(included_plugins).to include(foo)
      end

      it 'updates defaults for plugin' do
        described_class.configure(pluggable) do
          __send__ :foo, 'somedefault'
        end
        expect(pluggable.defaults).to eq(foo: 'somedefault')
      end

      it 'detects before dependency conflict between two plugins' do
        foo.requires :bar, include: :before
        bar.requires :foo, include: :before
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, foo")
      end

      it 'includes pluggable name in cyclic dependency conflict message' do
        foo.requires :bar, include: :before
        bar.requires :foo, include: :before

        stub_const('Pluggable', pluggable)
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, foo in Pluggable")
      end

      it 'detects after dependency conflict between two plugins' do
        foo.requires :bar, include: :after
        bar.requires :foo, include: :after
        expect {
          described_class.configure(pluggable) do
            __send__ :foo
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::CyclicDependency,
                         "Dependencies cannot be resolved between: bar, foo")
      end

      it 'detects before dependency conflict between three plugins' do
        foo.requires :baz, include: :before
        bar.requires :foo, include: :before
        baz.requires :bar, include: :before
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
        foo.requires :baz, include: :after
        bar.requires :foo, include: :after
        baz.requires :bar, include: :after
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
        foo.requires :bar, include: :before
        baz.requires :foo, include: :before
        bar.requires :baz, include: :after

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
        bar.requires :foo, include: :after

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

      it 'includes pluggable name in after dependency conflict error message' do
        bar.requires :foo, include: :after

        described_class.configure(pluggable) do
          __send__ :foo
        end

        # Check that error message shows the pluggable name if defined
        stub_const('Pluggable', pluggable)

        expect {
          described_class.configure(pluggable) do
            __send__ :bar
          end
        }.to raise_error(Mobility::Plugin::DependencyConflict,
                         "'foo' plugin must come after 'bar' plugin in Pluggable")
      end

      it 'skips mutual before dependencies which have already been included' do
        foo.requires :baz, include: :before
        bar.requires :foo, include: :before
        bar.requires :baz, include: :before

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
        foo.requires :baz
        bar.requires :foo, include: :before
        bar.requires :baz, include: :before

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
        foo.requires :bar
        bar.requires :baz, include: :after
        baz.requires :qux, include: :before

        expect {
          described_class.configure(pluggable) do
            __send__ :foo
          end
        }.not_to raise_error

        expect(included_plugins).to match_array([foo, bar, baz, qux])
        expect(included_plugins & [baz, bar]).to eq([baz, bar])
        expect(included_plugins & [baz, qux]).to eq([baz, qux])
      end

      it 'does not include dependency for include: false' do
        foo.requires :bar, include: false

        expect {
          described_class.configure(pluggable) do
            __send__ :foo
          end
        }.not_to raise_error

        expect(included_plugins).to eq([foo])
      end

      it 'does not run hooks if direct dependency is not included for include: false' do
        # Note that foo hooks *are* run, although bar dependencies are not met.
        # So include: false is not applied recursively to dependents.
        foo.requires :bar
        bar.requires :baz, include: false

        foo_listener = double
        bar_listener = double

        foo.initialize_hook() { |*| foo_listener.initialize }
        bar.initialize_hook() { |*| bar_listener.initialize }

        foo.included_hook() { foo_listener.included }
        bar.included_hook() { bar_listener.included }

        described_class.configure(pluggable) do
          __send__ :foo
        end

        expect(foo_listener).to receive(:initialize)
        expect(bar_listener).not_to receive(:initialize)
        mod = pluggable.new

        expect(foo_listener).to receive(:included)
        expect(bar_listener).not_to receive(:included)
        Class.new.include mod
      end

      it 'does run hooks if dependency is included for include: false' do
        foo.requires :bar, include: false
        listener = double

        bar.initialize_hook do |*|
          listener.initialize
        end

        bar.included_hook do
          listener.included
        end

        described_class.configure(pluggable) do
          __send__ :foo
          __send__ :bar
        end

        expect(listener).to receive(:initialize)
        mod = pluggable.new

        expect(listener).to receive(:included)
        Class.new.include mod
      end
    end
  end
end
