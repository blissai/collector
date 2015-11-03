module CliTasks
  def auto?
    (@args.size.eql? 1) && (@args[0].eql? "auto")
  end

  def scheduler?
    (@args.size.eql? 1) && (@args[0].eql? "schedule") && Gem.win_platform?
  end

  def loop?
    @args.size.eql? 0
  end
end
