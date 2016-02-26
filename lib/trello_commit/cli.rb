require "logger"
require "optparse"
require "tempfile"

class TrelloCommit::CLI
  attr_reader :config, :logger, :options

  def initialize
    @logger = Logger.new(STDERR)
    logger.level = Logger::INFO

    Trello.logger = logger

    @options = OptionParser.new do |opts|
      opts.banner = "Usage: trello_commit [OPTIONS]"

      opts.on("-v", "--verbose", "Run with verbose output") do
        logger.level = Logger::DEBUG
      end

      opts.on("-h", "--help", "Print help message") do
        puts options
        exit 0
      end

      opts.on("--login") do
        login
        exit 0
      end

      opts.on("--configure") do
        configure
        exit 0
      end
    end
  end

  def commit
    load_config

    cards = config.boards.flat_map do |board_config|
      board = Trello::Board.find(board_config[:id])
      board.cards.reject(&:closed?)
    end

    cards.each do |card|
      labels = card.card_labels.map do |label|
        "[" + label["name"].colorize(trello_color(label["color"])) + "]"
      end

      puts "#{trello_id(card.short_url)} #{card.name} #{labels.join(" ")}"
    end
  end

  def configure
    load_config

    boards_file = Tempfile.new("trello_commit_boards")
    boards_file.write(<<-EOF)
# Trello Boards
# =============
#
# Below is a list of all of the Trello boards that you have access to.
# To exclude a board from Trello commit, simply delete the line containing
# the board.
#
    EOF

    if config.boards.any?
      boards_file.write("\n")
      boards_file.write("# Boards you are already watching\n")
    end

    config.boards.each do |existing_board|
      boards_file.write(existing_board[:id] + " ")
      boards_file.write(existing_board[:name] + "\n")
    end

    boards = Trello::Board.all
    boards.group_by(&:organization_id).each do |organization_id, organization_boards|
      boards_file.write("\n")
      if organization_id
        organization = Trello::Organization.find(organization_id)
        boards_file.write("# #{organization.display_name}\n")
      else
        boards_file.write("# My Boards\n")
      end

      organization_boards.each do |board|
        next if board.closed?

        boards_file.write(board.id)
        boards_file.write(" ")
        boards_file.write(board.name)

        if board.starred?
          boards_file.write(" (★ )")
        end

        boards_file.write("\n")
      end
    end

    boards_file.close
    edit(boards_file)

    boards_file.open

    config.boards = []
    boards_file.each_line do |line|
      next if line.blank?
      next if line.start_with?("#")

      id, name = line.split(" ", 2)
      config.boards << {id: id, name: name.strip}
    end

    config.boards.uniq! { |board| board[:id] }

    config.save

    puts "Alright, #{config.boards.length} board(s) will be used for finding Trello cards.".colorize(:green)
  ensure
    boards_file.unlink if boards_file
  end

  def login
    load_config

    if authenticated?
      puts "You are already authenticated as #{config.full_name} (#{config.username}).".colorize(:green)
      print "Do you want to use these credentials? (y/n): "

      return if $stdin.readline.match(/^y/i)

      puts ""
      print "Okay, we'll set up new credentials. "
    end

    puts "In order to use trello_commit, you must have an API key and auth token."
    puts ""
    puts "To generate an API key, visit this URL in your browser:".colorize(:green)
    puts Trello.public_key_url
    puts ""
    puts "Now, enter the API key below:".colorize(:green)
    print "> "

    api_key = $stdin.readline.strip

    puts ""
    puts "Great! Now for the auth token, visit this URL:".colorize(:green)
    puts Trello.authorize_url(key: api_key, name: "Trello Commit", scope: "read")
    puts ""
    puts "Now, enter the token below:".colorize(:green)
    print "> "

    auth_token = $stdin.readline.strip

    puts ""
    puts "Wonderful! Let's make sure this works..."

    Trello.configure do |config|
      config.developer_public_key = api_key
      config.member_token = auth_token
    end

    me = Trello::Member.find("me")
    puts "Hey, #{me.full_name}, it worked!".colorize(:green)

    puts ""
    puts ("Be careful if you use a shared environment! This API key and " +
      "auth token tie directly to YOUR Trello account. You should remove them " +
      "when you finish working.").colorize(:yellow)

    config.api_key = api_key
    config.auth_token = auth_token
    config.full_name = me.full_name
    config.username = me.username
    config.save
  rescue Trello::Error => e
    puts "It looks like that's not right. I got an error: #{e}"
  end

  def run
    options.parse!
    commit
  end

  class << self
    def run
      new.run
    end
  end

  private

  def authenticated?
    Trello::Member.find("me")
    true
  rescue Trello::Error => e
    false
  end

  def edit(file)
    editor = ENV["EDITOR"]

    raise "You must set the \$EDITOR environment variable" if editor.nil?

    system(editor, file.path)
  end

  def load_config
    @config = TrelloCommit::Configuration.new(logger)
    config.load
    config
  end

  def trello_color(trello_color)
    case trello_color
    when "black" then :default
    when "blue" then :blue
    when "green" then :green
    when "lime" then :light_green
    when "orange" then :yellow
    when "pink" then :magenta
    when "purple" then :light_magenta
    when "red" then :red
    when "sky" then :light_cyan
    when "yellow" then :light_yellow
    else :default
    end
  end

  def trello_id(trello_url)
    trello_url.match(%r{^https://trello\.com/[cb]/(\w+)})[1]
  end
end
