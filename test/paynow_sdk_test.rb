require "test_helper"

class PaynowSdkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PaynowSdk::VERSION
  end

  def test_it_does_something_useful
    assert true
  end

  def test_it_does_something_useful
    assert "data".status_update
  end
end
