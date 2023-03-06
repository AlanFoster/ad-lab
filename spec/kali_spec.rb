control 'Kali-wordlists' do
  impact 1.0
  title 'Wordlists configuration'
  desc 'The wordlists should be present'

  [
    '/usr/share/wordlists/rockyou.txt'
  ].each do |name|
    describe file(name) do
      it { should be_file }
    end
  end
end

control 'Kali-qterminal' do
  impact 1.0
  title 'qterminal configuration'
  desc 'The qterminal configuration should be valid'

  describe file('/home/vagrant/.config/qterminal.org/qterminal.ini') do
    it { should be_file }
    its('content') { should include 'Previous%20Tab=Meta+Shift+[' }
    its('content') { should include 'Next%20Tab=Meta+Shift+]' }
  end
end

control 'Kali-Packages' do
  impact 1.0
  title 'Packages configuration'
  desc 'The Packages configuration should be valid'

  [
    'bloodhound',
    'code-oss',
    'metasploit-framework'
  ].each do |name|
    describe package(name) do
      it { should be_installed }
    end
  end
end

control 'Kali-DNS' do
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
