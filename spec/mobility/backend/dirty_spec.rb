require "spec_helper"

describe Mobility::Backend::Dirty do
  describe ".apply" do
    context "option value is truthy" do
      let(:attributes) do
        instance_double(Mobility::Attributes, backend_class: backend_class, options: options)
      end
      let(:backend_class) { double("backend class") }
      let(:options) { { model_class: model_class } }
      before do
        expect(Mobility::FallthroughAccessors).to receive(:apply).with(attributes, true)
      end

      context "options[:model_class] includes ActiveModel::Dirty", orm: :active_record do
        context "options[:model_class] is an ActiveRecord::Base" do
          let(:model_class) { Class.new(ActiveRecord::Base) }

          it "includes Backend::ActiveRecord::Dirty into backend class" do
            expect(backend_class).to receive(:include).with(Mobility::Backend::ActiveRecord::Dirty)
            described_class.apply(attributes, true)
          end
        end

        context "options[:model_class] is not an ActiveRecord::Base" do
          let(:model_class) do
            klass = Class.new
            klass.include(ActiveModel::Dirty)
            klass
          end

          it "includes Backend::ActiveModel::Dirty into backend class" do
            expect(backend_class).to receive(:include).with(Mobility::Backend::ActiveModel::Dirty)
            described_class.apply(attributes, true)
          end
        end
      end

      context "options[:model_class] is a Sequel::Model", orm: :sequel do
        let(:model_class) { Class.new(Sequel::Model) }

        it "includes Backend::ActiveRecord::Sequel into backend class" do
          expect(backend_class).to receive(:include).with(Mobility::Backend::Sequel::Dirty)
          described_class.apply(attributes, true)
        end
      end
    end

    context "optoin value is falsey" do
      let(:attributes) { instance_double(Mobility::Attributes) }

      it "does not include Mobility::FallthroughAccessors" do
        expect(Mobility::FallthroughAccessors).not_to receive(:apply)
        described_class.apply(attributes, false)
      end

      it "does not include anything into backend class" do
        expect(attributes).not_to receive(:backend_class)
        described_class.apply(attributes, false)
      end
    end
  end
end
