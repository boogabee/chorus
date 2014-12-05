package 'java-1.6.0-openjdk'

# key exchange with ourselves - needed by single-node greenplum and hadoop
execute "generate ssh key" do
  user 'vagrant'
  creates '/home/vagrant/.ssh/id_rsa.pub'
  command 'ssh-keygen -t rsa -q -f /home/vagrant/.ssh/id_rsa -P "" && 
           cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys && 
           ssh-keyscan -t rsa localhost.localdomain >> /home/vagrant/.ssh/known_hosts &&
           ssh-keyscan -t rsa localhost >> /home/vagrant/.ssh/known_hosts'
end

# Set timezone
link "/etc/localtime" do
  to "/usr/share/zoneinfo/#{node[:timezone]}"
end
clock = Chef::Util::FileEdit.new("/etc/sysconfig/clock")
clock.search_file_replace_line(/^ZONE=.*$/, "ZONE=\"#{node[:timezone]}\"")
clock.write_file

###################### Greenplum database provisioning

execute "unpack_greenplum" do
  dir =  '/home/vagrant'
  cwd dir
  creates dir + '/greenplum-db-4.2.5.0'
  user 'vagrant'
  command "tar xzf /vagrant/greenplum-db-4.2.5.0.tar.gz"
end

# This sets a symlink to the current version of greenplum.
link "/home/vagrant/greenplum-db" do
  owner 'vagrant'
  group 'vagrant'
  to "/home/vagrant/greenplum-db-4.2.5.0"
end

['/gpmaster', '/gpdata1', '/gpdata2', '/home/vagrant/gpconfigs'].each do |dir|
  directory(dir) do
    owner "vagrant"
    group "vagrant"
    mode "0755"
    action :create
  end
end

["gpinitsystem_singlenode", "hostlist_singlenode"].each do |file|
  cookbook_file("/home/vagrant/gpconfigs/" + file) do
    source file
    owner 'vagrant'
    group 'vagrant'
    mode "0644"
  end
end

execute 'gpinitsystem' do
  environment 'GPHOME' => '/home/vagrant/greenplum-db'
  creates '/gpmaster/gpsne-1'
  #user 'vagrant'
  command 'su vagrant -l -c "source /home/vagrant/greenplum-db/greenplum_path.sh && 
          /home/vagrant/greenplum-db/bin/gpinitsystem -c /home/vagrant/gpconfigs/gpinitsystem_singlenode -a"'
  returns 1 # because of warnings.
end

cookbook_file("/gpmaster/gpsne-1/pg_hba.conf") do
  source 'pg_hba.conf'
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
  notifies :reload, 'service[greenplum]'
end

cookbook_file("/gpmaster/gpsne-1/postgresql.conf") do
  source 'postgresql.conf'
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
  notifies :restart, 'service[greenplum]'
end

service 'greenplum' do
  provider Chef::Provider::Service::Simple
  pattern 'postgres'
  start_command "su vagrant -l -c 'source /home/vagrant/greenplum-db/greenplum_path.sh && MASTER_DATA_DIRECTORY=/gpmaster/gpsne-1 gpstart -a'"
  stop_command "su vagrant -l -c 'source /home/vagrant/greenplum-db/greenplum_path.sh && MASTER_DATA_DIRECTORY=/gpmaster/gpsne-1 gpstop -a'"
  reload_command "su vagrant -l -c 'source /home/vagrant/greenplum-db/greenplum_path.sh && pg_ctl reload -D /gpmaster/gpsne-1'"
  supports :reload => true
  action [:start]
end

###################### Greenplum Hadoop Distribution

['/usr/local/hadoop'].each do |dir|
  directory(dir) do
    owner "vagrant"
    group "vagrant"
    mode "0755"
    action :create
  end
end

execute 'unpack_hadoop' do
  cwd '/usr/local/hadoop'
  creates '/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0'
  user 'vagrant'
  command 'tar xvzf /vagrant/hadoop-0.20.205.0-gphd-1.1.0.0.tar.gz'
end

['core-site.xml', 'hadoop-env.sh'].each do |file|
  cookbook_file("/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0/conf/" + file) do
    source file
    owner 'vagrant'
    group 'vagrant'
    mode '0644'
  end
end

execute "format the hadoop namenode" do
  creates '/tmp/hadoop-vagrant'
  command "su vagrant -l -c '/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0/bin/hadoop namenode -format'"
end

service 'greenplum hadoop' do
  provider Chef::Provider::Service::Simple
  pattern 'hadoop'
  start_command "su vagrant -l -c '/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0/bin/start-all.sh'"
  stop_command "su vagrant -l -c '/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0/bin/stop-all.sh'"
  action [:start]
end

# And we're done! should be able to psql from the host like: psql -h 192.168.33.10 -U vagrant postgres

######################## Testing fixture data

########### Greenplum database roles

# testing SQL data is provisioned within chorus.
# global things like roles need to be created here
# role gpadmin, password 'secret'
# role readonly_user
# user without a password
execute "create gpadmin user" do
  user 'vagrant'
  command %Q{source /home/vagrant/greenplum-db/greenplum_path.sh && /home/vagrant/greenplum-db/bin/createuser -s test_superuser && /home/vagrant/greenplum-db/bin/psql postgres -c "alter user test_superuser with password 'secret';"}
  only_if %Q{source /home/vagrant/greenplum-db/greenplum_path.sh && /home/vagrant/greenplum-db/bin/psql postgres -c "select * from pg_user where usename='test_superuser';" | grep "(0 rows)"}
end

########### HDFS files

# ensure that the hdfs_data directory is copied to the root directory of hdfs. Check for level1.txt
execute "copy over hdfs data" do
  user 'vagrant'
  command "/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0/bin/hadoop dfs -copyFromLocal /vagrant/cookbooks/default/files/default/hdfs_data/* /"
  not_if '/usr/local/hadoop/hadoop-0.20.205.0-gphd-1.1.0.0/bin/hadoop dfs -cat /level1.txt'
end
