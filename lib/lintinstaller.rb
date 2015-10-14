class LintInstaller
  def initialize(linters, git_dir)
    @git_dir = git_dir
    @linters = linters
  end

  # Install required linter dependencies
  def install_dependencies
    @linters.each do |linter|
      linter_name = linter['name']
      install_command = linter['install_command']
      puts "Installing linter '#{linter_name}'..."
      `cd #{@git_dir};#{install_command} > /dev/null`
    end
  end
end
