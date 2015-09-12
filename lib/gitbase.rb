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
      puts err
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
      if File.exist?(file_name)
        `#{get_cmd(cmd)}`
      end
    end
    puts "Removed open source files"
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
    '--yaml --quiet --skip-uniqueness --progress-rate=0'
  end

  def cloc_command
    if Gem.win_platform?
      "bin\\cloc"
    else
      "bin/cloc"
    end
  end
end
