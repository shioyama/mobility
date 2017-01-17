module Helpers
  module ActiveRecord
    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "AR Model with translated scope", *args
    end

    def include_serialization_examples *args
      it_behaves_like "AR Model with serialized translations", *args
    end
  end

  module Sequel
    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
      it_behaves_like "Sequel model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "Sequel Model with translated dataset", *args
    end

    def include_serialization_examples *args
      it_behaves_like "Sequel Model with serialized translations", *args
    end
  end
end
