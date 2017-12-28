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

COLUMNS = %w(title body long_title seo_title)

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
  translates(*COLUMNS, backend: :column, presence: false)
end

post = Post.new(title_en: "hey", title_ja: "あああ")

Benchmark.ips do |x|
  x.report("activerecord") { post.title_ja }
  x.report("mobility without plugins") { post.title }

  x.compare!
end
