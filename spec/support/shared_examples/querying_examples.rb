shared_examples_for "AR Model with translated scope" do |model_class_name, attribute1=:title, attribute2=:content|
  let(:model_class) { model_class_name.constantize }
  let(:query_scope) { model_class.i18n }

  describe ".where" do
    context "querying on one translated attribute" do
      before do
        @instance1 = model_class.create(attribute1 => "foo")
        @instance2 = model_class.create(attribute1 => "bar")
        @instance3 = model_class.create(attribute1 => "baz", published: true)
        @instance4 = model_class.create(attribute1 => "baz", published: false)
        @instance5 = model_class.create(attribute1 => "foo", published: true)
      end

      it "returns correct result searching on unique attribute value" do
        expect(query_scope.where(attribute1 => "bar")).to eq([@instance2])
      end

      it "returns correct results when query matches multiple records" do
        expect(query_scope.where(attribute1 => "foo")).to match_array([@instance1, @instance5])
      end

      it "returns correct result when querying on translated and untranslated attributes" do
        expect(query_scope.where(attribute1 => "baz", published: true)).to eq([@instance3])
      end

      it "returns correct result when querying on nil values" do
        instance = model_class.create(attribute1 => nil)
        expect(query_scope.where(attribute1 => nil)).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(attribute1 => "foo ja")
            @ja_instance2 = model_class.create(attribute1 => "foo")
          end
        end

        it "returns correct result when querying on same attribute value in different locale" do
          expect(query_scope.where(attribute1 => "foo")).to match_array([@instance1, @instance5])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo ja")).to eq([@ja_instance1])
            expect(query_scope.where(attribute1 => "foo")).to eq([@ja_instance2])
          end
        end
      end

      context "with exists?" do
        it "returns correct result searching on unique attribute value" do
          aggregate_failures do
            expect(query_scope.where(attribute1 => "bar").exists?).to eq(true)
            expect(query_scope.where(attribute1 => "aaa").exists?).to eq(false)
          end
        end
      end
    end

    context "with two translated attributes" do
      before do
        @instance1 = model_class.create(attribute1 => "foo"                                               )
        @instance2 = model_class.create(attribute1 => "foo", attribute2 => "foo content"                  )
        @instance3 = model_class.create(attribute1 => "foo", attribute2 => "foo content", published: false)
        @instance4 = model_class.create(                     attribute2 => "foo content"                  )
        @instance5 = model_class.create(attribute1 => "bar", attribute2 => "bar content"                  )
        @instance6 = model_class.create(attribute1 => "bar",                              published: true )
      end

      # @note Regression spec
      it "does not modify scope in-place" do
        query_scope.where(attribute1 => "foo")
        expect(query_scope.to_sql).to eq(model_class.all.to_sql)
      end

      it "returns correct results querying on one attribute" do
        expect(query_scope.where(attribute1 => "foo")).to match_array([@instance1, @instance2, @instance3])
        expect(query_scope.where(attribute2 => "foo content")).to match_array([@instance2, @instance3, @instance4])
      end

      it "returns correct results querying on two attributes in single where call" do
        expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content")).to match_array([@instance2, @instance3])
      end

      it "returns correct results querying on two attributes in separate where calls" do
        expect(query_scope.where(attribute1 => "foo").where(attribute2 => "foo content")).to match_array([@instance2, @instance3])
      end

      it "returns correct result querying on two translated attributes and untranslated attribute" do
        expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content", published: false)).to eq([@instance3])
      end

      it "works with nil values" do
        expect(query_scope.where(attribute1 => "foo", attribute2 => nil)).to eq([@instance1])
        expect(query_scope.where(attribute1 => "foo").where(attribute2 => nil)).to eq([@instance1])
        instance = model_class.create
        expect(query_scope.where(attribute1 => nil, attribute2 => nil)).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(attribute1 => "foo ja", attribute2 => "foo content ja")
            @ja_instance2 = model_class.create(attribute1 => "foo",    attribute2 => "foo content"   )
            @ja_instance3 = model_class.create(attribute1 => "foo"                                   )
            @ja_instance4 = model_class.create(                             attribute2 => "foo"      )
          end
        end

        it "returns correct result when querying on same attribute values in different locale" do
          expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content")).to match_array([@instance2, @instance3])
          expect(query_scope.where(attribute1 => "foo", attribute2 => nil)).to eq([@instance1])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo")).to match_array([@ja_instance2, @ja_instance3])
            expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content")).to eq([@ja_instance2])
            expect(query_scope.where(attribute1 => "foo ja", attribute2 => "foo content ja")).to eq([@ja_instance1])
          end
        end
      end
    end
  end

  describe ".not" do
    before do
      @instance1 = model_class.create(attribute1 => "foo"                                               )
      @instance2 = model_class.create(attribute1 => "foo", attribute2 => "foo content"                  )
      @instance3 = model_class.create(attribute1 => "foo", attribute2 => "foo content", published: false)
      @instance4 = model_class.create(                          attribute2 => "foo content"                  )
      @instance5 = model_class.create(attribute1 => "bar", attribute2 => "bar content", published: true )
      @instance6 = model_class.create(attribute1 => "bar", attribute2 => "baz content", published: false)
      @instance7 = model_class.create(                                                       published: true)
    end

    # @note Regression spec
    it "does not modify scope in-place" do
      query_scope.where.not(attribute1 => nil)
      expect(query_scope.to_sql).to eq(model_class.all.to_sql)
    end

    it "works with nil values" do
      expect(query_scope.where.not(attribute1 => nil)).to match_array([@instance1, @instance2, @instance3, @instance5, @instance6])
      expect(query_scope.where.not(attribute1 => nil).where.not(attribute2 => nil)).to match_array([@instance2, @instance3, @instance5, @instance6])
      expect(query_scope.where(attribute1 => nil).where.not(attribute2 => nil)).to eq([@instance4])
    end

    it "returns record without translated attribute value" do
      expect(query_scope.where.not(attribute1 => "foo")).to match_array([@instance5, @instance6])
    end

    it "returns record without set of translated attribute values" do
      expect(query_scope.where.not(attribute1 => "foo", attribute2 => "baz content")).to match_array([@instance5])
    end

    it "works in combination with untranslated attributes" do
      expect(query_scope.where.not(attribute1 => "foo", published: true)).to eq([@instance6])
    end
  end
end

shared_examples_for "Sequel Model with translated dataset" do |model_class_name, attribute1=:title, attribute2=:content|
  let(:model_class) { model_class_name.constantize }
  let(:table_name) { model_class.table_name }
  let(:query_scope) { model_class.i18n }

  describe ".where" do
    context "querying on one translated attribute" do
      before do
        @instance1 = model_class.create(attribute1 => "foo")
        @instance2 = model_class.create(attribute1 => "bar")
        @instance3 = model_class.create(attribute1 => "baz", :published => true)
        @instance4 = model_class.create(attribute1 => "baz", :published => false)
        @instance5 = model_class.create(attribute1 => "foo", :published => true)
      end

      it "returns correct result searching on unique attribute value" do
        expect(query_scope.where(attribute1 => "bar").select_all(table_name).all).to eq([@instance2])
      end

      it "returns correct results when query matches multiple records" do
        expect(query_scope.where(attribute1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance5])
      end

      it "returns correct result when querying on translated and untranslated attributes" do
        expect(query_scope.where(attribute1 => "baz", :published => true).select_all(table_name).all).to eq([@instance3])
      end

      it "returns correct result when querying on nil values" do
        instance = model_class.create(attribute1 => nil)
        expect(query_scope.where(attribute1 => nil).select_all(table_name).all).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(attribute1 => "foo ja")
            @ja_instance2 = model_class.create(attribute1 => "foo")
          end
        end

        it "returns correct result when querying on same attribute value in different locale" do
          expect(query_scope.where(attribute1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance5])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo ja").select_all(table_name).all).to eq([@ja_instance1])
            expect(query_scope.where(attribute1 => "foo").select_all(table_name).all).to eq([@ja_instance2])
          end
        end
      end
    end

    context "with two translated attributes" do
      before do
        @instance1 = model_class.create(attribute1 => "foo"                                               )
        @instance2 = model_class.create(attribute1 => "foo", attribute2 => "foo content"                  )
        @instance3 = model_class.create(attribute1 => "foo", attribute2 => "foo content", published: false)
        @instance4 = model_class.create(                          attribute2 => "foo content"                  )
        @instance5 = model_class.create(attribute1 => "bar", attribute2 => "bar content"                  )
        @instance6 = model_class.create(attribute1 => "bar",                              published: true )
      end

      it "returns correct results querying on one attribute" do
        expect(query_scope.where(attribute1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance2, @instance3])
        expect(query_scope.where(attribute2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3, @instance4])
      end

      it "returns correct results querying on two attributes in single where call" do
        expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
      end

      it "returns correct results querying on two attributes in separate where calls" do
        expect(query_scope.where(attribute1 => "foo").where(attribute2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
      end

      it "returns correct result querying on two translated attributes and untranslated attribute" do
        expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content", published: false).select_all(table_name).all).to eq([@instance3])
      end

      it "works with nil values" do
        expect(query_scope.where(attribute1 => "foo", attribute2 => nil).select_all(table_name).all).to eq([@instance1])
        expect(query_scope.where(attribute1 => "foo").where(attribute2 => nil).select_all(table_name).all).to eq([@instance1])
        instance = model_class.create
        expect(query_scope.where(attribute1 => nil, attribute2 => nil).select_all(table_name).all).to eq([instance])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_instance1 = model_class.create(attribute1 => "foo ja", attribute2 => "foo content ja")
            @ja_instance2 = model_class.create(attribute1 => "foo",    attribute2 => "foo content"   )
            @ja_instance3 = model_class.create(attribute1 => "foo"                                   )
            @ja_instance4 = model_class.create(                             attribute2 => "foo"      )
          end
        end

        it "returns correct result when querying on same attribute values in different locale" do
          expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
          expect(query_scope.where(attribute1 => "foo", attribute2 => nil).select_all(table_name).all).to eq([@instance1])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo").select_all(table_name).all).to match_array([@ja_instance2, @ja_instance3])
            expect(query_scope.where(attribute1 => "foo", attribute2 => "foo content").select_all(table_name).all).to eq([@ja_instance2])
            expect(query_scope.where(attribute1 => "foo ja", attribute2 => "foo content ja").select_all(table_name).all).to eq([@ja_instance1])
          end
        end
      end
    end
  end

  describe ".exclude" do
    before do
      @instance1 = model_class.create(attribute1 => "foo"                                               )
      @instance2 = model_class.create(attribute1 => "foo", attribute2 => "baz content"                  )
      @instance3 = model_class.create(attribute1 => "bar", attribute2 => "foo content", published: false)
    end

    it "returns record without excluded attribute condition" do
      expect(query_scope.exclude(attribute1 => "foo").select_all(table_name).all).to match_array([@instance3])
    end

    it "returns record without excluded set of attribute conditions" do
      expect(query_scope.exclude(attribute1 => "foo", attribute2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
    end

    it "works with nil values" do
      expect(query_scope.exclude(attribute1 => "bar", attribute2 => nil).select_all(table_name).all).to match_array([@instance1, @instance2, @instance3])
      expect(query_scope.exclude(attribute1 => "bar").exclude(attribute2 => nil).select_all(table_name).all).to eq([@instance2])
      expect(query_scope.exclude(attribute1 => nil).exclude(attribute2 => nil).select_all(table_name).all).to match_array([@instance2, @instance3])
    end
  end

  describe "Model.i18n.first_by_<translated attribute>" do
    let(:finder_method) { :"first_by_#{attribute1}" }

    it "finds correct translation if exists in current locale" do
      Mobility.locale = :ja
      instance = model_class.create(attribute1 => "タイトル")
      Mobility.locale = :en
      instance.send(:"#{attribute1}=", "Title")
      instance.save
      match = query_scope.send(finder_method, "Title")
      expect(match).to eq(instance)
      Mobility.locale = :ja
      expect(query_scope.send(finder_method, "タイトル")).to eq(instance)
      expect(query_scope.send(finder_method, "foo")).to be_nil
    end

    it "returns nil if no matching translation exists in this locale" do
      Mobility.locale = :ja
      model_class.create(attribute1 => "タイトル")
      Mobility.locale = :en
      expect(query_scope.send(finder_method, "タイトル")).to eq(nil)
      expect(query_scope.send(finder_method, "foo")).to be_nil
    end
  end
end
