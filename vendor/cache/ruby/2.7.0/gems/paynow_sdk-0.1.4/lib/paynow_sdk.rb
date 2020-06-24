require "paynow_sdk/version"
require "httparty"

#throws error when hash from Paynow does not match locally generated hash

class HashMismatch < StandardError
  def initialize(message)
    super(message)
  end
end

# status of the transaction

class StatusResponse
  attr_accessor :paid, :status, :amount, :reference, :paynow_reference, :hash

  def initialize(data, update)
    @data = data
    @update = update
    if update
      self.status_update(data)
    else
      self.status = data["status"].downcase
      self.paid = self.status == "paid"

      if data.include?("amount")
        self.amount = data["amount"].to_f
      end
      if data.include?("reference")
        self.reference = data["reference"].to_s
      end
      if data.include?("paynow_reference")
        self.paynow_reference = data["paynow_reference"].to_s
      end
      if data.include?("hash")
        self.hash = data["hash"]
      end
    end
  end

  def self.status_update(data)
    print "Not Implemented"
  end
end

#response from paynow during transaction

class InitialResponse
  attr_accessor :success, :instructions, :has_redirect, :hash, :redirect_url, :error, :poll_url

  def initialize(data)
    @data = data

    @status = data["status"]
    @success = data["status"].downcase != "error"
    @has_redirect = data["browserurl"]
    @hash = data["hash"]

    if !success
      @poll_url = data["pollurl"]
      @error = data["error"]
    end
    if !has_redirect
      @redirect_url = data["browserurl"]
    end
    if data.include?(instructions)
      @instruction = data["instructions"]
    end
  end
end

#Create a transaction

class Payment
  attr_accessor :items, :auth_email, :reference

  def initialize(reference, auth_email)
    @reference = reference
    @auth_email = auth_email
  end

  def add(title, amount)
    @items = []
    @items.push([title, amount])
  end

  def total
    @total = 0.0
    @items.map do |item|
      @total += item[1]
      @total
    end
  end

  def info
    @ticket = ""
    @items.each do |item|
      @ticket += item[0] + ", "
      @ticket
    end
  end
end

class Paynow
  attr_accessor :integration_id, :integration_key, :return_url, :result_url

  @url_initiate_mobile_transaction = "https://www.paynow.co.zw/interface/remotetransaction"

  def initialize(integration_id, integration_key, return_url, result_url)
    @integration_id = integration_id
    @integration_key = integration_key
    @return_url = return_url
    @result_url = result_url
  end

  def self.result_url(url)
    self.result_url = url
  end

  def create_payment(reference, auth_email)
    Payment.new(reference, auth_email)
  end

  def send(payment)
    paying(payment)
  end

  def send_mobile(payment, phone, method)
    return paying_mobile(payment, phone, method)
  end

  def process_status_update(data)
    return StatusResponse(data)
  end

  def paying(payment)
    # if payment.total <= 0
    #   raise "Transaction total cannot be less than 1"
    # end

    data = build(payment)
    url_initiate_transaction = "https://www.paynow.co.zw/interface/initiatetransaction"
    response = HTTParty.post(url_initiate_transaction, data)
    response_object = rebuild_response(response.parsed_response)

    if response_object.status.to_s == "error"
      InitalResponse.new(response_object)
    end
    if !verify_hash(response_object, integration_key)
      HashMismatchException("Hashes do not match")
    end
    InitalResponse.new(response_object)
  end

  def paying_mobile(payment, phone, method)
    # if payment.total <= 0
    #   raise "Transaction total cannot be less than 1"
    # end

    # if !payment.auth_email || payment.auth_email.length <= 0
    #   raise "Auth email is required for mobile transactions. You can pass the auth email as the "
    #   "second parameter in the create_payment method call"
    # end

    data = build(payment, phone, method)

    response = HTTParty.post(url_initiate_mobile_transaction, data)
    response_object = rebuild_response(response.parsed_response)

    if response_object["status"].to_s == "error"
      return InitalResponse.new(response_object)
    end
    if !verify_hash(response_object, integration_key)
      raise HashMismatchException("Hashes do not match")
    end
    return InitalResponse.new(response_object)
  end

  def self.check_transaction_status(poll_url)
    response = HTTParty.post(poll_url, data)
    response_object = rebuild_response(response.parsed_response)

    return StatusResponse.new(response_object)
  end

  def build(payment)
    body = {
      "resulturl": result_url,
      "returnurl": return_url,
      "reference": payment.reference,
      "amount": payment.total,
      "id": integration_id,
      "additionalinfo": payment.info,
      "authemail": payment.auth_email,
      "status": "Message",
    }

    body.each do |key, value|
      body[key] = %q[value].to_s
    end

    body["hash"] = ahash(body, integration_key)

    return body
  end

  def build_mobile(payment, phone, method)
    body = {
      "resulturl": result_url,
      "returnurl": return_url,
      "reference": payment.reference,
      "amount": payment.total,
      "id": integration_id,
      "additionalinfo": payment.info,
      "authemail": payment.auth_email || "",
      "phone": phone,
      "method": method,
      "status": "Message",
    }

    body.each do |key, value|
      if key == "authemail"
        next
      end

      body[key] = %q[value].to_s
    end

    body["hash"] = ahash(body, integration_key)

    return body
  end

  def ahash(items, integration_key)
    out = ""
    items.each do |key, value|
      if key.to_s.downcase == "hash"
        next
      end
      out = value.to_s
    end
    out += integration_key.downcase

    # return hashlib.sha512(out.encode('utf-8')).hexdigest().upper()
  end

  def self.verify_hash(response, integration_key)
    if "hash" != response
      raise "Response from Paynow does not contain a hash"
    end

    old_hash = response["hash"]
    new_hash = self.ahash(response, integration_key)

    return old_hash == new_hash
  end

  #building the response into a key/value pair hash
  def rebuild_response(response)
    res = {}
    response.each do |key, array|
      array.each do |value|
        res[key] = value[0].to_s
      end
    end
    res
  end
end
