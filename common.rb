# Set of common functions used by all commands
module Common
  def get_cmd(cmd)
    if Gem.win_platform?
      @tmpbatchfile = Tempfile.new(['batch', '.ps1'])
      @tmpbatchfile.write(cmd.gsub(';', "\r\n"))
      @tmpbatchfile.close
      "powershell #{@tmpbatchfile.path}"
    else
      "(#{cmd})"
    end
  end

  def get_directory_list(top_dir_name)
    top_dir_with_star = File.join(top_dir_name.to_s, '*')
    Dir.glob(top_dir_with_star).select { |f| File.directory? f }
  end
end
