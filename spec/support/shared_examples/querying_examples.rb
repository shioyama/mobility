shared_examples_for "AR Model with translated scope" do |model_class_name, a1=:title, a2=:content|
  let(:model_class) { model_class_name.constantize }
  let(:query_scope) { model_class.i18n }

  describe ".where" do
    context "querying on one translated attribute" do
      before do
        @instance1 = model_class.create(a1 => "foo")
        @instance2 = model_class.create(a1 => "bar")
        @instance3 = model_class.create(a1 => "baz", published: true)
        @instance4 = model_class.create(a1 => "baz", published: false)
        @instance5 = model_class.create(a1 => "foo", published: true)
      end

      it "returns correct result searching on unique attribute value" do
        expect(query_scope.where(a1 => "bar")).to eq([@instance2])
      end

      it "returns correct results when query matches multiple records" do
        expect(query_scope.where(a1 => "foo")).to match_array([@instance1, @instance5])
      end

      it "returns correct result when querying on translated and untranslated attributes" do
        expect(query_scope.where(a1 => "baz", published: true)).to eq([@instance3])
      end

      it "returns correct result when querying on nil values" do
        instance = model_class.create(a1 => nil)
        expect(query_scope.where(a1 => nil)).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(a1 => "foo ja")
            @ja_instance2 = model_class.create(a1 => "foo")
          end
        end

        it "returns correct result when querying on same attribute value in different locale" do
          expect(query_scope.where(a1 => "foo")).to match_array([@instance1, @instance5])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(a1 => "foo ja")).to eq([@ja_instance1])
            expect(query_scope.where(a1 => "foo")).to eq([@ja_instance2])
          end
        end
      end

      context "with exists?" do
        it "returns correct result searching on unique attribute value" do
          aggregate_failures do
            expect(query_scope.where(a1 => "bar").exists?).to eq(true)
            expect(query_scope.where(a1 => "aaa").exists?).to eq(false)
          end
        end
      end
    end

    context "with two translated attributes" do
      before do
        @instance1 = model_class.create(a1 => "foo"                                       )
        @instance2 = model_class.create(a1 => "foo", a2 => "foo content"                  )
        @instance3 = model_class.create(a1 => "foo", a2 => "foo content", published: false)
        @instance4 = model_class.create(             a2 => "foo content"                  )
        @instance5 = model_class.create(a1 => "bar", a2 => "bar content"                  )
        @instance6 = model_class.create(a1 => "bar",                      published: true )
      end

      # @note Regression spec
      it "does not modify scope in-place" do
        query_scope.where(a1 => "foo")
        expect(query_scope.to_sql).to eq(model_class.all.to_sql)
      end

      it "returns correct results querying on one attribute" do
        expect(query_scope.where(a1 => "foo")).to match_array([@instance1, @instance2, @instance3])
        expect(query_scope.where(a2 => "foo content")).to match_array([@instance2, @instance3, @instance4])
      end

      it "returns correct results querying on two attributes in single where call" do
        expect(query_scope.where(a1 => "foo", a2 => "foo content")).to match_array([@instance2, @instance3])
      end

      it "returns correct results querying on two attributes in separate where calls" do
        expect(query_scope.where(a1 => "foo").where(a2 => "foo content")).to match_array([@instance2, @instance3])
      end

      it "returns correct result querying on two translated attributes and untranslated attribute" do
        expect(query_scope.where(a1 => "foo", a2 => "foo content", published: false)).to eq([@instance3])
      end

      it "works with nil values" do
        expect(query_scope.where(a1 => "foo", a2 => nil)).to eq([@instance1])
        expect(query_scope.where(a1 => "foo").where(a2 => nil)).to eq([@instance1])
        instance = model_class.create
        expect(query_scope.where(a1 => nil, a2 => nil)).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(a1 => "foo ja", a2 => "foo content ja")
            @ja_instance2 = model_class.create(a1 => "foo",    a2 => "foo content"   )
            @ja_instance3 = model_class.create(a1 => "foo"                           )
            @ja_instance4 = model_class.create(                a2 => "foo"           )
          end
        end

        it "returns correct result when querying on same attribute values in different locale" do
          expect(query_scope.where(a1 => "foo", a2 => "foo content")).to match_array([@instance2, @instance3])
          expect(query_scope.where(a1 => "foo", a2 => nil)).to eq([@instance1])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(a1 => "foo")).to match_array([@ja_instance2, @ja_instance3])
            expect(query_scope.where(a1 => "foo", a2 => "foo content")).to eq([@ja_instance2])
            expect(query_scope.where(a1 => "foo ja", a2 => "foo content ja")).to eq([@ja_instance1])
          end
        end
      end
    end

    context "with array of values" do
      before do
        @instance1 = model_class.create(a1 => "foo")
        @instance2 = model_class.create(a1 => "bar")
        @instance3 = model_class.create(a1 => "baz")
        @instance4 = model_class.create(a1 => nil)

        Mobility.with_locale(:ja) do
          @ja_instance1 = model_class.create(a1 => "foo")
        end
      end

      it "returns records with matching translated attribute values" do
        expect(query_scope.where(a1 => ["foo", "baz"])).to match_array([@instance1, @instance3])
        expect(query_scope.where(a1 => ["foo", nil])).to match_array([@instance1, @instance4, @ja_instance1])
      end

      it "collapses clauses in array of values" do
        instance = model_class.create(a1 => "baz")
        expect(query_scope.where(a1 => ["foo", nil, nil])).to match_array([@instance1, @instance4, @ja_instance1])
        expect(query_scope.where(a1 => ["foo", "foo", nil])).to match_array([@instance1, @instance4, @ja_instance1])
        aggregate_failures do
          expect(query_scope.where(a1 => ["foo", nil]).to_sql).to eq(query_scope.where(a1 => ["foo", nil, nil]).to_sql)
          expect(query_scope.where(a1 => ["foo", nil]).to_sql).to eq(query_scope.where(a1 => ["foo", "foo", nil]).to_sql)
        end
      end
    end

    context "with single table inheritance" do
      let(:sti_model) { Class.new(model_class) }

      it "works with sti model" do
        instance = sti_model.create(a1 => "foo")
        sti_model.i18n.where(a1 => "foo")
        expect(sti_model.i18n.where(a1 => "foo")).to match_array([instance])
      end
    end
  end

  describe ".not" do
    before do
      @instance1 = model_class.create(a1 => "foo"                                       )
      @instance2 = model_class.create(a1 => "foo", a2 => "foo content"                  )
      @instance3 = model_class.create(a1 => "foo", a2 => "foo content", published: false)
      @instance4 = model_class.create(             a2 => "foo content"                  )
      @instance5 = model_class.create(a1 => "bar", a2 => "bar content", published: true )
      @instance6 = model_class.create(a1 => "bar", a2 => "baz content", published: false)
      @instance7 = model_class.create(                                  published: true )
    end

    # @note Regression spec
    it "does not modify scope in-place" do
      query_scope.where.not(a1 => nil)
      expect(query_scope.to_sql).to eq(model_class.all.to_sql)
    end

    it "works with nil values" do
      expect(query_scope.where.not(a1 => nil)).to match_array([@instance1, @instance2, @instance3, @instance5, @instance6])
      expect(query_scope.where.not(a1 => nil).where.not(a2 => nil)).to match_array([@instance2, @instance3, @instance5, @instance6])
      expect(query_scope.where(a1 => nil).where.not(a2 => nil)).to eq([@instance4])
    end

    it "returns record without translated attribute value" do
      expect(query_scope.where.not(a1 => "foo")).to match_array([@instance5, @instance6])
    end

    it "returns record without set of translated attribute values" do
      expect(query_scope.where.not(a1 => "foo", a2 => "baz content")).to match_array([@instance5])
    end

    it "works in combination with untranslated attributes" do
      expect(query_scope.where.not(a1 => "foo", published: true)).to eq([@instance6])
    end

    it "works with array of values" do
      instance = model_class.create(a1 => "baz")
      aggregate_failures do
        expect(query_scope.where.not(a1 => ["foo", "bar"])).to match_array([instance])
        expect(query_scope.where.not(a1 => ["foo", nil])).to match_array([instance, @instance5, @instance6])
      end
    end

    it "collapses clauses in array of values" do
      instance = model_class.create(a1 => "baz")
      expect(query_scope.where.not(a1 => ["foo", nil, nil])).to match_array([instance, @instance5, @instance6])
      expect(query_scope.where.not(a1 => ["foo", "foo", nil])).to match_array([instance, @instance5, @instance6])
      aggregate_failures do
        expect(query_scope.where.not(a1 => ["foo", nil]).to_sql).to eq(query_scope.where.not(a1 => ["foo", nil, nil]).to_sql)
        expect(query_scope.where.not(a1 => ["foo", nil]).to_sql).to eq(query_scope.where.not(a1 => ["foo", "foo", nil]).to_sql)
      end
    end

    it "uses IN when matching array of two or more non-nil values" do
      aggregate_failures "where" do
        expect(query_scope.where(a1 => ["foo", "bar"]).to_sql).to match /\sIN\s/
        expect(query_scope.where(a1 => ["foo", "bar", nil]).to_sql).to match /\sIN\s/
        expect(query_scope.where(a1 => ["foo", nil]).to_sql).not_to match /\sIN\s/
        expect(query_scope.where(a1 => "foo").to_sql).not_to match /\sIN\s/
        expect(query_scope.where(a1 => nil).to_sql).not_to match /\sIN\s/
      end

      aggregate_failures "where not" do
        expect(query_scope.where.not(a1 => ["foo", "bar"]).to_sql).to match /\sIN\s/
        expect(query_scope.where.not(a1 => ["foo", "bar", nil]).to_sql).to match /\sIN\s/
        expect(query_scope.where.not(a1 => ["foo", nil]).to_sql).not_to match /\sIN\s/
        expect(query_scope.where.not(a1 => "foo").to_sql).not_to match /\sIN\s/
        expect(query_scope.where.not(a1 => nil).to_sql).not_to match /\sIN\s/
      end
    end
  end
end

shared_examples_for "Sequel Model with translated dataset" do |model_class_name, a1=:title, a2=:content|
  let(:model_class) { constantize(model_class_name) }
  let(:table_name) { model_class.table_name }
  let(:query_scope) { model_class.i18n }

  describe ".where" do
    context "querying on one translated attribute" do
      before do
        @instance1 = model_class.create(a1 => "foo")
        @instance2 = model_class.create(a1 => "bar")
        @instance3 = model_class.create(a1 => "baz", :published => true)
        @instance4 = model_class.create(a1 => "baz", :published => false)
        @instance5 = model_class.create(a1 => "foo", :published => true)
      end

      it "returns correct result searching on unique attribute value" do
        expect(query_scope.where(a1 => "bar").select_all(table_name).all).to eq([@instance2])
      end

      it "returns correct results when query matches multiple records" do
        expect(query_scope.where(a1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance5])
      end

      it "returns correct result when querying on translated and untranslated attributes" do
        expect(query_scope.where(a1 => "baz", :published => true).select_all(table_name).all).to eq([@instance3])
      end

      it "returns correct result when querying on nil values" do
        instance = model_class.create(a1 => nil)
        expect(query_scope.where(a1 => nil).select_all(table_name).all).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(a1 => "foo ja")
            @ja_instance2 = model_class.create(a1 => "foo")
          end
        end

        it "returns correct result when querying on same attribute value in different locale" do
          expect(query_scope.where(a1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance5])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(a1 => "foo ja").select_all(table_name).all).to eq([@ja_instance1])
            expect(query_scope.where(a1 => "foo").select_all(table_name).all).to eq([@ja_instance2])
          end
        end
      end
    end

    context "with two translated attributes" do
      before do
        @instance1 = model_class.create(a1 => "foo"                                       )
        @instance2 = model_class.create(a1 => "foo", a2 => "foo content"                  )
        @instance3 = model_class.create(a1 => "foo", a2 => "foo content", published: false)
        @instance4 = model_class.create(             a2 => "foo content"                  )
        @instance5 = model_class.create(a1 => "bar", a2 => "bar content"                  )
        @instance6 = model_class.create(a1 => "bar",                      published: true )
      end

      it "returns correct results querying on one attribute" do
        expect(query_scope.where(a1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance2, @instance3])
        expect(query_scope.where(a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3, @instance4])
      end

      it "returns correct results querying on two attributes in single where call" do
        expect(query_scope.where(a1 => "foo", a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
      end

      it "returns correct results querying on two attributes in separate where calls" do
        expect(query_scope.where(a1 => "foo").where(a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
      end

      it "returns correct result querying on two translated attributes and untranslated attribute" do
        expect(query_scope.where(a1 => "foo", a2 => "foo content", published: false).select_all(table_name).all).to eq([@instance3])
      end

      it "works with nil values" do
        expect(query_scope.where(a1 => "foo", a2 => nil).select_all(table_name).all).to eq([@instance1])
        expect(query_scope.where(a1 => "foo").where(a2 => nil).select_all(table_name).all).to eq([@instance1])
        instance = model_class.create
        expect(query_scope.where(a1 => nil, a2 => nil).select_all(table_name).all).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(a1 => "foo ja", a2 => "foo content ja")
            @ja_instance2 = model_class.create(a1 => "foo",    a2 => "foo content"   )
            @ja_instance3 = model_class.create(a1 => "foo"                           )
            @ja_instance4 = model_class.create(                a2 => "foo"           )
          end
        end

        it "returns correct result when querying on same attribute values in different locale" do
          expect(query_scope.where(a1 => "foo", a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
          expect(query_scope.where(a1 => "foo", a2 => nil).select_all(table_name).all).to eq([@instance1])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(a1 => "foo").select_all(table_name).all).to match_array([@ja_instance2, @ja_instance3])
            expect(query_scope.where(a1 => "foo", a2 => "foo content").select_all(table_name).all).to eq([@ja_instance2])
            expect(query_scope.where(a1 => "foo ja", a2 => "foo content ja").select_all(table_name).all).to eq([@ja_instance1])
          end
        end
      end
    end

    context "with array of values" do
      before do
        @instance1 = model_class.create(a1 => "foo")
        @instance2 = model_class.create(a1 => "bar")
        @instance3 = model_class.create(a1 => "baz")

        Mobility.with_locale(:ja) do
          @ja_instance1 = model_class.create(a1 => "foo")
        end
      end

      it "returns records with matching translated attribute values" do
        expect(query_scope.where(a1 => ["foo", "baz"]).select_all(table_name).all).to match_array([@instance1, @instance3])
      end

      it "collapses clauses in array of values" do
        expect(query_scope.where(a1 => ["foo", "foo"]).select_all(table_name).all).to match_array([@instance1])
        aggregate_failures do
          expect(query_scope.where(a1 => ["foo", "foo", nil]).sql).to eq(query_scope.where(a1 => ["foo", nil]).sql)
          expect(query_scope.where(a1 => ["foo", nil, nil]).sql).to eq(query_scope.where(a1 => ["foo", nil]).sql)
        end
      end

      it "uses IN when matching array of two or more non-nil values" do
        aggregate_failures do
          expect(query_scope.where(a1 => ["foo", "bar"]).sql).to match /\sIN\s/
          expect(query_scope.where(a1 => "foo").sql).not_to match /\sIN\s/
          expect(query_scope.where(a1 => nil).sql).not_to match /\sIN\s/
        end
      end
    end
  end

  describe ".exclude" do
    before do
      @instance1 = model_class.create(a1 => "foo"                                       )
      @instance2 = model_class.create(a1 => "foo", a2 => "baz content"                  )
      @instance3 = model_class.create(a1 => "bar", a2 => "foo content", published: false)
    end

    it "returns record without excluded attribute condition" do
      expect(query_scope.exclude(a1 => "foo").select_all(table_name).all).to match_array([@instance3])
    end

    it "returns record without excluded set of attribute conditions" do
      expect(query_scope.exclude(a1 => "foo", a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
    end

    it "works with nil values" do
      expect(query_scope.exclude(a1 => "bar", a2 => nil).select_all(table_name).all).to match_array([@instance1, @instance2, @instance3])
      expect(query_scope.exclude(a1 => "bar").exclude(a2 => nil).select_all(table_name).all).to eq([@instance2])
      expect(query_scope.exclude(a1 => nil).exclude(a2 => nil).select_all(table_name).all).to match_array([@instance2, @instance3])
    end
  end

  describe ".or" do
    before do
      @instance1 = model_class.create(a1 => "baz", a2 => "foo content", published: true )
      @instance2 = model_class.create(a1 => "foo", a2 => "baz content", published: false)
      @instance3 = model_class.create(a1 => "bar", a2 => "foo content", published: false)
    end
    let(:backend_class) { model_class.mobility_modules.first.backend_class.superclass }

    it "returns union of queries" do
      expect(query_scope.where(published: true).or(a1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance2])
    end

    it "works with set of translated and untranslated attributes" do
      # For backends that join translation tables (Table and KeyValue backends)
      # this fails because the table will be inner join'ed, excluding the
      # result which satisfies the second (or) condition. This is impossible to
      # avoid without modification of an earlier dataset, which is probably not
      # a good idea.
      skip "Not supported by #{backend_class.name}" if [Mobility::Backends::Sequel::Table, Mobility::Backends::Sequel::KeyValue].include?(backend_class)
      expect(query_scope.where(a1 => "foo").or(:published => false, a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
    end
  end

  describe "Model.i18n.first_by_<translated attribute>" do
    let(:finder_method) { :"first_by_#{a1}" }

    it "finds correct translation if exists in current locale" do
      Mobility.locale = :ja
      instance = model_class.create(a1 => "タイトル")
      Mobility.locale = :en
      instance.send(:"#{a1}=", "Title")
      instance.save
      match = query_scope.send(finder_method, "Title")
      expect(match.id).to eq(instance.id)
      Mobility.locale = :ja
      expect(query_scope.send(finder_method, "タイトル").id).to eq(instance.id)
      expect(query_scope.send(finder_method, "foo")).to be_nil
    end

    it "returns nil if no matching translation exists in this locale" do
      Mobility.locale = :ja
      model_class.create(a1 => "タイトル")
      Mobility.locale = :en
      expect(query_scope.send(finder_method, "タイトル")).to eq(nil)
      expect(query_scope.send(finder_method, "foo")).to be_nil
    end
  end
end
