# BunnyFarm

A very simplistic AMQP/JSON-based background job manager.

The bunny farm is an abstraction in which the messages are encapsulated as classes.  Instances of these BunnyFarm::Messages are hopping around the RabbitMQ as JSON strings with routing keys in the form of MessageClassName.action where action is a method on the MessageClassName instance.

## Why?

- Simplistic?  Because extensive is sometimes overkill.
- JSON?        Because binary compression is sometimes overkill.
- Bunny?       Who doen't like bunnies?  They're like cats with long ears.
- AMQP?        I like AMQP.  I like RabbitMQ as an AMQP broker.

BTW, at the farm bunnies are best if planted ears up.


## How?

Use system environment variables.  Such as:

```bash
export AMQP_HOST=amqp.example.com
export AMQP_VHOST=sandbox
export AMQP_EXCHANGE=sandbox
export AMQP_QUEUE=tv_show_suggestions
export AMQP_ROUTING_KEY="'TvShowSuggestion.subnit'"
export AMQP_PASS=guest
export AMQP_USER=guest
```

If you don't know how AMQP works you had better go study.  The
values above were selected to match the demo code below.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bunny_farm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bunny_farm

## Usage

The shortest job manager / message processor looks like this:

```Ruby
require 'bunny_farm'
require 'my_message_class'
BunnyFarm.init
BunnyFarm.run
```

Here is how to publish messages:

```Ruby
require 'bunny_farm'
require 'my_message_class'

AMQP_CONFIG.app_id = 'my job name'

BunnyFarm.init

mm = MyMessageClass.new

mm[:field1] = 'Hello'
mm[:field2] = 'World'
# ...
mm[:fieldn] = 'whatever'

mm.publish('action') # routing key becomes: MyMessageClass.action

puts 'It worked' if mm.successful?

if mm.failed?
  puts 'This sucks.  Here are some errors:'
  puts mm.errors.join("\n")
end
# rinse and repeat as necessary
```


All of the processing is done in YourMessageClass.  The
AMQP routing keys look like: "YourMessageClass.action" and
guess what the "action" is... a method in YourMessageClass.

So assume that I have a public facing website which allows users
to fill our forms for various purposes.  Say that one of those
forms is to collect suggestions for episodes of a TV show.  I would have a
form with fields that collect informaion about the user as well as a field
where their suggestion is recorded.  As a hash it might looks something
like this:

```Ruby
form_contents = {
	author: {
		name: 'Jimmy Smith',
		mailing_address: '123 Main St. USA',
		email_address: 'little_jimmy@smith.us',
		phone_number: '+19995551212'
	},
	tv_show_name: 'Lost In Space',
	suggestion: 'Why does doctor Smith have to be such a meanie?',
	lots_of_other_house_keeping_junk: {}
}
```

The website turns that hash into a json package and publishes it
via an AMQP broker.  I like RabbitMQ.  The published message has
a routing key of 'TvShowSuggestion.submit'

In the file tv_show_suggestion.rb you could have something like this:

```Ruby
class TvShowSuggestion < BunnyFarm::Message

  items :tv_show_name, :suggestion,
    { author: [ :name, :mailing_address, :email_address, :phone_number ]}

	actions :submit

	def submit
		# TODO: anything you want.
		save_suggestion
		notify_writers  if success?
		success? ? send_thank_you : send_sorry_please_try_again
		auccess!
		some_super_class_service
		successful? # true will ACK the message; false will not
	end

private

	def save_suggestion
		puts @items[:suggestion]
		success
	end

	def notify_writers
		puts 'Hey slackers! what about #{@items[:suggestions]}'
		failure('Writers were sleeping')
	end

	def send_thank_you
		puts "Thank you goes to #{@items[:author][:name]}"
		success
	end

	def send_sorry_please_try_again
		STDERR.puts "Sorry #{@items[:author][:name]}, please try again later."
	end
end # class TvShowSuggestion < BunnyFarmMessage
```

## Contributing

Remember the key design goal is K.I.S.S.  Edge cases and exotic stuff
are not what life is like on the bunny farm.

1. Fork it ( https://github.com/[my-github-username]/bunny_farm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
