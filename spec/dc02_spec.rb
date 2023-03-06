control 'DC02-DNS' do
  impact 1.0
  title 'DNS configuration'
  desc 'The DNS configuration should be valid'

  describe host('dc01.demo.local') do
    it { should be_reachable }
    it { should be_resolvable }
    its('ipaddress') { should include '10.10.10.5' }
  end

  describe host('dc02.dev.demo.local') do
    it { should be_reachable }
    it { should be_resolvable }
    its('ipaddress') { should include '10.10.11.5' }
  end
end
