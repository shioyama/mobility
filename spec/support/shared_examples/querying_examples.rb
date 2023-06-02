shared_examples_for "AR Model with translated scope" do |model_class_name, a1=:title, a2=:content|
  let(:backend) { model_class.ancestors.grep(Mobility::Translations).first.backend }
  let(:model_class) { model_class_name.constantize }
  let(:query_scope) { model_class.i18n }
  let(:ordered_results) { query_scope.order("#{model_class.table_name}.id asc") }

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

        it "returns correct result when querying with locale option" do
          expect(query_scope.where(a1 => "foo", locale: :en)).to match_array([@instance1, @instance5])
          expect(query_scope.where(a1 => "foo ja", locale: :ja)).to eq([@ja_instance1])
          expect(query_scope.where(a1 => "foo", locale: :ja)).to eq([@ja_instance2])
        end

        it "returns correct result when querying with locale option twice in separate clauses" do
          @ja_instance1.update(a1 => "foo en")
          expect(query_scope.where(a1 => "foo ja", locale: :ja).where(a1 => "foo en", locale: :en)).to eq([@ja_instance1])
          expect(query_scope.where(a1 => "foo", locale: :ja).where(a1 => nil, locale: :en)).to eq([@ja_instance2])
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

  describe ".order" do
    let!(:i) do
      [
        model_class.create(a1 => "foo0"),
        model_class.create(a1 => "foo2", a2 => "foo1"),
        model_class.create(a1 => "foo1", a2 => "bar2"),
        model_class.create(a1 => "foo3", a2 => "bar1")
      ]
    end

    it "orders records correctly with string argument" do
      expect(query_scope.order(a1.to_s)).to eq([i[0], i[2], i[1], i[3]])
    end

    it "orders records correctly with symbol argument" do
      expect(query_scope.order(a1.to_sym)).to eq([i[0], i[2], i[1], i[3]])
    end

    it "orders records correctly with 1-key hash argument" do
      aggregate_failures "one attribute" do
        expect(query_scope.order(a1 => :asc)).to eq([i[0], i[2], i[1], i[3]])
        expect(query_scope.order(a1 => :desc)).to eq([i[3], i[1], i[2], i[0]])
      end
    end

    it "orders records correctly with 2-key hash argument" do
      skip "Not supported by #{backend}" if [:table, :key_value].include?(backend)

      added = model_class.create(a1 => "foo2", a2 => "foo2")
      expect(query_scope.order(a1 => :desc, a2 => :asc)).to eq([i[3], i[1], added, i[2], i[0]])
    end

    it "handles untranslated attributes" do
      expect { query_scope.order(published: :desc) }.not_to raise_error
    end

    it "does not modify original hash" do
      hash = { a1 => :asc }
      expect { query_scope.order(hash) }.not_to change { hash }
    end
  end

  describe ".pluck", active_record_geq: '5.0' do
    before do
      [["foo0", "bar3", true],
       ["foo2", "bar0", false],
       ["foo0", "bar1", true],
       ["foo1", "bar2", false],
       ["foo3", "bar1", nil]].each do |(val1, val2, val3)|
        model_class.create(a1 => val1, a2 => val2, :published => val3)
      end
    end

    it "plucks individual attribute values" do
      expect(ordered_results.pluck(a1)).to eq(["foo0", "foo2", "foo0", "foo1", "foo3"])
    end

    it "plucks pairs of attribute values" do
      expect(ordered_results.pluck(a1, a2)).to eq(
        [["foo0", "bar3"],
         ["foo2", "bar0"],
         ["foo0", "bar1"],
         ["foo1", "bar2"],
         ["foo3", "bar1"]]
      )
    end

    it "plucks translated attributes mixed with untranslated attributes" do
      expect(ordered_results.pluck(a1, :published, a2)).to eq(
        [["foo0", true,  "bar3"],
         ["foo2", false, "bar0"],
         ["foo0", true,  "bar1"],
         ["foo1", false, "bar2"],
         ["foo3", nil,   "bar1"]]
      )
    end

    it "plucks untranslated attributes only" do
      expect(ordered_results.pluck(:published)).to eq([true, false, true, false, nil])
    end

    it "works with nil values" do
      model_class.create(a1 => nil, a2 => "bar4")
      model_class.create(a1 => "foo4", a2 => nil)
      expect(ordered_results.pluck(a1, a2)).to eq(
        [["foo0", "bar3"],
         ["foo2", "bar0"],
         ["foo0", "bar1"],
         ["foo1", "bar2"],
         ["foo3", "bar1"],
         [nil,    "bar4"],
         ["foo4", nil   ]]
      )
    end
  end

  describe ".select/.group", active_record_geq: '5.0' do
    before do
      [["foo", "baz", true],
       ["foo", "baz", false],
       ["bar", "baz", true],
       ["bar", "foo", false],
       ["bar", "foo", nil]].each do |(val1, val2, val3)|
        model_class.create(a1 => val1, a2 => val2, :published => val3)
      end
    end

    describe "selecting translated attributes" do
      it "returns value from attribute methods on results" do
        selected = ordered_results.select(a1)
        expect(selected[0].send(a1)).to eq("foo")
        expect(selected[1].send(a1)).to eq("foo")
        expect(selected[2].send(a1)).to eq("bar")
        expect(selected[3].send(a1)).to eq("bar")
        expect(selected[4].send(a1)).to eq("bar")
      end
    end

    describe "counting translated attributes" do
      it "counts total results" do
        selected = query_scope.select(a1)
        expect(selected.count).to eq(5)
      end

      it "works with count and group" do
        selected = query_scope.select(a1).group(a1)
        expect(selected.count).to eq({ "foo" => 2, "bar" => 3 })
      end

      it "works with count and group on two attributes" do
        selected = query_scope.select(a1).group(a1, a2)
        expect(selected.count).to eq({ ["foo", "baz"] => 2, ["bar", "baz"] => 1, ["bar", "foo"] => 2 })
      end
    end

    describe "ActiveRecord compatibility" do
      it ".select does not throw any exception when passed a block" do
        expect { ordered_results.select {} }.not_to raise_error
      end

      it ".select does throw exception when passed a block with arguments" do
        expect { ordered_results.select(:foo) {} }.to raise_error(ArgumentError)
      end
    end
  end

  describe "Arel queries" do
    # Shortcut for passing block to e.g. Post.i18n
    def query(*args, **kwargs, &block); model_class.i18n(*args, **kwargs, &block); end

    context "single-block querying" do
      let!(:i) { [
        model_class.create(a1 => "foo"             ),
        model_class.create(                        ),
        model_class.create(             a2 => "bar"),
        model_class.create(             a2 => "foo"),
        model_class.create(a1 => "bar"             ),
        model_class.create(a1 => "foo", a2 => "bar"),
        model_class.create(a1 => "foo", a2 => "baz")
      ] }

      describe "equality" do
        it "handles (a EQ 'foo')" do
          expect(query { __send__(a1).eq("foo") }).to match_array([i[0], *i[5..6]])
        end

        it "handles (a EQ NULL)" do
          expect(query { __send__(a1).eq(nil) }).to match_array(i[1..3])
        end

        it "handles (a EQ b)" do
          matching = [
            model_class.create(a1 => "foo", a2 => "foo"),
            model_class.create(a1 => "bar", a2 => "bar")
          ]
          expect(query { __send__(a1).eq(__send__(a2)) }).to match_array(matching)
        end

        context "with locale option" do
          it "handles (a EQ 'foo')" do
            post1 = model_class.new(a1 => "foo en", a2 => "bar en")
            Mobility.with_locale(:ja) do
              post1.send("#{a1}=", "foo ja")
              post1.send("#{a2}=", "bar ja")
            end
            post1.save

            post2 = model_class.new(a1 => "baz en")
            Mobility.with_locale(:'pt-BR') { post2.send("#{a1}=", "baz pt-br") }
            post2.save

            expect(query(locale: :en) { __send__(a1).eq("foo en") }).to match_array([post1])
            expect(query(locale: :en) { __send__(a2).eq("bar en") }).to match_array([post1])
            expect(query(locale: :ja) { __send__(a1).eq("foo ja") }).to match_array([post1])
            expect(query(locale: :ja) { __send__(a2).eq("bar ja") }).to match_array([post1])
            expect(query(locale: :en) { __send__(a1).eq("baz en") }).to match_array([post2])
            expect(query(locale: :'pt-BR') { __send__(a1).eq("baz pt-br") }).to match_array([post2])
          end
        end
      end

      describe "not equal" do
        it "handles (a NOT EQ 'foo')" do
          expect(query { __send__(a1).not_eq("foo") }).to match_array([i[4]])
        end

        it "handles (a NOT EQ NULL)" do
          expect(query { __send__(a1).not_eq(nil) }).to match_array([i[0], *i[4..6]])
        end

        context "with AND" do
          it "handles ((a NOT EQ NULL) AND (b NOT EQ NULL))" do
            expect(query {
              __send__(a1).not_eq(nil).and(__send__(a2).not_eq(nil))
            }).to match_array(i[5..6])
          end
        end

        context "with OR" do
          it "handles ((a NOT EQ NULL) OR (b NOT EQ NULL))" do
            expect(query {
              __send__(a1).not_eq(nil).or(__send__(a2).not_eq(nil))
            }).to match_array([i[0], *i[2..6]])
          end
        end
      end

      describe "AND" do
        it "handles (a AND b)" do
          expect(query {
            __send__(a1).eq("foo").and(__send__(a2).eq("bar"))
          }).to match_array([i[5]])
        end

        it "handles (a AND b), where a is NULL-valued" do
          expect(query {
            __send__(a1).eq(nil).and(__send__(a2).eq("bar"))
          }).to match_array([i[2]])
        end

        it "handles (a AND b), where both a and b are NULL-valued" do
          expect(query {
            __send__(a1).eq(nil).and(__send__(a2).eq(nil))
          }).to match_array([i[1]])
        end
      end

      describe "OR" do
        it "handles (a OR b) on same attribute" do
          expect(query {
            __send__(a1).eq("foo").or(__send__(a1).eq("bar"))
          }).to match_array([i[0], *i[4..6]])
        end

        it "handles (a OR b) on same attribute, where a is NULL-valued" do
          expect(query {
            __send__(a1).eq(nil).or(__send__(a1).eq("foo"))
          }).to match_array([*i[0..3], *i[5..6]])
        end

        it "handles (a OR b) on two attributes" do
          expect(query {
            __send__(a1).eq("foo").or(__send__(a2).eq("bar"))
          }).to match_array([i[0], i[2], *i[5..6]])
        end

        it "handles (a OR b) on two attributes, where a is NULL-valued" do
          expect(query {
            __send__(a1).eq(nil).or(__send__(a2).eq("bar"))
          }).to match_array([*i[1..2], i[3], i[5]])
        end

        it "handles (a OR b) on two attributes, where both a and b are NULL-valued" do
          expect(query {
            __send__(a1).eq(nil).or(__send__(a2).eq(nil))
          }).to match_array(i[0..4])
        end
      end

      describe "combination of AND and OR" do
        it "handles a AND (b OR c)" do
          expect(query {
            __send__(a1).eq("foo").and(
              __send__(a2).eq("bar").or(__send__(a2).eq("baz")))
          }).to match_array(i[5..6])
        end

        it "handles a AND (b OR c), where c is NULL-valued" do
          expect(query {
            __send__(a1).eq("foo").and(
              __send__(a2).eq("bar").or(__send__(a2).eq(nil)))
          }).to match_array([i[0], i[5]])
        end

        it "handles (a AND b) OR (c AND d), where b and d are NULL-valued" do
          expect(query {
            __send__(a1).eq("foo").or(__send__(a1).eq(nil)).and(
              __send__(a2).eq("baz").or(__send__(a2).eq(nil)))
          }).to match_array([*i[0..1], i[6]])
        end
      end

      describe "LIKE/ILIKE (matches)" do
        it "includes partial string matches" do
          foobar = model_class.create(a1 => "foObar")
          barfoo = model_class.create(a1 => "barfOo")

          if backend == Mobility::Backends::ActiveRecord::Json && ENV['DB'] == 'mysql'
            # MySQL JSON columns are case sensitive
            expect(query { __send__(a1).matches("foO%") }).to match_array([foobar])
            expect(query { __send__(a1).matches("%fOo") }).to match_array([barfoo])
          else
            expect(query { __send__(a1).matches("foo%") }).to match_array([i[0], *i[5..6], foobar])
            expect(query { __send__(a1).matches("%foo") }).to match_array([i[0], *i[5..6], barfoo])
          end
        end

        if ENV['DB'] == 'postgres' && ::ActiveRecord::VERSION::STRING >= '5.0'
          it "works with case_sensitive option" do
            foobar = model_class.create(a1 => "foObar")
            barfoo = model_class.create(a1 => "barfOo")
            expect(query { __send__(a1).matches("foo%", nil, true) }).not_to include(foobar)
            expect(query { __send__(a1).matches("foO%", nil, true) }).to include(foobar)
            expect(query { __send__(a1).matches("%foo", nil, true) }).not_to include(barfoo)
            expect(query { __send__(a1).matches("%fOo", nil, true) }).to include(barfoo)
          end
        end
      end

      describe "LOWER" do
        it "matches lowercase string values" do
          foobar = model_class.create(a1 => "foObar")
          expect(query { __send__(a1).lower.eq("foobar") }).to match_array([foobar])
        end
      end
    end

    context "multi-block querying" do
      it "combines multiple locales with non-nil values" do
        post1 = model_class.new(a1 => "foo en", a2 => "bar en")
        Mobility.with_locale(:ja) do
          post1.send("#{a1}=", "foo ja")
          post1.send("#{a2}=", "bar ja")
        end
        post1.save

        post2 = model_class.new(a1 => "baz en")
        Mobility.with_locale(:'pt-BR') { post2.send("#{a1}=", "baz pt-br") }
        post2.save

        aggregate_failures do
          expect(
            query(locale: :en) { |en|
              query(locale: :ja) { |ja|
                en.__send__(a1).eq("foo en").and(ja.__send__(a2).eq("bar ja"))
              }
            }
          ).to match_array([post1])

          expect(
            query(locale: :en) { |en|
              query(locale: :'pt-BR') { |pt|
                en.__send__(a1).eq("baz en").and(pt.__send__(a1).eq("baz pt-br"))
              }
            }
          ).to match_array([post2])
        end
      end

      it "combines multiple locales with nil and non-nil values" do
        post1 = model_class.new(a1 => "foo en")
        Mobility.with_locale(:ja) { post1.send("#{a1}=", "foo ja") }
        post1.save

        post2 = model_class.create(a1 => "foo en")

        expect(
          query(locale: :en) { |en|
            query(locale: :ja) { |ja|
              en.__send__(a1).eq("foo en").and(ja.__send__(a1).eq(nil))
            }
          }
        ).to match_array([post2])
      end
    end
  end
end

shared_examples_for "Sequel Model with translated dataset" do |model_class_name, a1=:title, a2=:content|
  let(:model_class) { constantize(model_class_name) }
  let(:table_name) { model_class.table_name }
  let(:query_scope) { model_class.i18n }
  let(:backend) { model_class.ancestors.grep(Mobility::Translations).first.backend }

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

        it "returns correct result when querying with locale option" do
          expect(query_scope.where(a1 => "foo", locale: :en).select_all(table_name).all).to match_array([@instance1, @instance5])
          expect(query_scope.where(a1 => "foo ja", locale: :ja).select_all(table_name).all).to eq([@ja_instance1])
          expect(query_scope.where(a1 => "foo", locale: :ja).select_all(table_name).all).to eq([@ja_instance2])
        end

        it "returns correct result when querying with locale option twice in separate clauses" do
          @ja_instance1.update(a1 => "foo en")
          @ja_instance1.reload
          expect(query_scope.where(a1 => "foo ja", locale: :ja).where(a1 => "foo en", locale: :en).select_all(table_name).all).to eq([@ja_instance1])
          expect(query_scope.where(a1 => "foo", locale: :ja).where(a1 => nil, locale: :en).select_all(table_name).all).to eq([@ja_instance2])
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

    it "returns union of queries" do
      expect(query_scope.where(published: true).or(a1 => "foo").select_all(table_name).all).to match_array([@instance1, @instance2])
    end

    it "works with set of translated and untranslated attributes" do
      # For backends that join translation tables (Table and KeyValue backends)
      # this fails because the table will be inner join'ed, excluding the
      # result which satisfies the second (or) condition. This is impossible to
      # avoid without modification of an earlier dataset, which is probably not
      # a good idea.
      skip "Not supported by #{backend}" if [:table, :key_value].include?(backend)
      expect(query_scope.where(a1 => "foo").or(:published => false, a2 => "foo content").select_all(table_name).all).to match_array([@instance2, @instance3])
    end
  end

  describe "dataset queries" do
    # Shortcut for passing block to e.g. Post.i18n
    def query(*args, **options, &block); model_class.i18n(*args, **options, &block); end

    context "single-block querying" do
      let!(:i) { [
        model_class.create(a1 => "foo"             ),
        model_class.create(                        ),
        model_class.create(             a2 => "bar"),
        model_class.create(             a2 => "foo"),
        model_class.create(a1 => "bar"             ),
        model_class.create(a1 => "foo", a2 => "bar"),
        model_class.create(a1 => "foo", a2 => "baz")
      ] }

      describe "equality" do
        it "handles (a EQ 'foo')" do
          expect(query { __send__(a1) =~ "foo" }.select_all(table_name).all).to match_array([i[0], *i[5..6]])
        end

        it "handles (a EQ NULL)" do
          expect(query { __send__(a1) =~ nil }.select_all(table_name).all).to match_array(i[1..3])
        end

        it "handles (a EQ b)" do
          matching = [
            model_class.create(a1 => "foo", a2 => "foo"),
            model_class.create(a1 => "bar", a2 => "bar")
          ]
          expect(query { __send__(a1) =~ __send__(a2) }.select_all(table_name).all).to match_array(matching)
        end

        context "with locale option" do
          it "handles (a EQ 'foo')" do
            post1 = model_class.new(a1 => "foo en", a2 => "bar en")
            Mobility.with_locale(:ja) do
              post1.send("#{a1}=", "foo ja")
              post1.send("#{a2}=", "bar ja")
            end
            post1.save

            post2 = model_class.new(a1 => "baz en")
            Mobility.with_locale(:'pt-BR') { post2.send("#{a1}=", "baz pt-br") }
            post2.save

            expect(query(locale: :en) { __send__(a1) =~ "foo en" }.select_all(table_name).all).to match_array([post1])
            expect(query(locale: :en) { __send__(a2) =~ "bar en" }.select_all(table_name).all).to match_array([post1])
            expect(query(locale: :ja) { __send__(a1) =~ "foo ja" }.select_all(table_name).all).to match_array([post1])
            expect(query(locale: :ja) { __send__(a2) =~ "bar ja" }.select_all(table_name).all).to match_array([post1])
            expect(query(locale: :en) { __send__(a1) =~ "baz en" }.select_all(table_name).all).to match_array([post2])
            expect(query(locale: :'pt-BR') { __send__(a1) =~ "baz pt-br" }.select_all(table_name).all).to match_array([post2])
          end
        end
      end

      describe "not equal" do
        it "handles (a != 'foo')" do
          expect(query { __send__(a1) !~ "foo" }.select_all(table_name).all).to match_array([i[4]])
        end

        # @note For sequel, we need to use +invert+ to get NOT EQ NULL
        it "handles (a NOT EQ NULL)" do
          expect(query { __send__(a1) =~ nil }.invert.select_all(table_name).all).to match_array([i[0], *i[4..6]])
        end
      end

      describe "AND" do
        it "handles (a AND b)" do
          expect(query {
            (__send__(a1) =~ "foo") & (__send__(a2) =~ "bar")
          }.select_all(table_name).all).to match_array([i[5]])
        end
      end

      describe "OR" do
        it "handles (a OR b) on same attribute" do
          expect(query {
            (__send__(a1) =~ "foo") | (__send__(a1) =~ "bar")
          }.select_all(table_name).all).to match_array([i[0], *i[4..6]])
        end

        it "handles (a OR b) on two attributes" do
          expect(query {
            (__send__(a1) =~ "foo") | (__send__(a2) =~ "bar")
          }.select_all(table_name).all).to match_array([i[0], i[2], *i[5..6]])
        end
      end

      describe "combination of AND and OR" do
        it "handles a AND (b OR c)" do
          expect(query {
            ((__send__(a1) =~ "foo") & (__send__(a2) =~ "bar")) | (__send__(a2) =~ "baz")
          }.select_all(table_name).all).to match_array(i[5..6])
        end
      end

      describe "ILIKE" do
        it "matches case-insensitively, including partial string matches" do
          foobar = model_class.create(a1 => "foObar")
          barfoo = model_class.create(a1 => "barfOo")
          expect(query { Sequel.ilike(__send__(a1), "foo%") }.select_all(table_name).all).
            to match_array([i[0], *i[5..6], foobar])
          expect(query { Sequel.ilike(__send__(a1), "%foo") }.select_all(table_name).all).
            to match_array([i[0], *i[5..6], barfoo])
        end
      end

      describe "LIKE" do
        it "matches case-sensitively, including partial string matches" do
          foobar = model_class.create(a1 => "foObar")
          barfoo = model_class.create(a1 => "barfOo")
          expect(query { Sequel.like(__send__(a1), "foo%") }.select_all(table_name).all).
            not_to include(foobar)
          expect(query { Sequel.like(__send__(a1), "foO%") }.select_all(table_name).all).
            to include(foobar)
          expect(query { Sequel.like(__send__(a1), "%foo") }.select_all(table_name).all).
            not_to include(barfoo)
          expect(query { Sequel.like(__send__(a1), "%fOo") }.select_all(table_name).all).
            to include(barfoo)
        end
      end
    end

    context "multi-block querying" do
      it "combines multiple locales" do
        post1 = model_class.new(a1 => "foo en", a2 => "bar en")
        Mobility.with_locale(:ja) do
          post1.send("#{a1}=", "foo ja")
          post1.send("#{a2}=", "bar ja")
        end
        post1.save

        post2 = model_class.new(a1 => "baz en")
        Mobility.with_locale(:'pt-BR') { post2.send("#{a1}=", "baz pt-br") }
        post2.save

        aggregate_failures do
          expect(
            query(locale: :en) { |en|
              query(locale: :ja) { |ja|
                (en.__send__(a1) =~ "foo en") & (ja.__send__(a2) =~ "bar ja")
              }
            }.select_all(table_name).all
          ).to match_array([post1])

          expect(
            query(locale: :en) { |en|
              query(locale: :'pt-BR') { |pt|
                (en.__send__(a1) =~ "baz en") & (pt.__send__(a1) =~ "baz pt-br")
              }
            }.select_all(table_name).all
          ).to match_array([post2])
        end
      end
    end
  end
end
