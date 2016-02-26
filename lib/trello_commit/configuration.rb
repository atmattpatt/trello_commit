require "yaml"

class TrelloCommit::Configuration
  attr_reader :logger

  attr_accessor :api_key, :auth_token, :boards, :full_name, :username

  def initialize(logger)
    @logger = logger
  end

  def load
    if File.exist?(configuration_file)
      load_file(configuration_file)
    else
      logger.debug("Configuration file #{configuration_file} does not exist")
    end

    Trello.configure do |config|
      config.developer_public_key = api_key
      config.member_token = auth_token
    end
  end

  def save
    File.open(configuration_file, "w") do |file|
      file.write(to_yaml)
    end
  end

  def to_yaml
    {
      api_key: api_key,
      auth_token: auth_token,
      boards: boards,
      full_name: full_name,
      username: username,
    }.to_yaml
  end

  private

  def configuration_file
    File.join(ENV["HOME"], ".trello_commit.yml")
  end

  def load_file(file)
    configuration = YAML.load_file(configuration_file)
    self.api_key = configuration[:api_key]
    self.auth_token = configuration[:auth_token]
    self.boards = configuration[:boards]
    self.full_name = configuration[:full_name]
    self.username = configuration[:username]
  end
end
