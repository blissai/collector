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

  def save_bliss_file(top_dir_name, data)
    File.open("#{top_dir_name}/.bliss.json", 'w') do |f|
      f.write(data.to_json)
    end
  end

  def read_bliss_file(top_dir_name)
    JSON.parse(File.open("#{top_dir_name}/.bliss.json", 'r').read)
  end
end
