require_relative 'copyright'
module Gitbase
  def checkout_commit(git_dir, commit)
    throw 'Git directory not found' unless File.exist?(git_dir)
    # cmd = get_cmd("cd #{git_dir};git reset --hard HEAD")
    cmd = "cd #{git_dir} && git reset --hard HEAD"
    `#{cmd}`
    # cmd = get_cmd("cd #{git_dir};git clean -f -d")
    cmd = "cd #{git_dir} && git clean -f -d"
    `#{cmd}`
    # co_cmd = get_cmd("cd #{git_dir};git checkout #{commit}")
    co_cmd = "cd #{git_dir} && git checkout #{commit}"
    stdin, stdout, stderr = Open3.popen3(co_cmd)
    @ref = nil
    while (err = stderr.gets) do
      puts err unless err.include? "Already on 'master'"
      @ref = err
      if err =~ /Your local changes to the following files would be overwritten by checkout/
        `#{remove_command} #{git_dir}/*`
        # cmd = get_cmd("cd #{git_dir};git checkout #{co_cmd}")
        cmd = "cd #{git_dir} && git checkout #{commit}"
        `#{cmd}`
        # cmd = get_cmd("cd #{git_dir};git reset --hard HEAD")
        cmd = "cd #{git_dir} && git reset --hard HEAD"
        `#{cmd}`
        # cmd = get_cmd("cd #{git_dir};git clean -fdx")
        cmd = "cd #{git_dir} && git clean -fdx"
        `#{cmd}`
        @ref = `#{co_cmd}`
        break
      end
    end
  end

  def remove_open_source_files(git_dir)
    # Remove open source files
    puts "\tRemoving open source files...".blue
    open_source_lines = nil
    if Gem.win_platform?
      egrep_cmd = "C:/Program Files (x86)/GnuWin32/bin/egrep.exe"
      if File.exist?(egrep_cmd)
        open_source_lines = `"#{egrep_cmd}" -i "free software|Hamano|jQuery|BSD|GPL|GNU|MIT|Apache" #{git_dir}/* -R`.encode('UTF-8', :invalid => :replace).split("\n").keep_if do |line|
          line =~ /License|Copyright/i
        end
      else
        open_source_lines = `findstr /R /S "Hamano jQuery BSD GPL GNU MIT Apache" #{git_dir}/*`.encode('UTF-8', :invalid => :replace).split("\n").keep_if do |line|
          line =~ /License|Copyright/i
        end
      end
    else
      open_source_lines = `egrep -i "free software|Hamano|jQuery|BSD|GPL|GNU|MIT|Apache" #{git_dir}/* -R`.encode('UTF-8', :invalid => :replace).split("\n").keep_if do |line|
        line =~ /License|Copyright/i
      end
    end
    todo = []
    temp_start = Gem.win_platform? ? "c:/temp/codecop" : "/tmp/codecop"
    open_source_lines.each do |line|
      line = line.gsub("\\", "/")
      if match = /^#{temp_start}([^:]+?)\/[^\/:\s]*license|licence|readme|(.txt|.md):/i.match(line)
        #puts "license file found: #{line}"
        file_name = "#{temp_start}#{match[1]}"
        todo << ["#{remove_command} #{file_name}/*", file_name] if match[1]
      elsif match = /^#{temp_start}([^:]+?)\/[^\/]*manifest.xml:/i.match(line)
        #puts "manifest file found: #{line}"
        file_name = "#{temp_start}#{match[1]}"
        todo << ["#{remove_command} #{file_name}/*", file_name] if match[1]
      elsif match = /^#{temp_start}([^:]+?):/i.match(line)
        file_name = "#{temp_start}#{match[1]}"
        todo << ["rm #{file_name}", file_name] if match[1]
      end
      if true
      end
    end
    if File.exist?(File.join(git_dir,'NuGet.config')) && Dir.exist?(File.join(git_dir,'packages'))
      file_name = File.join(git_dir, 'packages')
      todo << ["#{remove_command} #{file_name}", file_name]
    end
    todo.uniq!
    todo.each do |cmd, file_name|
      #puts cmd
      puts "Removing #{file_name}"
      if File.exist?(file_name)
        # `#{get_cmd(cmd)}`
        `#{cmd}`
      end
    end
  end

  def find_copyright(git_dir, is_demo=false)
    puts "Finding copyrights: #{git_dir}".blue
    owners = []
    egrep_cmd = Gem.win_platform? ? "\"C:/Program Files (x86)/GnuWin32/bin/egrep.exe\"" : 'egrep'
    copyright_lines = `#{egrep_cmd} -i "copyright|\(c\)|\&copy\;" #{git_dir}/* -R`
    copyright_lines.encode('UTF-8', :invalid => :replace).split("\n").each do |line|
      owner, file = Copyright.find_owner(line)
      next if is_demo and (file =~ /fixture/)
      owners << owner
    end
    owners = owners.compact.uniq
    puts "Found #{owners.count} owners under: #{git_dir}".green
    owners
  end

  def cloc_options
    "--yaml --quiet --skip-uniqueness --progress-rate 0"
  end

  def cloc_command
    if Gem.win_platform?
      "bin\\cloc"
    else
      "bin/cloc"
    end
  end

  def remove_command
    if Gem.win_platform?
      "rm -r -Force"
    else
      "rm -rf"
    end
  end

  def sense_project_type(git_dir)
    # language = ''
    languages = []
    if Dir.entries(git_dir).find { |e| /\.sln$/ =~ e }
      # language = ".NET"
      languages.push(".NET")
    elsif !Dir.glob(File.join(git_dir, "**/*.rb")).empty?
      languages.push("ruby")
      if File.exist?(File.join(git_dir,"config","boot.rb"))
        # language = 'rails'
        languages.push("rails")
      end
    elsif File.exist?(File.join(git_dir,"Podfile")) || !Dir.glob(File.join(git_dir, "**/*.xcodeproj")).empty?
      # language = 'ios'
      languages.push("ios")
      languages.push("Objective-C")
    elsif File.exist?(File.join(git_dir, "Godeps"))
      # language = 'go'
      languages.push("go")
    elsif File.directory?(File.join(git_dir, "wp-content"))
      # language = 'wordpress'
      languages.push("wordpress")
    elsif !Dir.glob(File.join(git_dir, "**/*.php")).empty?
      if File.exist?(File.join(git_dir, "server.php")) && file_contains("#{git_dir}/server.php", /package[ ]+Laravel/)
        languages.push("Laravel")
      elsif File.exist?(File.join(git_dir, "index.php")) && file_contains("#{git_dir}/index.php", "package Elgg")
        languages.push("elgg")
      else
        languages.push("php")
      end
    elsif !Dir.glob(File.join(git_dir, "*.py")).empty?
      if File.exists?(File.join(git_dir, "manage.py"))
        if file_contains("#{git_dir}/manage.py", "django")
          # language = 'django'
          languages.push("django")
        end
      end
      # language = 'Python'
      languages.push("Python")
    elsif File.exist?(File.join(git_dir, "package.json"))
      # language = 'nodejs'
      languages.push("nodejs")
    elsif !Dir.glob(File.join(git_dir, "**/*.java")).empty? || File.exist?(File.join(git_dir, "build.gradle"))
      # language = 'Java'
      languages.push("Java")
    elsif !Dir.glob(File.join(git_dir, "**/*.pm")).empty? || !Dir.glob(File.join(git_dir, "**/*.pl")).empty?
      languages.push("Perl")
    end
    languages
  end

  def file_contains(file_path, search_string)
    if search_string.is_a? Regexp
      File.read(file_path) =~ search_string
    else
      File.read(file_path).include?(search_string)
    end
  end

  def get_test_dirs(git_dir)
    cloc_test_dirs = nil
    if File.exist?(File.join(git_dir,"config","boot.rb"))
      dirs = []
      ['test', 'spec'].each do |test_dir|
        if File.directory?(File.join(git_dir,test_dir))
          dirs << File.join(git_dir,test_dir)
        end
      end
      cloc_test_dirs = dirs.join(" ") if dirs.present?
    elsif File.exist?(File.join(git_dir,"Podfile"))
      dirs = []
      ['test', 'KIFTests'].each do |test_dir|
        if File.directory?(File.join(git_dir, test_dir))
          dirs << File.join(git_dir, test_dir)
        end
      end
      cloc_test_dirs = dirs.join(" ") if dirs.present?
    elsif File.exist?(File.join(git_dir, "Godeps"))
      cloc_test_dirs = "#{git_dir} --match-f=_test"
    elsif File.directory?(File.join(git_dir, "wp-content"))
      cloc_test_dirs = "#{git_dir} --match-f=Test.php"
    elsif File.exist?(File.join(git_dir, "index.php"))
      cloc_test_dirs = "#{git_dir} --match-f=Test.php"
    elsif File.exist?(File.join(git_dir, "server.php"))
      if file_contains("#{git_dir}/server.php", /package[ ]+Laravel/)
        cloc_test_dirs = "#{git_dir} --match-f=Test.php"
      end
      elsif File.exist?(File.join(git_dir, "codeception.yml"))
        dirs = []
        ['tests'].each do |test_dir|
          if File.directory?(File.join(git_dir, test_dir))
            dirs << File.join(git_dir, test_dir)
          end
        end
        cloc_test_dirs = dirs.join(" ") if dirs.present?
    elsif File.exist?(File.join(git_dir, "manage.py"))
      if file_contains("#{git_dir}/manage.py", "django")
        cloc_test_dirs = "#{git_dir} --match-f='test[\s]*.py'"
      end
    end
    if cloc_test_dirs.nil?
      # Go with some pretty wide defaults for finding tests
      dirs = []
      ['test', 'spec'].each do |test_dir|
        if File.directory?("#{git_dir}/#{test_dir}")
          dirs << "#{git_dir}/#{test_dir}"
        end
      end
      cloc_test_dirs = dirs.join(" ") if dirs.present?
    end
    cloc_test_dirs
  end
end
