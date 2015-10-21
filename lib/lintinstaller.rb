class LintInstaller
  include Gitbase

  def initialize(git_dirs)
    puts "Installing linters..."
    @git_dirs = git_dirs
    @languages = determine_languages(git_dirs)
    install_dependencies
  end

  #Determine all languages/frameworks
  def determine_languages(git_dirs)
    langs = []
    git_dirs.each do |git_dir|
      project_types = sense_project_type(git_dir)
      langs = (langs << project_types).flatten!
    end
    langs
  end

  def php_dependecies
    puts "Installing PHP Codesniffer..."
    # install php codesniffer
    `composer global require "squizlabs/php_codesniffer=*"`
  end

  def wordpress_dependencies
    puts "Installing Wordpress Codesniffer..."
    # install wordpress codesniffer standards
    if Gem.win_platform?
    else
      # install php codesniffer if not exists
      `if [[ ! -e phpcs ]]; then composer global require "squizlabs/php_codesniffer=*"; fi;`
      # install wpcs if not exists
      `if [[ ! -e ~/wpcs ]]; then git clone https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git ~/wpcs; fi`
      # point php codesniffer to wpcs
      composer_home = `composer config --global home`.gsub(/\n/, "")
      `#{composer_home}/vendor/bin/phpcs --config-set installed_paths ~/wpcs`
    end
  end

  def js_dependencies
    puts "Installing jsHint..."
    `npm install -g jshint`
    `npm install --save-dev jshint-json`
  end

  def python_dependencies
    puts "Installing Django and Prospector..."
    `pip install django`
    `pip install prospector`
  end

  def c_dependencies
    puts "Installing Lizard..."
    `pip install lizard`
  end

  def ruby_dependencies
    puts "Installing metric_fu..."
    `gem install metric_fu`
  end

  def cpd_dependencies
    puts "Installing pmd..."
    if Gem.win_platform?
    else
      `if [[ ! -e ~/pmd ]]; then git clone https://github.com/iconnor/pmd.git ~/pmd; fi`
    end
  end

  def install_dependencies
    if @languages.any? { |lang| ["JavaScript", "nodejs", "node"].include? lang }
      js_dependencies
    end
    if @languages.any? { |lang| ["PHP","Laravel","php","elgg"].include? lang }
      php_dependencies
    end
    if @languages.any? { |lang| ["Objective-C", "Objective-C++"].include? lang }
      c_dependencies
    end
    if @languages.any? { |lang| ["wordpress"].include? lang }
      wordpress_dependencies
    end
    if @languages.any? { |lang| ["Python", "django"].include? lang }
      python_dependencies
    end
    if @languages.any? { |lang| ["rails","ruby"].include? lang }
      ruby_dependencies
    end
    cpd_dependencies
  end
end
