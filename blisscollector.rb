#!/usr/bin/env ruby
$LOAD_PATH << 'lib'
require 'bootstrap'

# Load configuration File if it exists
if File.exist? 'bliss-config.yml'
  $bliss_config = YAML::load_file('bliss-config.yml')
else
  $bliss_config = {}
end

# Checks for saved argument in config file, otherwise prompts user
def get_or_save_arg(message, env_name)
  if $bliss_config && $bliss_config[env_name]
    puts "Loading #{env_name} from bliss-config.yml..."
  else
    puts message
    arg = gets.chomp
    $bliss_config[env_name] = arg
  end
end

# Global AWS Configuration
def configure_aws(key, secret)
  aws_credentials = Aws::Credentials.new(key, secret)
  Aws.config.update(region: 'us-east-1', credentials: aws_credentials)
end

# The main program loop to accept commands for various tasks
def program_loop
  command = ''
  while command != 'Q'
    puts 'Which command would you like to run? ((C)ollector, (L)int or (S)tats or (Q)uit)'
    command = gets.chomp.upcase
    if command == 'C'
      puts 'Running Collector'
      CollectorTask.new.execute($bliss_config['TOP_LVL_DIR'], $bliss_config['ORG_NAME'], $bliss_config['API_KEY'], $bliss_config['BLISS_HOST'])
    elsif command == 'L'
      puts 'Running Linter'
      LinterTask.new.execute($bliss_config['TOP_LVL_DIR'], $bliss_config['API_KEY'], $bliss_config['BLISS_HOST'])
    elsif command == 'S'
      puts 'Running Stats'
      StatsTask.new.execute($bliss_config['TOP_LVL_DIR'], $bliss_config['API_KEY'], $bliss_config['BLISS_HOST'])
    else
      puts 'Not a valid option. Please choose Collector, Lint, Stats or Quit.' unless command == 'Q'
    end
  end
  puts 'Goodbye'
end

# Initialize state from config file or user input
def init
  puts 'Configuring collector...'
  get_or_save_arg('What\'s your Bliss API Key?', 'API_KEY')
  get_or_save_arg('Which directory are your repositories located in?', 'TOP_LVL_DIR')
  get_or_save_arg('What\'s your AWS Access Key?', 'AWS_ACCESS_KEY_ID')
  get_or_save_arg('What\'s your AWS Access Secret?', 'AWS_SECRET_ACCESS_KEY')
  get_or_save_arg('What is the hostname of your Bliss instance?', 'BLISS_HOST')
  get_or_save_arg('What is the name of your organization in git?', 'ORG_NAME')
  File.open('bliss-config.yml', 'w') { |f| f.write $bliss_config.to_yaml } # Store
  puts 'Collector configured.'
  puts 'Configuring AWS...'
  configure_aws($bliss_config['AWS_ACCESS_KEY_ID'], $bliss_config['AWS_SECRET_ACCESS_KEY'])
  puts 'AWS configured.'
end

init
program_loop
