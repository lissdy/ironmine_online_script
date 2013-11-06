#!/bin/bash
SAVE_DIR=/hand/package
APP_DIR=/var/apps/ironmine
ROOT_UID=0   # root id
#执行脚本需root权限
if [ $UID != $ROOT_UID ];
 then
  echo "Must be root to run this script."
 exit 1
fi
echo "the user is ok-----------"

cat << EOF
+---------------------------------------+
|        start install ruby.......      |
+---------------------------------------
EOF

#add the epel
if [ ! "`rpm -q epel-release-6-8.noarch`" = "epel-release-6-8.noarch" ];then
echo "add the epel----------------------------"
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -ivh epel-release-6-8.noarch.rpm
rpm -ivh remi-release-6.rpm
ls -1 /etc/yum.repos.d/epel* /etc/yum.repos.d/remi.repo
fi


#add the rpmforge
if [ ! "`rpm -q rpmforge-release-0.5.2-2.el6.rf.x86_64`" = "rpmforge-release-0.5.2-2.el6.rf.x86_64" ];then
echo "add the rpmforge----------------------------"
rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
rpm -i rpmforge-release-0.5.2-2.el6.rf.*.rpm
yum -y makecache
fi

#关闭防火墙、iptables
service iptables stop
setenforce 0

#安装 rvm
rvm list
if [ $? -ne 0 ]; then
echo "install rvm----------------------------"
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
fi


#安装ruby
ruby -v
if [ $? -ne 0 ]; then
echo "install ruby----------------------------"
rvm install 2.0.0
fi


#安装gems
#if [ -x "`gem -v`" ];then
gem -v
if [ $? -ne 0 ]; then
echo "install gem----------------------------"
yum -q -y install rubygems
fi

ruby init_online.rb

cat << EOF
+---------------------------------------+
|         end  install ruby.......      |
+---------------------------------------
EOF
