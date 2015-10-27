# A class to handle config and instantiation of tasks
class BlissRunner
  def initialize
    # Load configuration File if it exists
    if File.exist? "#{File.expand_path(File.dirname($0))}/bliss-config.yml"
      @config = YAML::load_file("#{File.expand_path(File.dirname($0))}/bliss-config.yml")
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
    File.open("#{File.expand_path(File.dirname($0))}/bliss-config.yml", 'w') { |f| f.write @config.to_yaml } # Store
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
      schedule_job
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
  def schedule_job
    puts "How often would you like to automatically run Bliss Collector?".blue
    puts " (1) Every Day\n (2) Every Hour\n (3) Every 10 Minutes"
    minutes = gets.chomp
    if ![1, 2, 3].include? minutes.to_i
      puts 'This is not a option. Please choose 1, 2, 3 or 4.'
    else
      if Gem.win_platform?

      else
        cron_job(option)
      end
    end
  end

  def task_sched
    # Choose frequency
    if option == 1
      freq = "/SC DAILY"
    elsif option == 2
      freq = "/SC HOURLY"
    else
      freq = "/SC MINUTE /MO 10"
    end

    # Get current path
    cwd = `@powershell $pwd.path`.gsub(/\n/, "")
    task_cmd = "cd  #{cwd}\nruby blissauto.rb"

    # create batch file
    file_name = "#{cwd}\\blisstask.bat"
    File.open(file_name, 'w') { |file| file.write(task_cmd) }

    # schedule task with schtasks
    cmd = "schtasks /Create #{freq} /TN BlissCollector /TR #{file_name}"
    `#{cmd}`
  end

  def cron_job(option)
    # Create a shell script that runs blissauto
    cwd = `pwd`.gsub(/\n/, "")
    cron_command = "cd  #{cwd}; ruby blissauto.rb"
    file_name = "#{cwd}/blisstask.sh"
    File.open(file_name, 'w') { |file| file.write(cron_command) }
    # Format cron entry
    if option == 1
      cron_entry = "0 23 * * * #{file_name}"
    elsif option == 2
      cron_entry = "0 * * * * #{file_name}"
    else
      cron_entry = "*/10 * * * * #{file_name}"
    end

    # Create a file for Cron
    File.open('/etc/cron.d/bliss', 'w') { |file| file.write(cron_entry) }
    puts 'Job scheduled successfully.'
  end

  private
  # Checks for saved argument in config file, otherwise prompts user
  def get_or_save_arg(message, env_name)
    if @config && @config[env_name]
      puts "Loading #{env_name} from bliss-config.yml...".green
    else
      puts message.blue
      arg = gets.chomp
      @config[env_name] = arg
    end
  end
end
