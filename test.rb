# require "digest"
# require "cgi"
require "uri"

# @inter = "3e9fed89-60e1-4ce5-ab6e-6b1eb2d4f977"
# url_initiate_transaction = "https://www.paynow.co.zw/interface/initiatetransaction/"

# def build
#   body = {
#     "id": "1201",
#     "reference": "TEST REF",
#     "amount": "99.99",
#     "additionalinfo": "A test ticket transaction",
#     "returnurl": "http://www.google.com/search?q=returnurl",
#     "resulturl": "http://www.google.com/search?q=resulturl",
#     "status": "Message",
#   }

#   joined = body.values.join.to_s
#   add_key = joined += @inter
#   body["hash"] = hash(add_key)
#   body = URI.encode_www_form(body)
#   p body
# end

# def hash(encrypt)
#   Digest::SHA2.new(512).hexdigest(encrypt).upcase
# end

# def something
#   build = "http://www.example.com/something?param1=value1&param2=value2&param3=value3"
#   rebuild(build)
# end

# def rebuild(parm)
#   joined = CGI.parse(parm)
#   add_key = joined.values.join.to_s
#   reb = add_key += @inter
#   hash(reb)
# end

# def init(payment)
#   if payment.total <= 0
#     raise TypeError, "Transaction total cannot be less than 1"
#   end
#   data = build(payment)

#   response = HTTParty.post(@url_initiate_mobile_transaction, data)
#   response_object = rebuild_response(CGI::parse(response))
# end

build = "id=1201&reference=TEST+REF&amount=99.99&additionalinfo=A+test+ticket+transaction&returnurl=http%3A%2F%2Fwww.google.com%2Fsearch%3Fq%3Dreturnurl&resulturl=http%3A%2F%2Fwww.google.com%2Fsearch%3Fq%3Dresulturl&status=Message&hash=2A033FC38798D913D42ECB786B9B19645ADEDBDE788862032F1BD82CF3B92DEF84F316385D5B40DBB35F1A4FD7D5BFE73835174136463CDD48C9366B0749C689"

p URI.decode_www_form(build).to_h
