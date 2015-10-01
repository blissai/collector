require 'spec_helper'

RSpec.describe "Command line files" do
  it "collector runs ok" do
    ret = `./collector.rb --help`
    expect(ret).to match('Available options')
  end
  
  it "run collector over an empty director" do
    Dir.mktmpdir do |git_dir| 
      collector = Collector.new
      collector.git_init(git_dir)
      
    end
  end
  
end