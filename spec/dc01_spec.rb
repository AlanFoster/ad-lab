control 'DC01-Users' do
  impact 1.0
  title 'User configuration'
  desc 'The user configuration should be valid'

  describe user("demo.local\\web_admin") do
    it { should exist }
    its("groups") { should eq ["Domain Users", "Administrators"] }
    its('maxdays') { should eq 0 }
  end
end

control 'DC01-RBCD-Vulnerablility' do
  impact 1.0
  title 'RBCD Vulnerability'
  desc 'The user should be vulnerable to RBCD attacks'

  sandy_access_control = %q[ (Get-ACL "AD:$(Get-ADComputer 'DC01')").Access | Where-Object { $_.IdentityReference -Match 'sandy' } ]

  describe user("demo.local\\sandy") do
    it { should exist }
    its("groups") { should eq ["Domain Users"] }
    its('maxdays') { should eq 0 }
  end

  describe powershell(sandy_access_control) do
    its('stdout') { should include 'ActiveDirectoryRights : GenericWrite' }
  end
end

control 'DC01-PasswordExpiration' do
  impact 1.0
  title 'User password expiration configuration'
  desc 'The user password expiration configuration should be valid'

  describe users.where { maxdays != 0 }.entries do
    its('length') { should eq 0 }
  end
end

control 'DC01-DNS' do
  impact 1.0
  title 'DNS configuration'
  desc 'The DNS configuration should be valid'

  describe host('dc01.demo.local') do
    it { should be_reachable }
    it { should be_resolvable }
    its('ipaddress') { should include '10.10.10.5' }
  end

  describe host('dc02.dev.demo.local') do
    its('ipaddress') { should be_nil }
  end
end
