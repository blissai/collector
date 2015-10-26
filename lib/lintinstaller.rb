class LintInstaller

  def initialize(languages)
    puts "Installing linters..."
    @languages = languages
  end

  def run
    install_dependencies
  end

  def php_dependecies
    if !File.directory?(File.expand_path("~/phpcs"))
      puts "Installing PHP Codesniffer..."
      `git clone https://github.com/squizlabs/PHP_CodeSniffer.git ~/phpcs`
      # install php codesniffer
    end
  end

  def wordpress_dependencies
    # install php codesniffer if not exists
    php_dependecies
    # install wpcs if not exists
    if !File.directory?(File.expand_path("~/wpcs"))
      puts "Installing Wordpress Codesniffer..."
      `git clone https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git ~/wpcs`
      # point php codesniffer to wpcs
      `#{File.expand_path("~/phpcs")} --config-set installed_paths #{File.expand_path("~/wpcs")}`
    end
  end

  def js_dependencies
    if `npm list -g jshint`.include? "empty"
      puts "Installing jsHint..."
      `npm install -g jshint`
      `npm install --save-dev jshint-json`
    end
  end

  def python_dependencies
    if !`pip freeze`.include?('django') || !`pip freeze`.include?('prospector')
      puts "Installing Django and Prospector..."
      `pip install django`
      `pip install prospector`
    end
  end

  def c_dependencies
    if !`pip freeze`.include? 'lizard'
      puts "Installing Lizard..."
      `pip install lizard`
    end
  end

  def ruby_dependencies
    puts "Installing metric_fu..."
    `gem install metric_fu`
  end

  def cpd_dependencies
    if !File.directory?(File.expand_path("~/pmd"))
      puts "Installing pmd..."
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
