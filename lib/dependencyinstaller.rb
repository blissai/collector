class DependencyInstaller
  include Common

  def initialize(top_lvl_dir)
    @top_lvl_dir = top_lvl_dir
  end

  def run
    puts "Installing dependencies..."
    dirs_list = get_directory_list(@top_lvl_dir)
    LintInstaller.new(dirs_list)
  end
end
