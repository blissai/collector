require 'rspec/matchers' # req by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'
Dir.glob("lib/sourcescrubber.rb").each(&method(:load))

RSpec.describe "Test Source Scrubber" do
  it "Source Scrubber removes code fragment from cpd" do
    @scrubber = SourceScrubber.new
    @xml = File.read("spec/fixtures/cpd_php.xml")
    @xml_scrubbed = Nokogiri::XML(File.read("spec/fixtures/cpd_php_scrubbed.xml"))
    scrubbed = Nokogiri::XML(@scrubber.scrub(@xml))
    expect(scrubbed).to be_equivalent_to(@xml_scrubbed)
  end
end
