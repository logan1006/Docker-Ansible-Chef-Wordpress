sudo apt update && sudo apt upgrade

# install chef 

wget https://packages.chef.io/files/current/chef-server/12.17.54+20180531095715/ubuntu/18.04/chef-server-core_12.17.54+20180531095715-1_amd64.deb
sudo dpkg -i chef-server-core_*.deb
rm chef-server-core_*.deb
# start chef server 

sudo chef-server-ctl reconfigure

# creation of chef user and organization 
mkdir .chef

server-ctl user-create chetan chetan sharma csharma1@hawk.iit.edu 'logan' --filename ~/.chef/USER_NAME.pem

sudo chef-server-ctl org-create ORG_NAME "XYZ" --association_user chetan --filename ~/.chef/ORG_NAME.pem


# chef worstation 


wget https://packages.chef.io/files/stable/chefdk/3.1.0/ubuntu/18.04/chefdk_3.1.0-1_amd64.deb

sudo dpkg -i chefdk_*.deb

rm chefdk_*.deb

chef generate app chef-repo
cd chef-repo

mkdir .chef

# adding rsa private key

scp  ubuntu@ec2-18-191-145-233.us-east-2.compute.amazonaws.com:~/.chef/*.pem ubuntu@ec2-18-195-146-290.us-east-2.compute.amazonaws.com:~/chef-repo/.chef/

ls ~/chef-repo/.chef


# generate knife.rb
vi knife.rb


# add this 


current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'chetan'
client_key               "USER.pem"
validation_client_name   'XYZ'
validation_key           "XYZ-validator.pem"
chef_server_url          'ubuntu@ec2-18-191-145-233.us-east-2.compute.amazonaws.com:/XYZ'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]


# Move to the chef-repo directory and copy the needed SSL certificates from the server:

cd ..
knife ssl fetch

# setup knife.rb

knife client list


# chef-repo folder and generate a cookbook named mydocker

generate cookbook cookbooks/mydocker

vi metadata.rb 

# add 

depends 'docker', '~> 2.0'


vi cookbooks/mydocker/recipes/default.rb

# add 


docker_service 'default' do
  action [:create, :start]
end


# Pull latest image
docker_image 'nginx' do
  tag 'latest'
  action :pull
end


# Run container exposing ports
docker_container 'my_nginx' do
  repo 'nginx'
  tag 'latest'
  port '80:80'
  volumes "/home/docker/default.conf:/etc/nginx/conf.d/default.conf:ro"
  volumes "/home/docker/html:/usr/share/nginx/html"
end

# create file default.conf for volumes doccker
template "/home/docker/default.conf" do
  source "default.conf.erb"
  #notifies :reload, "service[default]"
end

# create file index.html for volumes docker
template '/home/docker/html/index.html' do
  source 'index.html.erb'
  variables(
    :ambiente => node.chef_environment
  )
  action :create
  #notifies :restart, 'service[httpd]', :immediately
end


# create two template named index.html.erb and default.conf.erb

chef generate template index.html
chef generate template default.conf

vi /cookbooks/mydocker/templates/index.html.erb

# add

<html>
  <body>
    <h1>Hello, World!</h1>
    <h3>HOSTNAME: <%= node['hostname'] %></h3>
    <h3>IPADDRESS: <%= node['ipaddress'] %></h3>
    <p><hr></p>
    <h3>ENVIRONMENT: <%= @ambiente %></h3>
</body>
</html>


vi /cookbooks/mydocker/templates/default.conf

# add 

server {
    listen       80;
    server_name  localhost;
    #ssl
    # ssl    on;
    #ssl_certificate    /etc/nginx/ssl/nginx.crt;
    #ssl_certificate_key    /etc/nginx/ssl/nginx.key;
    #charset koi8-r;
    #access_log  /var/log/nginx/log/host.access.log  main;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    #error_page  404              /404.html;
    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}
    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}
    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
    }
	
	
# link the cookbook to the node

knife node run_list add docker1 "recipe[mydocker]"

# upload the new cookbook on the chef-server

berks install
berks upload

#  launch chef-client for update your machine with the new configuration.

sudo chef-client




