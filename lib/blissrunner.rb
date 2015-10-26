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
    DependencyInstaller.new(@config["TOP_LVL_DIR"]).run
  end

  # Global AWS Configuration
  def configure_aws(key, secret)
    # If Windows, use AWS's bundled ssl cert
    if Gem.win_platform?
      Aws.use_bundled_cert!
    end
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
    puts 'Which command would you like to run? ((C)ollector, (S)tats, (L)inter or (Q)uit) or type "T" to setup scheduling.'
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
    elsif command == 'T'
      puts 'How often, in minutes, would you like to automatically run Bliss Collector?'
      minutes = gets.chomp
      if !is_i?(minutes)
        puts 'This is not a valid integer. Please try again with a positive integer.'
      else
        schedule_job(minutes)
      end
    else
      puts 'Not a valid option. Please choose Collector, Lint, Stats or Quit.' unless command == 'Q'
    end
    choose_command unless command.eql? 'Q'
  end

  # A function that automates the above three functions for a scheduled job
  def automate
    puts 'Running Collector'
    CollectorTask.new.execute(@config['TOP_LVL_DIR'], @config['ORG_NAME'], @config['API_KEY'], @config['BLISS_HOST'])
    puts 'Running Stats'
    StatsTask.new.execute(@config['TOP_LVL_DIR'], @config['API_KEY'], @config['BLISS_HOST'])
    puts 'Running Linter'
    LinterTask.new.execute(@config['TOP_LVL_DIR'], @config['API_KEY'], @config['BLISS_HOST'])
  end

  # A function to set up a scheduled job to run 'automate' every x number of minutes
  def schedule_job(every_x_minutes)
    if Gem.win_platform?

    else
      # Create a shell script that runs blissauto
      cwd = `pwd`.gsub(/\n/, "")
      cron_command = "cd  #{cwd}; ruby blissauto.rb"
      file_name = cwd + "/cron_script.sh"
      File.open(file_name, 'w') {|file|
        file.write(cron_command)
      }

      # Create a file for Cron
      cron_entry = "*/#{every_x_minutes} * * * * #{cwd}/cron_script.sh"
      File.open('/etc/cron.d/bliss', 'w') {|file|
        file.write(cron_entry)
      }
      puts 'Job scheduled successfully.'
    end
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

  def is_i? string_to_check
    !!(string_to_check =~ /\A[-+]?[0-9]+\z/)
  end
end
