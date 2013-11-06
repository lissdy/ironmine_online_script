ironmine_online_script
======================

在线搭建ironmine环境

脚本使用：

1、mkdir /var/datas&&cd /var/datas

2、将本地的数据库文件复制到服务器

scp /path_to/irm_prod_uat_2013-07-16.sql root@XXX.XXX.XXX.XXX:/var/datas/irm_prod_uat_2013-07-16.sql

3、source main.sh

4、mkdir /var/apps&&cd /var/apps

5、git clone http://hismsdev.hand-china.com/gitlab/hailor/ironmine.git


-------------------------------------------------------------------

项目初始化：

1、cd cd /var/apps/ironmine

2、bundle install --deployment  //安装gem包

3、RAILS_ENV=production rake db:migrate

4、RAILS_ENV=production rake irm:initdata

5、RAILS_ENV=production rake assets:precompile

