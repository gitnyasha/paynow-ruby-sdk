$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "paynow_sdk"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!
