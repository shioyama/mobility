shared_examples_for "AR Model with translated scope" do |model_class_name, attribute1=:title, attribute2=:content|
  let(:model_class) { model_class_name.constantize }
  let(:query_scope) { model_class.i18n }

  describe ".where" do
    context "querying on one translated attribute" do
      before do
        @post1 = model_class.create(attribute1 => "foo post")
        @post2 = model_class.create(attribute1 => "bar post")
        @post3 = model_class.create(attribute1 => "baz post", published: true)
        @post4 = model_class.create(attribute1 => "baz post", published: false)
        @post5 = model_class.create(attribute1 => "foo post", published: true)
      end

      it "returns correct result searching on unique attribute value" do
        expect(query_scope.where(attribute1 => "bar post")).to eq([@post2])
      end

      it "returns correct results when query matches multiple records" do
        expect(query_scope.where(attribute1 => "foo post")).to match_array([@post1, @post5])
      end

      it "returns correct result when querying on translated and untranslated attributes" do
        expect(query_scope.where(attribute1 => "baz post", published: true)).to eq([@post3])
      end

      it "returns correct result when querying on nil values" do
        post = model_class.create(attribute1 => nil)
        expect(query_scope.where(attribute1 => nil)).to eq([post])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_post1 = model_class.create(attribute1 => "foo post ja")
            @ja_post2 = model_class.create(attribute1 => "foo post")
          end
        end

        it "returns correct result when querying on same attribute value in different locale" do
          expect(query_scope.where(attribute1 => "foo post")).to match_array([@post1, @post5])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo post ja")).to eq([@ja_post1])
            expect(query_scope.where(attribute1 => "foo post")).to eq([@ja_post2])
          end
        end
      end
    end

    context "with two translated attributes" do
      before do
        @post1 = model_class.create(attribute1 => "foo post"                                               )
        @post2 = model_class.create(attribute1 => "foo post", attribute2 => "foo content"                  )
        @post3 = model_class.create(attribute1 => "foo post", attribute2 => "foo content", published: false)
        @post4 = model_class.create(                          attribute2 => "foo content"                  )
        @post5 = model_class.create(attribute1 => "bar post", attribute2 => "bar content"                  )
        @post6 = model_class.create(attribute1 => "bar post",                              published: true )
      end

      # @note Regression spec
      it "does not modify scope in-place" do
        query_scope.where(attribute1 => "foo post")
        expect(query_scope.to_sql).to eq(model_class.all.to_sql)
      end

      it "returns correct results querying on one attribute" do
        expect(query_scope.where(attribute1 => "foo post")).to match_array([@post1, @post2, @post3])
        expect(query_scope.where(attribute2 => "foo content")).to match_array([@post2, @post3, @post4])
      end

      it "returns correct results querying on two attributes in single where call" do
        expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content")).to match_array([@post2, @post3])
      end

      it "returns correct results querying on two attributes in separate where calls" do
        expect(query_scope.where(attribute1 => "foo post").where(attribute2 => "foo content")).to match_array([@post2, @post3])
      end

      it "returns correct result querying on two translated attributes and untranslated attribute" do
        expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content", published: false)).to eq([@post3])
      end

      it "works with nil values" do
        expect(query_scope.where(attribute1 => "foo post", attribute2 => nil)).to eq([@post1])
        expect(query_scope.where(attribute1 => "foo post").where(attribute2 => nil)).to eq([@post1])
        post = model_class.create
        expect(query_scope.where(attribute1 => nil, attribute2 => nil)).to eq([post])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_post1 = model_class.create(attribute1 => "foo post ja", attribute2 => "foo content ja")
            @ja_post2 = model_class.create(attribute1 => "foo post",    attribute2 => "foo content"   )
            @ja_post3 = model_class.create(attribute1 => "foo post"                                   )
            @ja_post4 = model_class.create(                             attribute2 => "foo post"      )
          end
        end

        it "returns correct result when querying on same attribute values in different locale" do
          expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content")).to match_array([@post2, @post3])
          expect(query_scope.where(attribute1 => "foo post", attribute2 => nil)).to eq([@post1])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo post")).to match_array([@ja_post2, @ja_post3])
            expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content")).to eq([@ja_post2])
            expect(query_scope.where(attribute1 => "foo post ja", attribute2 => "foo content ja")).to eq([@ja_post1])
          end
        end
      end
    end
  end

  describe ".not" do
    before do
      @post1 = model_class.create(attribute1 => "foo post"                                               )
      @post2 = model_class.create(attribute1 => "foo post", attribute2 => "foo content"                  )
      @post3 = model_class.create(attribute1 => "foo post", attribute2 => "foo content", published: false)
      @post4 = model_class.create(                          attribute2 => "foo content"                  )
      @post5 = model_class.create(attribute1 => "bar post", attribute2 => "bar content", published: true )
      @post6 = model_class.create(attribute1 => "bar post", attribute2 => "baz content", published: false)
      @post7 = model_class.create(                                                       published: true)
    end

    # @note Regression spec
    it "does not modify scope in-place" do
      query_scope.where.not(attribute1 => nil)
      expect(query_scope.to_sql).to eq(model_class.all.to_sql)
    end

    it "works with nil values" do
      expect(query_scope.where.not(attribute1 => nil)).to match_array([@post1, @post2, @post3, @post5, @post6])
      expect(query_scope.where.not(attribute1 => nil).where.not(attribute2 => nil)).to match_array([@post2, @post3, @post5, @post6])
      expect(query_scope.where(attribute1 => nil).where.not(attribute2 => nil)).to eq([@post4])
    end

    it "returns record without translated attribute value" do
      expect(query_scope.where.not(attribute1 => "foo post")).to match_array([@post5, @post6])
    end

    it "returns record without set of translated attribute values" do
      expect(query_scope.where.not(attribute1 => "foo post", attribute2 => "baz content")).to match_array([@post5])
    end

    it "works in combination with untranslated attributes" do
      expect(query_scope.where.not(attribute1 => "foo post", published: true)).to eq([@post6])
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
        @post1 = model_class.create(attribute1 => "foo post")
        @post2 = model_class.create(attribute1 => "bar post")
        @post3 = model_class.create(attribute1 => "baz post", :published => true)
        @post4 = model_class.create(attribute1 => "baz post", :published => false)
        @post5 = model_class.create(attribute1 => "foo post", :published => true)
      end

      it "returns correct result searching on unique attribute value" do
        expect(query_scope.where(attribute1 => "bar post").select_all(table_name).all).to eq([@post2])
      end

      it "returns correct results when query matches multiple records" do
        expect(query_scope.where(attribute1 => "foo post").select_all(table_name).all).to match_array([@post1, @post5])
      end

      it "returns correct result when querying on translated and untranslated attributes" do
        expect(query_scope.where(attribute1 => "baz post", :published => true).select_all(table_name).all).to eq([@post3])
      end

      it "returns correct result when querying on nil values" do
        post = model_class.create(attribute1 => nil)
        expect(query_scope.where(attribute1 => nil).select_all(table_name).all).to eq([post])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_post1 = model_class.create(attribute1 => "foo post ja")
            @ja_post2 = model_class.create(attribute1 => "foo post")
          end
        end

        it "returns correct result when querying on same attribute value in different locale" do
          expect(query_scope.where(attribute1 => "foo post").select_all(table_name).all).to match_array([@post1, @post5])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo post ja").select_all(table_name).all).to eq([@ja_post1])
            expect(query_scope.where(attribute1 => "foo post").select_all(table_name).all).to eq([@ja_post2])
          end
        end
      end
    end

    context "with two translated attributes" do
      before do
        @post1 = model_class.create(attribute1 => "foo post"                                               )
        @post2 = model_class.create(attribute1 => "foo post", attribute2 => "foo content"                  )
        @post3 = model_class.create(attribute1 => "foo post", attribute2 => "foo content", published: false)
        @post4 = model_class.create(                          attribute2 => "foo content"                  )
        @post5 = model_class.create(attribute1 => "bar post", attribute2 => "bar content"                  )
        @post6 = model_class.create(attribute1 => "bar post",                              published: true )
      end

      it "returns correct results querying on one attribute" do
        expect(query_scope.where(attribute1 => "foo post").select_all(table_name).all).to match_array([@post1, @post2, @post3])
        expect(query_scope.where(attribute2 => "foo content").select_all(table_name).all).to match_array([@post2, @post3, @post4])
      end

      it "returns correct results querying on two attributes in single where call" do
        expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content").select_all(table_name).all).to match_array([@post2, @post3])
      end

      it "returns correct results querying on two attributes in separate where calls" do
        expect(query_scope.where(attribute1 => "foo post").where(attribute2 => "foo content").select_all(table_name).all).to match_array([@post2, @post3])
      end

      it "returns correct result querying on two translated attributes and untranslated attribute" do
        expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content", published: false).select_all(table_name).all).to eq([@post3])
      end

      it "works with nil values" do
        expect(query_scope.where(attribute1 => "foo post", attribute2 => nil).select_all(table_name).all).to eq([@post1])
        expect(query_scope.where(attribute1 => "foo post").where(attribute2 => nil).select_all(table_name).all).to eq([@post1])
        post = model_class.create
        expect(query_scope.where(attribute1 => nil, attribute2 => nil).select_all(table_name).all).to eq([post])
      end

      context "with content in different locales" do
        before do
          Mobility.with_locale(:ja) do
            @ja_post1 = model_class.create(attribute1 => "foo post ja", attribute2 => "foo content ja")
            @ja_post2 = model_class.create(attribute1 => "foo post",    attribute2 => "foo content"   )
            @ja_post3 = model_class.create(attribute1 => "foo post"                                   )
            @ja_post4 = model_class.create(                             attribute2 => "foo post"      )
          end
        end

        it "returns correct result when querying on same attribute values in different locale" do
          expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content").select_all(table_name).all).to match_array([@post2, @post3])
          expect(query_scope.where(attribute1 => "foo post", attribute2 => nil).select_all(table_name).all).to eq([@post1])

          Mobility.with_locale(:ja) do
            expect(query_scope.where(attribute1 => "foo post").select_all(table_name).all).to match_array([@ja_post2, @ja_post3])
            expect(query_scope.where(attribute1 => "foo post", attribute2 => "foo content").select_all(table_name).all).to eq([@ja_post2])
            expect(query_scope.where(attribute1 => "foo post ja", attribute2 => "foo content ja").select_all(table_name).all).to eq([@ja_post1])
          end
        end
      end
    end
  end

  describe ".exclude" do
    before do
      @post1 = model_class.create(attribute1 => "foo post"                                               )
      @post2 = model_class.create(attribute1 => "foo post", attribute2 => "baz content"                  )
      @post3 = model_class.create(attribute1 => "bar post", attribute2 => "foo content", published: false)
    end

    it "returns record without excluded attribute condition" do
      expect(query_scope.exclude(attribute1 => "foo post").select_all(table_name).all).to match_array([@post3])
    end

    it "returns record without excluded set of attribute conditions" do
      expect(query_scope.exclude(attribute1 => "foo post", attribute2 => "foo content").select_all(table_name).all).to match_array([@post2, @post3])
    end

    it "works with nil values" do
      expect(query_scope.exclude(attribute1 => "bar post", attribute2 => nil).select_all(table_name).all).to match_array([@post1, @post2, @post3])
      expect(query_scope.exclude(attribute1 => "bar post").exclude(attribute2 => nil).select_all(table_name).all).to eq([@post2])
      expect(query_scope.exclude(attribute1 => nil).exclude(attribute2 => nil).select_all(table_name).all).to match_array([@post2, @post3])
    end
  end

  describe "Model.i18n.first_by_<translated attribute>" do
    let(:finder_method) { :"first_by_#{attribute1}" }

    it "finds correct translation if exists in current locale" do
      Mobility.locale = :ja
      post = model_class.create(attribute1 => "タイトル")
      Mobility.locale = :en
      post.send(:"#{attribute1}=", "Title")
      post.save
      match = query_scope.send(finder_method, "Title")
      expect(match).to eq(post)
      Mobility.locale = :ja
      expect(query_scope.send(finder_method, "タイトル")).to eq(post)
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
