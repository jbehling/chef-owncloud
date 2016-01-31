require 'spec_helper'

describe package('nginx') do
  it { should be_installed }
end

describe 'PHP and required libraries should be installed' do
  php_packages = %w(php5 php5-fpm php5-gd php5-json php5-mysql php5-curl php5-intl php5-mcrypt php5-imagick)
  php_packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end

describe service('nginx') do
  it { should be_running }
  it { should be_enabled }
end
describe port('80') do
  it { should be_listening }
end

describe 'owncloud directory' do
  describe file('/var/www/html/owncloud') do
    it { should be_directory }
    it { should be_owned_by 'www-data' }
  end
end

describe service('php5-fpm') do
  it { should be_running }
end

fpm_process_cmd = 'ps -a -eux |grep php'
describe 'php-fpm should have a master process' do
  describe command(fpm_process_cmd) do
    its(:stdout) { should match /master/ }
    its(:exit_status) { should eq 0 }
  end
end

describe 'php-fpm should have at least 1 pool process' do
  describe command(fpm_process_cmd) do
    its(:stdout) { should match /pool/ }
    its(:exit_status) { should eq 0 }
  end
end

describe port('80') do
  it { should be_listening }
end

describe port('443') do
  it { should be_listening }
end

ssl_cmd = 'curl -k https://localhost/'
redirect_cmd = 'curl http://localhost/|grep 301'
occ_status_cmd = 'cd /var/www/html/owncloud; sudo -u www-data php occ status'
describe 'final HTTP smoke tests' do
  before do
    `apt-get install -y curl`
  end
  describe 'http should redirect to https' do
    describe command(redirect_cmd) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /Moved/ }
    end
  end
  describe 'https should be login page' do
    describe command(ssl_cmd) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /login/ }
      its(:stdout) { should_not match /create/ }
    end
  end
  describe 'occ tool should report installed' do
    describe command(occ_status_cmd) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /installed:\s+true/ }
    end
  end
end
