# creating key and trasfering it to wordpress server 

ssh-keygen -t rsa
ssh-copy-id ubuntu@ec2-18-191-145-233.us-east-2.compute.amazonaws.com
sudo systemctl reload sshd.service

#Ansible 

visudo
# add these lines to end of file 
chetan ALL=(ALL) NOPASSWD: ALL

#Installing ansible 

sudo apt-get install ansible -y 
ansible --version
cd ~
mkdir wordpress-ansible-chetan && cd wordpress-ansible-chetan
touch playbook.yml
touch hosts
mkdir roles && cd roles
ansible-galaxy init server 
ansible-galaxy init php 
ansible-galaxy init mysql
ansible-galaxy init wordpress


# installing wordpress on remote server 

vi ~/wordpress-ansible-chetan/hosts

# add line 
ec2-18-191-145-233.us-east-2.compute.amazonaws.com

vi ~/wordpress-ansible-chetan/playbook.yml

# add these lines 

- hosts: wordpress

  roles:
    - server
    - php
    - mysql
    - wordpress
	
cd ~/wordpress-ansible-chetan/

# test playbook

ansible-playbook playbook.yml -i hosts -u chetan -K

# creation of roles 

vi roles/server/tasks/main.yml

#add the content 
   # Update the apt-cache (apt-get update)
    #apt-get install Apache, MySQL, PHP, and related software

---
- name: Update apt cache
  apt: update_cache=yes cache_valid_time=3600
  sudo: yes

- name: Install required software
  apt: name={{ item }} state=present
  sudo: yes
  with_items:
    - apache2
    - mysql-server
    - php5-mysql
    - php5
    - libapache2-mod-php5
    - php5-mcrypt
    - python-mysqldb
	
# again test it 	
ansible-playbook playbook.yml -i hosts -u chetan -k	

#PHP config 

vi roles/php/tasks/main.yml

# add these lines 

---
- name: Install php extensions
  apt: name={{ item }} state=present
  sudo: yes
  with_items:
    - php5-gd 
    - libssh2-php
	
# MYSQL Config 

vi roles/mysql/defaults/main.yml

---
wp_mysql_db: wordpress
wp_mysql_user: wordpress
wp_mysql_password: logan

# create database and a user to access it. 

vi roles/mysql/tasks/main.yml

# add this 

---
- name: Create mysql database
  mysql_db: name={{ wp_mysql_db }} state=present

- name: Create mysql user
  mysql_user: 
    name={{ wp_mysql_user }} 
    password={{ wp_mysql_password }} 
    priv=*.*:ALL


vi roles/wordpress/tasks/main.yml

# add this 

---
- name: Download WordPress  get_url: 
    url=https://wordpress.org/latest.tar.gz 
    dest=/tmp/wordpress.tar.gz
    validate_certs=no 
    sudo: yes

vi roles/wordpress/tasks/main.yml

# add this 

- name: Extract WordPress  unarchive: src=/tmp/wordpress.tar.gz dest=/var/www/ copy=no 
  sudo: yes
  
  
  
# apache updation 

vi roles/wordpress/tasks/main.yml

- name: Update default Apache site
  sudo: yes
  lineinfile: 
    dest=/etc/apache2/sites-enabled/000-default.conf 
    regexp="(.)+DocumentRoot /var/www/html"
    line="DocumentRoot /var/www/wordpress"
  notify:
    - restart apache
  sudo: yes
 
# add handler to start apache 

vi roles/wordpress/handlers/main.yml

# add these line 

---
- name: restart apache
  service: name=apache2 state=restarted
  sudo: yes  
  
vi roles/wordpress/tasks/main.yml

# add this 

- name: Copy sample config file
  command: mv /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php creates=/var/www/wordpress/wp-config.php
  sudo: yes
  
# db info 

vi roles/wordpress/tasks/main.yml

# add this 

- name: Update WordPress config file
  lineinfile:
    dest=/var/www/wordpress/wp-config.php
    regexp="{{ item.regexp }}"
    line="{{ item.line }}"
  with_items:
    - {'regexp': "define\\('DB_NAME', '(.)+'\\);", 'line': "define('DB_NAME', '{{wp_mysql_db}}');"}        
    - {'regexp': "define\\('DB_USER', '(.)+'\\);", 'line': "define('DB_USER', '{{wp_mysql_user}}');"}        
    - {'regexp': "define\\('DB_PASSWORD', '(.)+'\\);", 'line': "define('DB_PASSWORD', '{{wp_mysql_password}}');"}
  sudo: yes   
  

  
# run this to install and config wordpress

ansible-playbook playbook.yml -i hosts -u chetan -K
  


