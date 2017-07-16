require "spec_helper"

describe Mobility::Backend::Dirty do
  describe ".apply" do
    context "option value is truthy" do
      let(:attributes) do
        instance_double(Mobility::Attributes, backend_class: backend_class, model_class: model_class, names: ["title"])
      end
      let(:backend_class) { Class.new }
      before do
        expect(Mobility::FallthroughAccessors).to receive(:apply).with(attributes, true)
      end

      context "model_class includes ActiveModel::Dirty", orm: :active_record do
        context "model_class is an ActiveRecord::Base" do
          let(:model_class) { Class.new(ActiveRecord::Base) }

          it "includes Backend::ActiveRecord::Dirty into backend class" do
            expect(backend_class).to receive(:include).with(Mobility::Backend::ActiveRecord::Dirty)
            methods = instance_double(Mobility::Backend::ActiveRecord::Dirty::MethodsBuilder)
            expect(Mobility::Backend::ActiveRecord::Dirty::MethodsBuilder).to receive(:new).with("title").and_return(methods)
            expect(attributes).to receive(:include).with(methods)
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
            methods = instance_double(Mobility::Backend::ActiveModel::Dirty::MethodsBuilder)
            expect(Mobility::Backend::ActiveModel::Dirty::MethodsBuilder).to receive(:new).with("title").and_return(methods)
            expect(attributes).to receive(:include).with(methods)
            described_class.apply(attributes, true)
          end
        end
      end

      context "options[:model_class] is a Sequel::Model", orm: :sequel do
        let(:model_class) { Class.new(Sequel::Model) }

        it "includes Backend::ActiveRecord::Sequel into backend class" do
          expect(backend_class).to receive(:include).with(Mobility::Backend::Sequel::Dirty)
          methods = instance_double(Mobility::Backend::Sequel::Dirty::MethodsBuilder)
          expect(Mobility::Backend::Sequel::Dirty::MethodsBuilder).to receive(:new).with("title").and_return(methods)
          expect(attributes).to receive(:include).with(methods)
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
