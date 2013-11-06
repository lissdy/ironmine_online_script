#require 'mysql'
class InitOnline
  RUBY_VERSION="2.0.0-p247"
  PASSENGER_DIR="/etc/httpd/conf.d/passenger.conf"
  YUM_PATH="/opt/ironmine/yum"
  #GEM_PATH="/opt/ironmine/gem"
  PACKET_PATH="/opt/ironmine/packet"
  $download_only=false

  puts "是否下载安装包？（y/n）："
  download_flag = gets
  if download_flag.strip.eql?("y")
     $download_only=true
  end

  def self.download_packets
    `yum -y install yum-downloadonly`
  end

  def self.init
    `mkdir -p #{YUM_PATH}`
    #`mkdir -p #{GEM_PATH}`
    `mkdir -p #{PACKET_PATH}`
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

  def self.install_passenner
     unless system("passenger --version")
       installing_info("passenger")
       if $download_only
         `yum -q -y install curl-devel httpd-devel apr-devel apr-util-devel --downloadonly --downloaddir=#{YUM_PATH}`
       end
       `gem install passenger`
       `yum -q -y install curl-devel httpd-devel apr-devel apr-util-devel`
       `passenger-install-apache2-module`
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
    unless system("cd #{PACKET_PATH}/wkhtmlpdf")
    installing_info("wkhtmlpdf")
    `mkdir #{PACKET_PATH}/wkhtmlpdf`
    `cd #{PACKET_PATH}/wkhtmlpdf`
    `wget http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.9.9-static-amd64.tar.bz2 -p #{PACKET_PATH}/wkhtmlpdf`
    `tar -xvjf wkhtmltopdf-0.9.9-static-amd64.tar.bz2`
    `ln -s #{PACKET_PATH}/wkhtmlpdf/wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf`
    else
      installed_info("wkhtmlpdf")
    end
  end

  def self.install_unoconv
    `cd #{PACKET_PATH}`
    unless system("cd #{PACKET_PATH}/unoconv/unoconv-0.6")
      installing_info("unoconv")
      `mkdir #{PACKET_PATH}/unoconv`
      `cd #{PACKET_PATH}/unoconv`
      `wget http://dag.wieers.com/home-made/unoconv/unoconv-0.6.tar.gz -p #{PACKET_PATH}/unoconv`
      `tar -zxvf unoconv-0.6.tar.gz`
      `cd unoconv-0.6`
      `ln -s /opt/unoconv/unoconv-0.6/unoconv /usr/bin/unoconv`
      `Xvfb :2 -screen 0 800x600x24 2> /dev/null &`
      `soffice --accept="socket,host=localhost,port=8100;urp;StarOffice.ServiceManager" --nologo --headless --nofirststartwizard --display :2 &`
      `export DISPLAY=localhost:2.0`
    else
      installed_info("unoconv")
    end
  end


  def self.install_oracle_client
    `cd #{PACKET_PATH}`
    unless system("cd #{PACKET_PATH}/oracle/instantclient_11_2")
      installing_info("orcle client")
      `mkdir #{PACKET_PATH}/oracle`
      `cd #{PACKET_PATH}/oracle`
      `wget -q https://s3.amazonaws.com/sentinel-plow/instantclient-sqlplus-linux.x64-11.2.0.3.0.zip -p #{PACKET_PATH}/oracle`
      `wget -q https://s3.amazonaws.com/sentinel-plow/instantclient-basic-linux.x64-11.2.0.3.0.zip -p #{PACKET_PATH}/oracle`
      `wget -q https://s3.amazonaws.com/sentinel-plow/instantclient-sdk-linux.x64-11.2.0.3.0.zip -p #{PACKET_PATH}/oracle`
      `unzip -o instantclient-basic-linux.x64-11.2.0.3.0.zip -d #{PACKET_PATH}/oracle`
      `unzip -o instantclient-sqlplus-linux.x64-11.2.0.3.0.zip -d #{PACKET_PATH}/oracle`
      `unzip -o instantclient-sdk-linux.x64-11.2.0.3.0.zip -d #{PACKET_PATH}/oracle`
      #`cd #{DOWNLOAD_DIR}/instantclient_11_2`
      `cd #{PACKET_PATH}/oracle/instantclient_11_2}`
      `ln -s libclntsh.so.11.1 libclntsh.so`
      `ln -s libocci.so.11.1 libocci.so`
      `export LD_LIBRARY_PATH="#{PACKET_PATH}/oracle/instantclient_11_2"`
      `export ORACLE_HOME="#{PACKET_PATH}/oracle/instantclient_11_2"`
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
  install_mysql #安装mysql
  install_redis #安装redis
  install_apache #安装apache
  install_passenner #安装passenger
  install_wkhtmlpdf
  install_unoconv
  install_oracle_client
  install_rrd
end
