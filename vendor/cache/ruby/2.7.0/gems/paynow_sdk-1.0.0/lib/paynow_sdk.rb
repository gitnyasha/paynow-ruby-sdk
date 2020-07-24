require "paynow_sdk/version"
require "cgi"
require "digest"
require "uri"
require "net/http"

#throws error when hash from Paynow does not match locally generated hash

class HashMismatchException < Exception
  def initialize(message)
    super(message)
  end
end

#Returns the status of the payment

class StatusResponse
  @@paid = true
  @@status = ""
  @@amount = 0.0
  @@reference = ""
  @@paynow_reference = ""
  @@hash = ""

  def status_update(data)
    return "Not implemented"
  end

  def initialize(data, update)
    if update
      status_update(data)
    else
      @status = data["status"].downcase
      @paid = @status == "paid"
      if data.include?("amount")
        @amount = data["amount"].round(2)
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
  @@instructions = ""
  @@has_redirect = true
  @@hash = ""
  @@redirect_url = ""
  @@error = ""
  @@poll_url = ""

  def initialize(data)
    @status = data["status"]
    @success = data["status"].downcase != "error"
    @has_redirect = data.include?("browserurl")
    @hash = data.include?("hash")
    if @success
      @poll_url = data["pollurl"]
    end
    if !@success
      @error = data["error"]
    end
    if @has_redirect
      puts @redirect_url = data["browserurl"]
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
  @@reference = ""
  @@items = []
  @@auth_email = ""

  def initialize(reference, auth_email)
    @reference = reference
    @auth_email = auth_email
  end

  def add(title, amount)
    @items = []
    @items.push([title, amount])
    self
  end

  def total
    total = 0
    for item in @items
      total += item[1]
    end
    total.round(2)
  end

  def info
    out = ""
    for item in @items
      out += item[0]
    end
    out
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
    Payment.new(reference, auth_email)
  end

  def send(payment)
    init(payment)
  end

  def send_mobile(payment, phone, method)
    init_mobile(payment, phone, method)
  end

  def process_status_update(data)
    StatusResponse.new(data, true)
  end

  def init(payment)
    if payment.total <= 0
      raise TypeError, "Transaction total cannot be less than 1"
    end

    data = build(payment)

    url = URI("https://www.paynow.co.zw/interface/initiatetransaction/")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["content-type"] = "application/x-www-form-urlencoded"
    request.body = data

    response = http.request(request)
    response.read_body

    response_object = rebuild_response(response.read_body)

    if response_object["status"].to_s.downcase == "error"
      InitResponse.new(response_object)
    end
    if !verify_hash(response_object)
      raise HashMismatchException, "Hashes do not match"
    end
    InitResponse.new(response_object)
  end

  def init_mobile(payment, phone, method)
    if payment.total <= 0
      raise TypeError, "Transaction total cannot be less than 1"
    end
    if !payment.auth_email || payment.auth_email.size <= 0
      raise TypeError, "Auth email is required for mobile transactions. You can pass the auth email as the second parameter in the create_payment method call"
    end

    data = build_mobile(payment, phone, method)

    url = URI("https://www.paynow.co.zw/interface/remotetransaction")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["content-type"] = "application/x-www-form-urlencoded"
    request.body = data

    response = http.request(request)
    response.read_body

    response_object = rebuild_response(response.read_body)

    if response_object["status"].to_s.downcase == "error"
      InitResponse.new(response_object)
    end
    if !verify_hash(response_object)
      raise HashMismatchException, "Hashes do not match"
    end
    InitResponse.new(response_object)
  end

  def check_transaction_status(poll_url)
    url = URI(poll_url)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["content-type"] = "application/x-www-form-urlencoded"
    request.body = data

    response = http.request(request)
    response.read_body

    response_object = rebuild_response(response.read_body)
    StatusResponse.new(response_object, false)
  end

  #web payments

  def build(payment)
    body = {
      "id": @integration_id,
      "reference": payment.reference,
      "amount": payment.total,
      "additionalinfo": payment.info,
      "returnurl": @return_url,
      "resulturl": @result_url,
      "authemail": payment.auth_email,
      "status": "Payment for goods",
    }

    joined = body.values.join
    add_key = joined += @integration_key
    body["hash"] = createdhash(add_key)
    body = URI.encode_www_form(body)
    body
  end

  #mobile payments

  def build_mobile(payment, phone, method)
    body = {
      "resulturl": @result_url,
      "returnurl": @return_url,
      "reference": payment.reference,
      "amount": payment.total,
      "id": @integration_id,
      "additionalinfo": payment.info,
      "authemail": payment.auth_email,
      "phone": phone,
      "method": method,
      "status": "Message",
    }

    joined = body.values.join
    add_key = joined += @integration_key
    body["hash"] = createdhash(add_key)
    body = URI.encode_www_form(body)
    body
  end

  def createdhash(out)
    Digest::SHA2.new(512).hexdigest(out).upcase
  end

  #verify the hash send to paynow is equal to the hash from paynow
  def verify_hash(response)
    if !response.include?("hash")
      raise TypeError, "Response from Paynow does not contain a hash"
    end
    old_hash = response["hash"]
    new_hash = verify(response)
    old_hash == new_hash
  end

  def verify(item)
    out = ""
    for key, value in item
      if key.to_s == "hash"
        next
      end
      out += value.to_s
    end
    out += @integration_key.downcase
    Digest::SHA2.new(512).hexdigest(out).upcase
  end

  #  rebuild a response from paynow into hash like the we send

  def rebuild_response(response)
    URI.decode_www_form(response).to_h
  end

  def self.url_initiate_transaction; @@url_initiate_transaction; end
  def self.url_initiate_transaction=(val); @@url_initiate_transaction = val; end

  def url_initiate_transaction; @url_initiate_transaction = @@url_initiate_transaction if @url_initiate_transaction.nil?; @url_initiate_transaction; end
  def url_initiate_transaction=(val); @url_initiate_transaction = val; end

  def self.url_initiate_mobile_transaction; @@url_initiate_mobile_transaction; end
  def self.url_initiate_mobile_transaction=(val); @@url_initiate_mobile_transaction = val; end

  def url_initiate_mobile_transaction; @url_initiate_mobile_transaction = @@url_initiate_mobile_transaction if @url_initiate_mobile_transaction.nil?; @url_initiate_mobile_transaction; end
  def url_initiate_mobile_transaction=(val); @url_initiate_mobile_transaction = val; end

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
