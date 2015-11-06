class SourceScrubber
  def scrub(report)
    # CPD
    report.gsub(/<codefragment>.*<\/codefragment>/, "")
  end
end
