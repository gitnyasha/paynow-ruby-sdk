require "paynow_sdk/version"
require "httparty"
require "cgi"
require "digest"

#throws error when hash from Paynow does not match locally generated hash

class HashMismatchException < Exception
  def initialize(message)
    super(message)
  end
end

class StatusResponse
  @@paid = true
  @@status = String
  @@amount = Float
  @@reference = String
  @@paynow_reference = String
  @@hash = String

  def __status_update(data)
    "Not implemented"
  end

  def initialize(data, update)
    if is_bool(update)
      __status_update(data)
    else
      @status = data["status"].downcase()
      @paid = @status == "paid"
      if data.include?("amount")
        @amount = data["amount"].to_f
      end
      if data.include?("reference")
        @reference = data["reference"]
      end
      if data.include?("paynowreference")
        @paynow_reference = data["paynowreference"]
      end
      if data.include?("hash")
        @hash = data["hash"]
      end
    end
  end

  def self.paid; @@paid; end
  def self.paid=(val); @@paid = val; end

  def paid; @paid = @@paid if @paid.nil?; @paid; end
  def paid=(val); @paid = val; end

  def self.status; @@status; end
  def self.status=(val); @@status = val; end

  def status; @status = @@status if @status.nil?; @status; end
  def status=(val); @status = val; end

  def self.amount; @@amount; end
  def self.amount=(val); @@amount = val; end

  def amount; @amount = @@amount if @amount.nil?; @amount; end
  def amount=(val); @amount = val; end

  def self.reference; @@reference; end
  def self.reference=(val); @@reference = val; end

  def reference; @reference = @@reference if @reference.nil?; @reference; end
  def reference=(val); @reference = val; end

  def self.paynow_reference; @@paynow_reference; end
  def self.paynow_reference=(val); @@paynow_reference = val; end

  def paynow_reference; @paynow_reference = @@paynow_reference if @paynow_reference.nil?; @paynow_reference; end
  def paynow_reference=(val); @paynow_reference = val; end

  def self.hash; @@hash; end
  def self.hash=(val); @@hash = val; end

  def hash; @hash = @@hash if @hash.nil?; @hash; end
  def hash=(val); @hash = val; end
end

class InitResponse
  @@success = true
  @@instructions = String
  @@has_redirect = true
  @@hash = String
  @@redirect_url = String
  @@error = String
  @@poll_url = String

  def initialize(data)
    @status = data["status"]
    @success = data["status"].downcase() != "error"
    @has_redirect = data.include?("browserurl")
    @hash = data.include?("hash")
    if is_bool(!@success)
      return
    end
    @poll_url = data["pollurl"]
    if is_bool(!@success)
      @error = data["error"]
    end
    if is_bool(@has_redirect)
      @redirect_url = data["browserurl"]
    end
    if data.include?("instructions")
      @instruction = data["instructions"]
    end
  end

  def self.success; @@success; end
  def self.success=(val); @@success = val; end

  def success; @success = @@success if @success.nil?; @success; end
  def success=(val); @success = val; end

  def self.instructions; @@instructions; end
  def self.instructions=(val); @@instructions = val; end

  def instructions; @instructions = @@instructions if @instructions.nil?; @instructions; end
  def instructions=(val); @instructions = val; end

  def self.has_redirect; @@has_redirect; end
  def self.has_redirect=(val); @@has_redirect = val; end

  def has_redirect; @has_redirect = @@has_redirect if @has_redirect.nil?; @has_redirect; end
  def has_redirect=(val); @has_redirect = val; end

  def self.hash; @@hash; end
  def self.hash=(val); @@hash = val; end

  def hash; @hash = @@hash if @hash.nil?; @hash; end
  def hash=(val); @hash = val; end

  def self.redirect_url; @@redirect_url; end
  def self.redirect_url=(val); @@redirect_url = val; end

  def redirect_url; @redirect_url = @@redirect_url if @redirect_url.nil?; @redirect_url; end
  def redirect_url=(val); @redirect_url = val; end

  def self.error; @@error; end
  def self.error=(val); @@error = val; end

  def error; @error = @@error if @error.nil?; @error; end
  def error=(val); @error = val; end

  def self.poll_url; @@poll_url; end
  def self.poll_url=(val); @@poll_url = val; end

  def poll_url; @poll_url = @@poll_url if @poll_url.nil?; @poll_url; end
  def poll_url=(val); @poll_url = val; end
end

class Payment
  @@reference = String
  @@items = []
  @@auth_email = String

  def initialize(reference, auth_email)
    @reference = reference
    @auth_email = auth_email
  end

  def add(title, amount)
    @items = []
    @items.push([title, amount])
    return self
  end

  def total()
    total = 0.0
    for item in @items
      total += item[1].to_f
    end
    return total
  end

  def info()
    out = ""
    for item in @items
      out += item[0] + ", "
    end
    return out
  end

  def self.reference; @@reference; end
  def self.reference=(val); @@reference = val; end

  def reference; @reference = @@reference if @reference.nil?; @reference; end
  def reference=(val); @reference = val; end

  def self.items; @@items; end
  def self.items=(val); @@items = val; end

  def items; @items = @@items if @items.nil?; @items; end
  def items=(val); @items = val; end

  def self.auth_email; @@auth_email; end
  def self.auth_email=(val); @@auth_email = val; end

  def auth_email; @auth_email = @@auth_email if @auth_email.nil?; @auth_email; end
  def auth_email=(val); @auth_email = val; end
end

class Paynow
  @@URL_INITIATE_TRANSACTION = "https://www.paynow.co.zw/interface/initiatetransaction"
  @@URL_INITIATE_MOBILE_TRANSACTION = "https://www.paynow.co.zw/interface/remotetransaction"
  @@integration_id = String
  @@integration_key = String
  @@return_url = ""
  @@result_url = ""

  def initialize(integration_id, integration_key, return_url, result_url)
    @integration_id = integration_id
    @integration_key = integration_key
    @return_url = return_url
    @result_url = result_url
  end

  def set_result_url(url)
    @result_url = url
  end

  def set_return_url(url)
    @return_url = url
  end

  def create_payment(reference, auth_email)
    return Payment.new(reference, auth_email)
  end

  def send(payment)
    return __init(payment)
  end

  def send_mobile(payment, phone, method)
    return __init_mobile(payment, phone, method)
  end

  def process_status_update(data)
    return StatusResponse.new(data, true)
  end

  def qs_to_hash(querystring)
    keyvals = querystring.split("&").inject({}) do |result, q|
      k, v = q.split("=")
      if !v.nil?
        result.merge({ k => v })
      elsif !result.key?(k)
        result.merge({ k => true })
      else
        result
      end
    end
    keyvals
  end

  def __init(payment)
    if payment.total() <= 0
      raise TypeError, "Transaction total cannot be less than 1"
    end
    data = __build(payment)
    response = requests.HTTParty.post(@URL_INITIATE_TRANSACTION, data)
    response_object = __rebuild_response(CGI.parse(response.txt))
    if response_object["status"].to_s.downcase() == "error"
      return InitResponse.new(response_object)
    end
    if is_bool(!__verify_hash(response_object, @integration_key))
      raise HashMismatchException, "Hashes do not match"
    end
    return InitResponse.new(response_object)
  end

  def __init_mobile(payment, phone, method)
    if payment.total() <= 0
      raise TypeError, "Transaction total cannot be less than 1"
    end
    if is_bool(!payment.auth_email || payment.auth_email.size <= 0)
      raise TypeError, "Auth email is required for mobile transactions. You can pass the auth email as the second parameter in the create_payment method call"
    end
    data = __build_mobile(payment, phone, method)
    response = requests.HTTParty.post(@URL_INITIATE_TRANSACTION, data)
    response_object = __rebuild_response(CGI.parse(response.txt))
    if response_object["status"].to_s.downcase() == "error"
      return InitResponse.new(response_object)
    end
    if is_bool(!__verify_hash(response_object, @integration_key))
      raise HashMismatchException, "Hashes do not match"
    end
    return InitResponse.new(response_object)
  end

  def check_transaction_status(poll_url)
    response = requests.HTTParty.post(poll_url, data: {})
    response_object = __rebuild_response(CGI.parse(response.txt))
    return StatusResponse.new(response_object, false)
  end

  def __build(payment)
    body = { "resulturl" => @result_url, "returnurl" => @return_url, "reference" => payment.reference, "amount" => payment.total(), "id" => @integration_id, "additionalinfo" => payment.info(), "authemail" => payment.auth_email || "", "status" => "Message" }
    for (key, value) in body.to_a()
      body[key] = CGI::escape(value.to_s)
    end
    body["hash"] = __hash(body, @integration_key)
    return body
  end

  def __build_mobile(payment, phone, method)
    body = { "resulturl" => @result_url, "returnurl" => @return_url, "reference" => payment.reference, "amount" => payment.total(), "id" => @integration_id, "additionalinfo" => payment.info(), "authemail" => payment.auth_email, "phone" => phone, "method" => method, "status" => "Message" }
    for (key, value) in body.to_a()
      if key == "authemail"
        next
      end
      body[key] = CGI::escape(value.to_s)
    end
    body["hash"] = __hash(body, @integration_key)
    return body
  end

  def __hash(items, integration_key)
    out = ""
    for (key, value) in items.to_a()
      if key.to_s.downcase() == "hash"
        next
      end
      out += value.to_s
    end
    out += integration_key.downcase()
    return Digest::SHA2.new(512).hexdigest(@out).upcase
  end

  def __verify_hash(response, integration_key)
    if !response.include?("hash")
      raise TypeError, "Response from Paynow does not contain a hash"
    end
    old_hash = response["hash"]
    new_hash = __hash(response, integration_key)
    return old_hash == new_hash
  end

  def __rebuild_response(response)
    res = {}
    for (key, value) in response.to_a()
      res[key] = value[0].to_s
    end
    return res
  end

  def self.URL_INITIATE_TRANSACTION; @@URL_INITIATE_TRANSACTION; end
  def self.URL_INITIATE_TRANSACTION=(val); @@URL_INITIATE_TRANSACTION = val; end

  def URL_INITIATE_TRANSACTION; @URL_INITIATE_TRANSACTION = @@URL_INITIATE_TRANSACTION if @URL_INITIATE_TRANSACTION.nil?; @URL_INITIATE_TRANSACTION; end
  def URL_INITIATE_TRANSACTION=(val); @URL_INITIATE_TRANSACTION = val; end

  def self.URL_INITIATE_MOBILE_TRANSACTION; @@URL_INITIATE_MOBILE_TRANSACTION; end
  def self.URL_INITIATE_MOBILE_TRANSACTION=(val); @@URL_INITIATE_MOBILE_TRANSACTION = val; end

  def URL_INITIATE_MOBILE_TRANSACTION; @URL_INITIATE_MOBILE_TRANSACTION = @@URL_INITIATE_MOBILE_TRANSACTION if @URL_INITIATE_MOBILE_TRANSACTION.nil?; @URL_INITIATE_MOBILE_TRANSACTION; end
  def URL_INITIATE_MOBILE_TRANSACTION=(val); @URL_INITIATE_MOBILE_TRANSACTION = val; end

  def self.integration_id; @@integration_id; end
  def self.integration_id=(val); @@integration_id = val; end

  def integration_id; @integration_id = @@integration_id if @integration_id.nil?; @integration_id; end
  def integration_id=(val); @integration_id = val; end

  def self.integration_key; @@integration_key; end
  def self.integration_key=(val); @@integration_key = val; end

  def integration_key; @integration_key = @@integration_key if @integration_key.nil?; @integration_key; end
  def integration_key=(val); @integration_key = val; end

  def self.return_url; @@return_url; end
  def self.return_url=(val); @@return_url = val; end

  def return_url; @return_url = @@return_url if @return_url.nil?; @return_url; end
  def return_url=(val); @return_url = val; end

  def self.result_url; @@result_url; end
  def self.result_url=(val); @@result_url = val; end

  def result_url; @result_url = @@result_url if @result_url.nil?; @result_url; end
  def result_url=(val); @result_url = val; end
end
