require 'copyright'
module Gitbase

  def checkout_commit(git_dir, commit)
    throw 'Git directory not found' unless File.exist?(git_dir)
    cmd = get_cmd("cd #{git_dir};git reset --hard HEAD")
    `#{cmd}`
    cmd = get_cmd("cd #{git_dir};git clean -f -d")
    `#{cmd}`
    co_cmd = get_cmd("cd #{git_dir};git checkout #{commit}")
    stdin, stdout, stderr = Open3.popen3(co_cmd)
    @ref = nil
    while (err = stderr.gets) do
      puts err unless err.include? "Already on 'master'"
      @ref = err
      if err =~ /Your local changes to the following files would be overwritten by checkout/
        `#{remove_command} #{git_dir}/*`
        cmd = get_cmd("cd #{git_dir};git checkout #{co_cmd}")
        `#{cmd}`
        cmd = get_cmd("cd #{git_dir};git reset --hard HEAD")
        `#{cmd}`
        cmd = get_cmd("cd #{git_dir};git clean -fdx")
        `#{cmd}`
        @ref = `#{co_cmd}`
        break
      end
    end
  end

  def remove_open_source_files(git_dir)
    # Remove open source files
    puts "\tRemoving open source files..."
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
    end
    todo.uniq!
    todo.each do |cmd, file_name|
      #puts cmd
      puts "Removing #{file_name}"
      if File.exist?(file_name)
        `#{get_cmd(cmd)}`
      end
    end
  end

  def find_copyright(git_dir, is_demo=false)
    puts "Finding copyrights: #{git_dir}"
    owners = []
    egrep_cmd = Gem.win_platform? ? "\"C:/Program Files (x86)/GnuWin32/bin/egrep.exe\"" : 'egrep'
    copyright_lines = `#{egrep_cmd} -i "copyright|\(c\)|\&copy\;" #{git_dir}/* -R`
    copyright_lines.encode('UTF-8', :invalid => :replace).split("\n").each do |line|
      owner, file = Copyright.find_owner(line)
      next if is_demo and (file =~ /fixture/)
      owners << owner
    end
    owners = owners.compact.uniq
    puts "Found #{owners.count} owners under: #{git_dir}"
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

  def sense_project_type(git_dir)
    # language = ''
    languages = []
    if Dir.entries(git_dir).find { |e| /\.sln$/ =~ e }
      # language = ".NET"
      languages.push(".NET")
    end
    if File.exist?(File.join(git_dir,"config","boot.rb"))
      # language = 'rails'
      languages.push("rails")
      @cloc_options = "--exclude-dir public,vendor,bin,coverage"
      dirs = []
      ['test', 'spec'].each do |test_dir|
        if File.directory?(File.join(git_dir,test_dir))
          dirs << File.join(git_dir,test_dir)
        end
      end
      @cloc_test_dirs = dirs.join(" ") if dirs.present?
    end
    if File.exist?(File.join(git_dir,"Podfile"))
      # language = 'ios'
      languages.push("ios")
      dirs = []
      ['test', 'KIFTests'].each do |test_dir|
        if File.directory?(File.join(git_dir, test_dir))
          dirs << File.join(git_dir, test_dir)
        end
      end
      @cloc_test_dirs = dirs.join(" ") if dirs.present?
    end
    if File.exist?(File.join(git_dir, "build.gradle"))
      # language = 'java'
      languages.push("java")
    end
    if File.exist?(File.join(git_dir, "Godeps"))
      # language = 'go'
      languages.push("go")
      @cloc_test_dirs = "#{git_dir} --match-f=_test"
    end
    if File.directory?(File.join(git_dir, "wp-content"))
      # language = 'wordpress'
      languages.push("wordpress")
      if `find #{git_dir}/wp-content -name 'sass'`.present? or `find #{git_dir}/wp-content -name 'less'`.present?
        @cloc_options = "#{@cloc_options} --exclude-ext=css"
      end
      @cloc_test_dirs = "#{git_dir} --match-f=Test.php"
    end
    if File.exist?(File.join(git_dir, "index.php"))
      if `grep 'package Elgg' #{git_dir}/index.php`.present?
        # language = 'elgg'
        languages.push("elgg")
        source = File.open(File.join(git_dir, "version.php"), "r").read
        if version_match =  /\$release = '([0-9.]+)'/.match(source)
          @platform_cloc = PlatformCloc.where(name: 'elgg', version: version_match[1]).first
        end
      end
      @cloc_test_dirs = "#{git_dir} --match-f=Test.php"
    end
    if File.exist?(File.join(git_dir, "server.php"))
      if `egrep 'package[ ]+Laravel' #{git_dir}/server.php`.present?
        # language = 'Laravel'
        languages.push("Laravel")
        @cloc_test_dirs = "#{git_dir} --match-f=Test.php"
      end
      elsif File.exist?(File.join(git_dir, "codeception.yml"))
        # language = 'php'
        languages.push("php")
        dirs = []
        ['tests'].each do |test_dir|
          if File.directory?(File.join(git_dir, test_dir))
            dirs << File.join(git_dir, test_dir)
          end
        end
        @cloc_test_dirs = dirs.join(" ") if dirs.present?
    end
    if File.exist?(File.join(git_dir, "manage.py"))
      if `grep 'django' #{git_dir}/manage.py`.present?
        # language = 'django'
        languages.push("django")
        @cloc_test_dirs = "#{git_dir} --match-f='test[\s]*.py'"
        @cloc_options = "--exclude-dir vendor"
      else
        # language = 'Python'
        languages.push("Python")
      end
    end
    if File.exist?(File.join(git_dir, "package.json"))
      # language = 'nodejs'
      languages.push("nodejs")
      @cloc_options = "--exclude-dir vendor"
      @cloc_options = "--exclude-dir vendor"
    end
    if `find #{git_dir} -iregex '.*\\(java\\)'`.present?
      # language = 'Java'
      languages.push("Java")
    end
    if languages.empty?
      # Go with some pretty wide defaults for finding tests
      dirs = []
      ['test', 'spec'].each do |test_dir|
        if File.directory?("#{git_dir}/#{test_dir}")
          dirs << "#{git_dir}/#{test_dir}"
        end
      end
      @cloc_test_dirs = dirs.join(" ") if dirs.present?
    end
    languages
  end
end
