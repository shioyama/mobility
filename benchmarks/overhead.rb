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

COLUMNS = %w(default no_presence no_cache no_fallbacks no_presence_no_fallbacks)

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
  translates :default, backend: :column
  translates :no_presence, backend: :column, presence: false
  translates :no_cache, backend: :column, cache: false
  translates :no_fallbacks, backend: :column, fallbacks: false
  translates :no_presence_no_fallbacks, backend: :column, fallbacks: false, presence: false
end

post = Post.new
COLUMNS.each do |column|
  post.send("#{column}_en=", "hey")
  post.send("#{column}_ja=", "あああ")
end

Benchmark.ips do |x|
  x.report("activerecord") { post.default_ja }
  x.report("mobility with default plugins") { post.default }
  x.report("mobility without presence plugin") { post.no_presence }
  x.report("mobility without cache plugin") { post.no_cache }
  x.report("mobility without fallbacks plugin") { post.no_fallbacks }
  x.report("mobility without presence or fallbacks plugin") { post.no_presence_no_fallbacks }

  x.compare!
end
