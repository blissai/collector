# A class to handle config and instantiation of tasks
class BlissRunner
  def initialize
    # Load configuration File if it exists
    if File.exist? 'bliss-config.yml'
      @config = YAML::load_file('bliss-config.yml')
    else
      @config = {}
    end
    get_config
  end

  # Global AWS Configuration
  def configure_aws(key, secret)
    # do this once, and all s3 clients will now accept `:requester_pays` to all operations
    Aws::S3::Client.add_plugin(RequesterPays)
    aws_credentials = Aws::Credentials.new(key, secret)
    # Aws.config.update(region: 'us-east-1', credentials: aws_credentials)
    $aws_client = Aws::S3::Client.new(region: 'us-east-1', credentials: aws_credentials)
  end

  # Initialize state from config file or user input
  def get_config
    puts 'Configuring collector...'
    get_or_save_arg('What\'s your Bliss API Key?', 'API_KEY')
    get_or_save_arg('Which directory are your repositories located in?', 'TOP_LVL_DIR')
    get_or_save_arg('What\'s your AWS Access Key?', 'AWS_ACCESS_KEY_ID')
    get_or_save_arg('What\'s your AWS Access Secret?', 'AWS_SECRET_ACCESS_KEY')
    get_or_save_arg('What is the hostname of your Bliss instance?', 'BLISS_HOST')
    get_or_save_arg('What is the name of your organization in git?', 'ORG_NAME')
    File.open('bliss-config.yml', 'w') { |f| f.write @config.to_yaml } # Store
    puts 'Collector configured.'
    puts 'Configuring AWS...'
    configure_aws(@config['AWS_ACCESS_KEY_ID'], @config['AWS_SECRET_ACCESS_KEY'])
    puts 'AWS configured.'
  end

  def choose_command
    puts 'Which command would you like to run? ((C)ollector, (L)int or (S)tats or (Q)uit)'
    command = gets.chomp.upcase
    if command == 'C'
      puts 'Running Collector'
      CollectorTask.new.execute(@config['TOP_LVL_DIR'], @config['ORG_NAME'], @config['API_KEY'], @config['BLISS_HOST'])
    elsif command == 'L'
      puts 'Running Linter'
      LinterTask.new.execute(@config['TOP_LVL_DIR'], @config['API_KEY'], @config['BLISS_HOST'])
    elsif command == 'S'
      puts 'Running Stats'
      StatsTask.new.execute(@config['TOP_LVL_DIR'], @config['API_KEY'], @config['BLISS_HOST'])
    else
      puts 'Not a valid option. Please choose Collector, Lint, Stats or Quit.' unless command == 'Q'
    end
    choose_command unless command.eql? 'Q'
  end

  private
  # Checks for saved argument in config file, otherwise prompts user
  def get_or_save_arg(message, env_name)
    if @config && @config[env_name]
      puts "Loading #{env_name} from bliss-config.yml..."
    else
      puts message
      arg = gets.chomp
      @config[env_name] = arg
    end
  end
end
