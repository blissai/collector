class PackageInstaller
  def initialize
    if Gem.win_platform?
      @platform = "Win"
    else
      @platform = "Unix"
    end
  end

end
