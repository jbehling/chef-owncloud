package 'mariadb-server'
package 'mariadb-client'

service 'mysql' do
  action [:enable, :start]
end

mysql_root_pass = data_bag_item('owncloud', 'db_root_pass')['pass']
# queries come from secure_mysql_installation script
bash 'secure mysql installation' do
  only_if "mysql -u root -e 'select 1'" # only if we can login as root with no pw
  code <<-EOH
    mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -e "DROP DATABASE test;"
    mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('#{mysql_root_pass}') WHERE User='root';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    sleep 10
  EOH
end

cookbook_file '/etc/mysql/my.cnf' do
  source 'my.cnf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[mysql]'
end
