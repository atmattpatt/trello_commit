# TrelloCommit

Bring Trello into your commit messages

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trello_commit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trello_commit

## Authentication

You'll need an API key from Trello in order for TrelloCommit to work.

    trello_commit --login

This command will help you authenticate with Trello.

## Usage

    trello_commit

This will prompt you to select a Trello card to which your commit is
related. Then, your editor will be opened with text pre-populated for
your commit message.

    trello_commit --configure

This will help you set up narrow down which boards and lists you want
to use for TrelloCommit.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
