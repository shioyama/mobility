Mobility.configure do |config|
  config.default_backend = :key_value
  config.accessor_method = :translates
  config.query_method    = :i18n
end
