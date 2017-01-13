module Helpers
  module ActiveRecord
    def include_querying_examples(model_class_name, *attributes)
      it_behaves_like "AR Model with translated scope", model_class_name, *attributes
    end

    def include_serialization_examples(model_class_name, *attributes)
      it_behaves_like "AR Model with serialized translations", model_class_name, *attributes
    end
  end

  module Sequel
    def include_querying_examples(model_class_name, *attributes)
      it_behaves_like "Sequel Model with translated dataset", model_class_name, *attributes
    end

    def include_serialization_examples(model_class_name, *attributes)
      it_behaves_like "Sequel Model with serialized translations", model_class_name, *attributes
    end
  end
end
