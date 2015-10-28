class LintInstaller

  def initialize(languages)
    puts "Installing linters...".blue
    @languages = languages
  end

  def run
    install_dependencies
  end

  def php_dependecies
    begin
      `php -v`
      if !File.directory?(File.expand_path("~/phpcs"))
        puts "Installing PHP Codesniffer...".blue
        `git clone https://github.com/squizlabs/PHP_CodeSniffer.git #{File.expand_path("~/phpcs")}`
        # install php codesniffer
      end
    rescue
      puts "PHP not installed. Please install PHP >= 5.1.2 and make sure it is added to your PATH.".red
    end
  end

  def wordpress_dependencies
    # install php codesniffer if not exists
    php_dependecies
    # install wpcs if not exists
    if !File.directory?(File.expand_path("~/wpcs"))
      puts "Installing Wordpress Codesniffer...".blue
      `git clone https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git #{File.expand_path("~/wpcs")}`
      # point php codesniffer to wpcs
      `#{File.expand_path("~/phpcs/scripts/phpcs")} --config-set installed_paths #{File.expand_path("~/wpcs")}`
    end
  end

  def js_dependencies
    begin
      if `npm list -g jshint`.include? "empty"
        puts "Installing jsHint...".blue
        `npm install -g jshint`
        `npm install --save-dev jshint-json`
      end
    rescue
      puts "Node Package Manager not installed. Please install NodeJS and NPM and make sure it is added to your PATH".red
      $logger.warn("#{Time.now}: Dependency Error: Node not installed...")
    end
  end

  def python_dependencies
    begin
      if !`pip freeze`.include?('django') || !`pip freeze`.include?('prospector')
        puts "Installing Django and Prospector...".blue
        `pip install django`
        `pip install prospector`
      end
    rescue
      puts "Python not installed. Please install Python and make sure it is added to your PATH.".red
      $logger.warn("#{Time.now}: Dependency Error: Python not installed...")
    end
  end

  def c_dependencies
    begin
      if !`pip freeze`.include? 'lizard'
        puts "Installing Lizard...".blue
        `pip install lizard`
      end
    rescue
      puts "Python not installed. Please install Python and make sure it is added to your PATH.".red
      $logger.warn("#{Time.now}: Dependency Error: Python not installed...")
    end
  end

  def ruby_dependencies
    puts "Installing metric_fu...".blue
    `gem install metric_fu`
  end

  def cpd_dependencies
    if !File.directory?(File.expand_path("~/pmd"))
      puts "Installing pmd...".green
      `git clone https://github.com/iconnor/pmd.git #{File.expand_path("~/pmd")}`
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
