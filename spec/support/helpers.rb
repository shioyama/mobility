module Helpers
  def stringify_keys(hash)
    result = Hash.new
    hash.each_key { |key| result[key.to_s] = hash[key] }
    result
  end

  module Backend
    def include_backend_examples *args
      it_behaves_like "Mobility backend", *args
    end
  end

  module ActiveRecord
    include Backend

    def include_accessor_examples *args
      it_behaves_like "model with translated attribute accessors", *args
    end

    def include_querying_examples *args
      it_behaves_like "AR Model with translated scope", *args
    end

    def include_serialization_examples *args
      it_behaves_like "AR Model with serialized translations", *args
    end

    def include_validation_examples *args
      it_behaves_like "AR Model validation", *args
    end
  end

  module Sequel
    include Backend

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
