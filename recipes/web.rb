# Install NGINX
package 'nginx'

service 'nginx' do
  action [:enable, :start]
end

# Install PHP and required libs
php_packages = %w(php5 php5-fpm php5-gd php5-json php5-mysql php5-curl php5-intl php5-mcrypt php5-imagick)

php_packages.each do |pkg|
  package pkg
end

# required for archive
package 'bzip2'

remote_file '/tmp/owncloud.tar.bz2' do
  not_if 'stat /var/www/html/owncloud/index.php'
  source node['owncloud']['web']['download_url']
  action :create
  notifies :run, 'execute[unzip archive]', :immediately
end

execute 'unzip archive' do
  not_if 'stat /var/www/html/owncloud/index.php'
  cwd '/var/www/html'
  command 'tar xvjf /tmp/owncloud.tar.bz2'
  notifies :run, 'execute[fix owncloud permissions]', :immediately
end

execute 'cleanup archive' do
  only_if 'stat /tmp/owncloud.tar.bz2'
  command 'rm /tmp/owncloud.tar.bz2'
end

execute 'fix owncloud permissions' do
  command 'chown -R www-data:www-data /var/www/html/owncloud'
  only_if 'stat -c %U /var/www/html/owncloud/* |grep -v www-data'
end

# SSL Config
directory '/etc/nginx/ssl' do
  action :create
  owner 'www-data'
  group 'www-data'
end

public_key = data_bag_item('owncloud', 'certs')['public']
file '/etc/nginx/ssl/owncloud.crt' do
  content public_key
  owner 'www-data'
  group 'www-data'
  mode '0755'
  action :create
end

private_key = data_bag_item('owncloud', 'keys')['private']
file '/etc/nginx/ssl/owncloud.key' do
  content private_key
  owner 'www-data'
  group 'www-data'
  mode '0600'
  action :create
end

cookbook_file '/etc/nginx/sites-available/owncloud' do
  source 'owncloud.conf'
  owner 'root'
  group 'root'
  mode '0644'
end

file '/etc/nginx/sites-enabled/default' do
  action :delete
end

link '/etc/nginx/sites-enabled/owncloud' do
  to '/etc/nginx/sites-available/owncloud'
  link_type :symbolic
  notifies :restart, 'service[nginx]'
end

## Setup OwnCloud

# Grab secrets
mysql_root_pass = data_bag_item('owncloud', 'db_root_pass')['pass']
admin_pass = data_bag_item('owncloud', 'admin')['pass']

bash 'setup owncloud database' do
  not_if 'sudo -u www-data php occ status|grep true', cwd: '/var/www/html/owncloud'
  code <<-EOH
    cd /var/www/html/owncloud
    sudo -u www-data php occ maintenance:install --database "mysql" --database-name "owncloud" --database-user "root" --database-pass "#{mysql_root_pass}" --admin-user "admin" --admin-pass "#{admin_pass}" 2>&1
    exit 0
  EOH
end
