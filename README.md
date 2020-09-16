# PaynowSdk Ruby gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paynow_sdk'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install paynow_sdk

## Usage

Create an instance of the Paynow class optionally setting the result and return url(s)

```ruby
paynow = Paynow.new(
	'INTEGRATION_ID',
	'INTEGRATION_KEY',
	'http://returnurl.com',
	'http://resulturl.com'
	)
```

Create a new payment passing in the reference for that payment (e.g invoice id, or anything that you can use to identify the transaction and the user's email address

```ruby
payment = paynow.create_payment('Order #100', 'test@example.com')
```

You can then start adding items to the payment

```ruby
# Passing in the name of the item and the price of the item
payment.add('Bananas', 2.50)
payment.add('Apples', 3.40)
```

When you're finally ready to send your payment to Paynow, you can use the `send` method in the `paynow` object.

```ruby
# Save the response from paynow in a variable
response = paynow.send(payment)
```

The response from Paynow will be have some useful information like whether the request was successful or not. If it was, for example, it contains the url to redirect the user so they can make the payment.

If request was successful, you should consider saving the poll url sent from Paynow in the database

```ruby
if response.success
    # The link to redirect the user to paynow to make the payment
	link = response.redirect_url
	# Get the poll url (used to check the status of a transaction). You might want to save this in your DB
    pollUrl = response.poll_url
end
```

---

> Mobile Transactions

If you want to send an express (mobile) checkout request instead, the only thing that differs is the last step. You make a call to the `send_mobile` in the `paynow` object
instead of the `send` method.

The `send_mobile` method unlike the `send` method takes in two additional arguments i.e The phone number to send the payment request to and the mobile money method to use for the request. **Note that currently only ecocash is supported**

```ruby
# Save the response from paynow in a variable
response = paynow.send_mobile(payment, '0777777777', 'ecocash')
```

The response object is almost identical to the one you get if you send a normal request. With a few differences, firstly, you don't get a url to redirect to. Instead you instructions (which ideally should be shown to the user instructing them how to make payment on their mobile phone)

```ruby
if response.success
	# Get the poll url (used to check the status of a transaction). You might want to save this in your DB
    poll_url = response.poll_url

    instructions = response.instructions
end
```

# Checking transaction status

The SDK exposes a handy method that you can use to check the status of a transaction.

```ruby
# Check the status of the transaction with the specified poll url
#if you saved your poll url in the database you can use this function "PaynowStatus.check_transcation_status(poll_url)" to check the status of the payment

status = PaynowStatus.check_transcation_status(poll_url)

if status.paid
	render page
	print "Payment successfull"
else
	print "Not Paid"
end
```

# Full Usage Example

```ruby
gem 'paynow_sdk'
```

And then execute:

```ruby
    $ bundle install
```

Or install it yourself as:

```ruby
    $ gem install paynow_sdk
```

```ruby
paynow = Paynow.new(
	'INTEGRATION_ID',
	'INTEGRATION_KEY',
	'http://returnurl.com',
	'http://resulturl.com'
	)

payment = paynow.create_payment('Order Number', 'test@example.com')

payment.add('Payment for stuff', 99.99)

response = paynow.send(payment)


if response.success
 # The link to redirect the user to paynow to make the payment
    link = response.redirect_url

    poll_url = response.poll_url
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gitnyasha/paynow-ruby-sdk.
