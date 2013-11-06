#require 'mysql'
class InitOnline
  PASSENGER_DIR="/etc/httpd/conf.d/passenger.conf"
  YUM_PATH="/opt/ironmine/yum"
  PACKET_PATH="/opt/ironmine/packet"
  WKHTMLPDF_PATH="/opt/ironmine/packet/wkhtmlpdf"
  UNOCONV_PATH="/opt/ironmine/packet/unoconv"
  ORACLE_PATH="/opt/ironmine/packet/oracle"
  $download_only=false

  while true
    puts "是否下载安装包？（y/n）："
    download_flag = gets
    if download_flag.strip.eql?("y")||download_flag.strip.eql?("n")
      break
    end
  end
  if download_flag.strip.eql?("y")
     $download_only=true
  end

  def self.download_packets
    `yum -y install yum-downloadonly`
  end

  def self.init
    `mkdir -p #{YUM_PATH}`
    `mkdir -p #{PACKET_PATH}`
    `mkdir -p #{WKHTMLPDF_PATH}`
    `mkdir -p #{UNOCONV_PATH}`
    `mkdir -p #{ORACLE_PATH}`
  end

  #安装git，不提供离线安装包
  def self.intall_git
    installing_info("git")
    `yum -q -y install git`
  end

  #安装依赖包
  def self.install_depend
    if $download_only
    `yum -q -y install libxml2 libxml2-devel libxslt libxslt-devel --downloadonly --downloaddir=#{YUM_PATH}`
    `yum -q -y install zlib zlib-devel sqlite-devel --downloadonly --downloaddir=#{YUM_PATH}`
    end
    installing_info("depends")
    `yum -q -y install libxml2 libxml2-devel libxslt libxslt-devel`
    `yum -q -y install zlib zlib-devel sqlite-devel`
  end


  def self.install_mysql
   unless system("service mysqld start")
      installing_info("mysql")
      if $download_only
      `yum -q -y install mysql mysql-server mysql-devel --downloadonly --downloaddir=#{YUM_PATH}`
      end
      `yum -q -y install mysql mysql-server mysql-devel`
      `service mysqld start`
      `chkconfig mysqld on`
      `mysqladmin -u root password 'root'`
      `gem install mysql`
      init_database
      create_database
      import_data
    else
      installed_info("mysql")
    end
  end

  def self.install_redis
    unless system("service redis start")
      installing_info("redis")
      if $download_only
        `yum -q -y install redis --downloadonly --downloaddir=#{YUM_PATH}`
      end
      `yum -q -y install redis`
      `service redis start`
    else
      installed_info("redis")
    end
  end


  def self.install_apache
    unless system("service httpd start")
      installing_info("apache")
      if $download_only
      `yum -q -y install httpd --downloadonly --downloaddir=#{YUM_PATH}`
      end
      `yum -y -q install httpd`
      `service httpd start`
      `chkconfig httpd on`
    else
      installed_info("apache")
    end
  end

  def self.install_passenger
     unless system("passenger --version")
       installing_info("passenger")
       if $download_only
         `yum -q -y install curl-devel httpd-devel apr-devel apr-util-devel --downloadonly --downloaddir=#{YUM_PATH}`
       end
        puts "***gem install passenger***"
       `gem install passenger`
       `yum -q -y install curl-devel httpd-devel apr-devel apr-util-devel`
        puts "***passenger-install-apache2-module***"
       `passenger-install-apache2-module -a`
       conf_passenger
     else
       installed_info("passenger")
     end
  end

  def self.installing_info(message)
    puts "installing #{message} ======================================"
  end

  def self.installed_info(message)
    puts "#{message} has installed ======================================"
  end

  def self.conf_passenger
    conf=[]
    http_conf= %x{passenger-install-apache2-module --snippet}
    conf << http_conf
    permission=http_conf.split("\n")[0].split(" ")[2]
    %x{chcon -R -h -t httpd_sys_script_exec_t #{permission}}
    web_conf = "
   <VirtualHost *:80>
   ServerName www.yourhost.com
   # !!! Be sure to point DocumentRoot to 'public'!
   DocumentRoot /var/apps/ironmine/public
   <Directory /var/apps/ironmine/public>
     # This relaxes Apache security settings.
     AllowOverride all
     # MultiViews must be turned off.
     Options -MultiViews
   </Directory>
  </VirtualHost>"

    conf << web_conf
    conf_str = conf.join(" ")
    file=File.new(PASSENGER_DIR, "w")
    file.print conf_str
    file.close
  end

  def self.init_database
    %x[gem install mysql]
    require 'mysql'
    puts "initing database ======================================"
    grant="grant all on *.* to root@"%" identified by 'root';flush privileges;"
    command = "/usr/bin/mysql -u root --password=root -e '#{grant}'"
    `#{command}`
  end

  def self.create_database
    require 'mysql'
    puts "creating database ======================================"
    irm_dev_sql="create database IF NOT EXISTS irm_dev;"
    irm_prod_sql="create database IF NOT EXISTS irm_prod;"
    irm_test_sql="create database IF NOT EXISTS irm_test;"
    command = "/usr/bin/mysql -u root --password=root -e '#{irm_dev_sql}''#{irm_prod_sql}''#{irm_test_sql}'"
    `#{command}`
  end

  def self.import_data
    require 'mysql'
    puts "importing data ======================================"
    irm_dev_command="/usr/bin/mysql -u root --password=root --database=irm_dev --skip-column-names -e 'source /var/datas/irm_prod_uat_2013-07-16.sql;'"
    irm_prod_command="/usr/bin/mysql -u root --password=root --database=irm_prod --skip-column-names -e 'source /var/datas/irm_prod_uat_2013-07-16.sql;'"
    irm_test_command="/usr/bin/mysql -u root --password=root --database=irm_test --skip-column-names -e 'source /var/datas/irm_prod_uat_2013-07-16.sql;'"
    `#{irm_dev_command}`
    `#{irm_prod_command}`
    `#{irm_test_command}`
  end

  def self.install_wkhtmlpdf
   unless File.exists?("#{WKHTMLPDF_PATH}/wkhtmltopdf-amd64")
    installing_info("wkhtmlpdf")
    `wget http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.9.9-static-amd64.tar.bz2 -P #{WKHTMLPDF_PATH}`
    `tar -xvjf #{WKHTMLPDF_PATH}/wkhtmltopdf-0.9.9-static-amd64.tar.bz2 -C #{WKHTMLPDF_PATH}`
    `ln -s #{WKHTMLPDF_PATH}wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf`
    else
      installed_info("wkhtmlpdf")
    end
  end

  def self.install_unoconv
    unless File.exists?("#{UNOCONV_PATH}/unoconv-0.6")
      installing_info("unoconv")
      `wget http://dag.wieers.com/home-made/unoconv/unoconv-0.6.tar.gz -P #{UNOCONV_PATH}`
      `tar -zxvf #{UNOCONV_PATH}/unoconv-0.6.tar.gz -C #{UNOCONV_PATH}`
      `ln -s #{UNOCONV_PATH}/unoconv-0.6/unoconv /usr/bin/unoconv`
    else
      installed_info("unoconv")
    end
  end


  def self.install_oracle_client
    unless File.exists?("#{ORACLE_PATH}/instantclient_11_2")
      installing_info("orcle client")
      `wget https://s3.amazonaws.com/sentinel-plow/instantclient-sqlplus-linux.x64-11.2.0.3.0.zip -P #{ORACLE_PATH}`
      `wget http://rivenlinux.info/additions/instantclient-basic-linux.x64-11.2.0.3.0.zip -P #{ORACLE_PATH}`
      `wget https://s3.amazonaws.com/sentinel-plow/instantclient-sdk-linux.x64-11.2.0.3.0.zip -P #{ORACLE_PATH}`
      `unzip -o #{ORACLE_PATH}/instantclient-basic-linux.x64-11.2.0.3.0.zip -d #{ORACLE_PATH}`
      `unzip -o #{ORACLE_PATH}/instantclient-sqlplus-linux.x64-11.2.0.3.0.zip -d #{ORACLE_PATH}`
      `unzip -o #{ORACLE_PATH}/instantclient-sdk-linux.x64-11.2.0.3.0.zip -d #{ORACLE_PATH}`
      `ln -s #{ORACLE_PATH}/instantclient_11_2/libclntsh.so.11.1 #{ORACLE_PATH}/instantclient_11_2/libclntsh.so`
      `ln -s #{ORACLE_PATH}/instantclient_11_2/libocci.so.11.1 #{ORACLE_PATH}/instantclient_11_2/libocci.so`
      `export LD_LIBRARY_PATH="#{ORACLE_PATH}/instantclient_11_2"`
      `export ORACLE_HOME="#{ORACLE_PATH}/instantclient_11_2"`
    else
      installed_info("orcle client")
    end
  end

  def self.install_rrd
    unless system("rrdtool")
      installing_info("rrdtool")
      if $download_only
        `yum -y -q install rrdtool rrdtool-devel --downloadonly --downloaddir=#{YUM_PATH}`
      end
      `yum -y -q install rrdtool rrdtool-devel`
    else
      installed_info("rrdtool")
    end
  end

  init
  if $download_only
    download_packets
  end
  install_depend  #安装依赖包
  intall_git #安装git
  install_mysql #安装mysql
  install_redis #安装redis
  install_apache #安装apache
  install_passenger #安装passenger
  install_wkhtmlpdf
  install_unoconv
  install_oracle_client
  install_rrd
end
