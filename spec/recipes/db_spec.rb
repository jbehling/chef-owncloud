require_relative '../spec_helper'

describe 'owncloud::db' do
  subject { ChefSpec::Runner.new.converge(described_recipe) }
  before do
    stub_command("mysql -u root -e 'select 1'").and_return(true)
  end
  it { should install_package('mariadb-server') }
  it { should install_package('mariadb-client') }
  it { should enable_service('mysql') }
  it { should start_service('mysql') }
  it { should run_bash('secure mysql installation') }
  it { should render_file('/etc/mysql/my.cnf').with_content(/^bind-address\s+=\s+0\.0\.0\.0/) }
end
