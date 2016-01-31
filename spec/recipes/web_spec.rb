require_relative '../spec_helper'

describe 'owncloud::web' do
  subject { ChefSpec::Runner.new.converge(described_recipe) }
  it { should install_package('nginx') }
  php_packages = %w(php5 php5-fpm php5-gd php5-json php5-mysql php5-curl php5-intl php5-mcrypt php5-imagick)
  php_packages.each do |pkg|
    it { should install_package(pkg) }
  end
end
