# Borrowed from Traco

require "bundler/setup"
require "benchmark/ips"
require "active_record"
require "mobility"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

I18n.enforce_available_locales = false
I18n.available_locales = [ :en, :de, :ja ]
I18n.default_locale = :en
I18n.locale = :ja

COLUMNS = %w(title content subtitle author)

ActiveRecord::Schema.define(version: 0) do
  create_table :posts, force: true do |t|
    I18n.available_locales.each do |locale|
      COLUMNS.each do |column|
        t.string "#{column}_#{locale}"
      end
    end
  end
end

Mobility.configure do |config|
  config.plugins -= [:default]
end

class Post < ActiveRecord::Base
  extend Mobility
  translates :title, backend: :column
  translates :content, backend: :column, presence: false
  translates :subtitle, backend: :column, presence: false, cache: false
  translates :author, backend: :column, cache: false
end

post = Post.new(title_en: "hey", title_ja: "あああ")

Benchmark.ips do |x|
  x.report("activerecord") { post.title_ja }
  x.report("mobility with default plugins") { post.title }
  x.report("mobility without presence plugin") { post.content }
  x.report("mobility without presence and cache plugin") { post.subtitle }
  x.report("mobility without cache plugin") { post.subtitle }

  x.compare!
end
