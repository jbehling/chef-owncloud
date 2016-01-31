require 'spec_helper'

describe package('mariadb-server') do
  it { should be_installed }
end

describe package('mariadb-client') do
  it { should be_installed }
end

describe service('mysql') do
  it { should be_enabled }
  it { should be_running }
end

describe 'no root login w/o password' do
  describe command("mysql -u root -e 'select 1'") do
    its(:exit_status) { should eq 1 }
  end
end

describe 'bind to 0.0.0.0' do
  describe file('/etc/mysql/my.cnf') do
    its(:content) { should match %r{^bind-address\s+=\s+0\.0\.0\.0} }
  end
end

describe port(3306) do
  it { should be_listening }
end
