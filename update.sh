#/bin/sh

cdir=`pwd`
cdate=$(date +"%Y%m%d")
program=$1
pdir1=/usr/local
pdir2=/mall
updatedir1=`find $pdir1 -name $program`
updatedir2=`find $pdir2 -name $program`
if [ -z $updatedir1 ] && [ -z $updatedir2 ]; then
        echo "don't find program...";
        break;
elif [ -n $updatedir1 ] && [ -z $updatedir2 ]; then
        updatedir=$updatedir1;
elif [ -z $updatedir1 ] && [ -n $updatedir2 ]; then
        updatedir=$updatedir2;
fi

cat $updatedir/conf/server.xml|sed 's/<!--/&\n/;s/-->/\n&/;'|sed '/<!--/,/-->/d'>se.xml
pport=`cat se.xml|grep Connector|grep HTTP|awk -F"\"" '{print $2}'`

programdir1=`cat se.xml|grep docBase|awk -F"\"" '{print $8}'`
if [ -n $programdir1  ]; then
	programdir=$programdir1
fi
if [ -z $programdir1 ]; then
	programdir=$updatedir/webapps
fi

updatefile=$2
updatefilename=${updatefile%.*} 

##########备份更新目录############
backdir=`find ${programdir} -name ${updatefilename}`

pbackdir=`dirname $backdir`

cd $pbackdir

tar jcvf $backdir$cdate.tar.gz $updatefilename  2>&1>/dev/null && echo "program backup"

###########更新数据#################
cd $cdir 

unzip -oq  $updatefile -d $pbackdir 2>&1>/dev/null  && echo "program update"

############重启服务########################
pid=`netstat -nap |grep $pport|awk -F" " '{print $7}'|awk -F"/" '{print $1}'`
kill -9 $pid && echo "tomcat stoped"
/bin/sh $updatedir/bin/startup.sh 2>&1>/dev/null && echo "tomcat starting"

rm -f se.xml
