require "test_helper"

class PaynowSdkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PaynowSdk::VERSION
  end

  def test_it_does_something_useful
    paynow = Paynow.new("int_id", "int_key", "link", "link")
    assert paynow.createdhash("something")
  end

  def test_it_instantiate
    payment = Payment.new("1", "me@mail.com")
    assert payment.add("something", 1.00)
  end
end
