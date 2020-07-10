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
          __send__ :foo, default: 'somedefault'
        end
        expect(pluggable.defaults).to eq(foo: 'somedefault')
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

      it 'includes pluggable name in cyclic dependency conflict message' do
        foo.depends_on :bar, include: :before
        bar.depends_on :foo, include: :before

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

      it 'includes pluggable name in after dependency conflict error message' do
        bar.depends_on :foo, include: :after

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

      it 'does not include dependency for include: false' do
        foo.depends_on :bar, include: false

        expect {
          described_class.configure(pluggable) do
            __send__ :foo
          end
        }.not_to raise_error

        expect(included_plugins).to eq([foo])
      end

      it 'does not run hooks if dependency is not included for include: false' do
        foo.depends_on :bar, include: false
        listener = double

        bar.initialize_hook do |*|
          listener.initialize
        end

        bar.included_hook do
          listener.included
        end

        described_class.configure(pluggable) do
          __send__ :foo
        end

        expect(listener).not_to receive(:initialize)
        mod = pluggable.new

        expect(listener).not_to receive(:included)
        Class.new.include mod
      end

      it 'does run hooks if dependency is included for include: false' do
        foo.depends_on :bar, include: false
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
