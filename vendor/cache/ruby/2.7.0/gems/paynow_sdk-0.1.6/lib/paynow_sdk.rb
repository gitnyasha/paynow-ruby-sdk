require "paynow_sdk/version"
require "httparty"
require "cgi"
require "digest"

#throws error when hash from Paynow does not match locally generated hash

class HashMismatch < StandardError
  def initialize(message)
    super(message)
  end
end

# status of the transaction

class StatusResponse
  attr_accessor :paid, :status, :amount, :reference, :paynow_reference, :hash.to_s

  def initialize(data, update)
    @data = data
    @update = update
    if update
      self.status_update(data)
    else
      @status = data["status"].downcase
      @paid = self.status == "paid"

      if data.include?("amount")
        @amount = data["amount"].to_f
      end
      if data.include?("reference")
        @reference = data["reference"].to_s
      end
      if data.include?("paynow_reference")
        @paynow_reference = data["paynow_reference"].to_s
      end
      if data.include?("hash")
        @hash = data["hash"]
      end
    end
  end

  def self.status_update(data)
    "Not Implemented"
  end
end

#response from paynow during transaction

class InitialResponse
  attr_accessor :success, :has_redirect, :hash, :redirect_url, :error, :poll_url

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

  def initialize(integration_id, integration_key, return_url, result_url)
    @integration_id = integration_id
    @integration_key = integration_key
    @return_url = return_url
    @result_url = result_url
  end

  def self.result_url(url)
    result_url = url
  end

  def create_payment(reference, auth_email)
    Payment.new(reference, auth_email)
  end

  def send(payment)
    paying(payment)
  end

  # def send_mobile(payment, phone, method)
  #   paying_mobile(payment, phone, method)
  # end

  def process_status_update(data)
    return StatusResponse(data)
  end

  #send the payment body to the paynow api through httparty
  def paying(payment)
    # if payment.total <= 0
    #   raise "Transaction total cannot be less than 1"
    # end
    url_initiate_transaction = "https://www.paynow.co.zw/interface/initiatetransaction"

    data = build(payment)
    @response = HTTParty.post(url_initiate_transaction, data)
    @response_object = @response.parsed_response

    # if @response_object.status == "error"
    #   InitalResponse.new(@response_object)
    # end
    # if !verify_hash(@response_object, integration_key)
    #   HashMismatchException("Hashes do not match")
    # end
    InitialResponse.new(@response_object)
  end

  # def paying_mobile(payment, phone, method)
  #   # if payment.total <= 0
  #   #   raise "Transaction total cannot be less than 1"
  #   # end

  #   # if !payment.auth_email || payment.auth_email.length <= 0
  #   #   raise "Auth email is required for mobile transactions. You can pass the auth email as the "
  #   #   "second parameter in the create_payment method call"
  #   # end
  #   url_initiate_mobile_transaction = "https://www.paynow.co.zw/interface/remotetransaction"

  #   data = build(payment, phone, method)

  #   @response = HTTParty.post(url_initiate_mobile_transaction, data).to_json
  #   @response_object = rebuild_response(response.parsed_response)

  #   if response_object["status"].to_s == "error"
  #     InitalResponse.new(response_object)
  #   end
  #   if !verify_hash(response_object, integration_key)
  #     raise HashMismatchException("Hashes do not match")
  #   end
  #   InitalResponse.new(response_object)
  # end

  def check_transaction_status(poll_url)
    @response = HTTParty.post(poll_url, data)
    @response_object = response.parsed_response

    StatusResponse.new(@response_object)
  end

  def build(payment)
    body = {
      "id": @integration_id.to_s,
      "resulturl": result_url,
      "returnurl": return_url,
      "reference": payment.reference,
      "amount": payment.total,
      "additionalinfo": payment.info,
      "authemail": payment.auth_email,
      "status": "Message",
    }

    #1 join all values into one long string
    body.each do |key, value|
      body[key] = %q[value].to_s
    end

    # 2 Add integration key to the string
    body["hash"] = ahash(body, integration_key)

    body
  end

  # def build_mobile(payment, phone, method)
  #   body = {
  #     "resulturl": @result_url,
  #     "returnurl": @return_url,
  #     "reference": payment.reference,
  #     "amount": payment.total,
  #     "id": @integration_id,
  #     "additionalinfo": payment.info,
  #     "authemail": payment.auth_email || "",
  #     "phone": phone,
  #     "method": method,
  #     "status": "Message",
  #   }

  #   body.each do |key, value|
  #     if key == "authemail"
  #       next
  #     end

  #     body[key] = %q[value].to_s
  #   end

  #   body["hash"] = ahash(body, integration_key)
  #   body
  # end

  # Encrypt the string from body with sha512 and convert to uppercase

  def ahash(body, integration_key)
    @out = body.values.to_s
    @out += integration_key.downcase

    Digest::SHA2.new(512).hexdigest(@out).upcase
  end

  # def verify_hash(response, integration_key)
  #   if "hash" != response
  #     raise "Response from Paynow does not contain a hash"
  #   end

  #   old_hash = response["hash"]
  #   new_hash = ahash(response, integration_key)

  #   old_hash == new_hash
  # end
end
