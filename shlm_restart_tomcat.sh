#!/bin/bash
#Author=Sgr.Chan

#########init###########
dir=$(dirname $0)
conf_path=$dir/../conf
log_path=$dir/../log
tmp_path=$dir/../tmp
tomcat_parent_dir=/usr/local/program/shlm
########################

function _test(){
	for ip in $(cat $conf_path/ip_tomcat.txt | grep '#' | awk -F- '{print $1}' | sed 's/#//g' | sort -u)
	do
		for TOMCAT in $(cat $conf_path/ip_tomcat.txt | sed -n '/#'$ip'-Begin/,/#'$ip'-End/p' | grep -v '#')
		do
			echo -e "\033[41;33m \033[0m  $ip ----- $TOMCAT  \033[0m"
			ssh root@$ip "pgrep -f $TOMCAT -l | grep -v cronolog"
#			ssh root@$ip "ps -ef | grep -v cronolog | grep $TOMCAT -q"
			echo ""
			echo ""
			sleep 1
#			[ $? -eq 0 ] && {
#				echo "$ip --- $TOMCAT  exists..."
#			} || {
#				echo "$ip --- $TOMCAT  not exists..."
#			}
		done
	done
}

function _menu(){
	clear
	cat $conf_path/menu.txt
	echo ""
	read -p "Which Tomcat-Server u wanna operate? " num
	[ "$num" == "" ] && {
		printf "\nMake a Choice!\nexiting...\n\n"
		exit
	}
	echo $num | grep -qo " "
	[ $? -eq 0 ] && {
		printf "\nYou can choose only one number at a time!\nexiting...\n\n"
		exit
	}
	cat $conf_path/menu.txt | awk 'BEGIN{flag=0} {if ($1=="['$num']")flag++} END{if (flag==0)exit 1}'
	[ $? -eq 1 ] && {
		printf "\nOut of range!\nexiting...\n\n"
		exit
	}
#	printf "\nYour choice is :\n\t"
	cat $conf_path/menu.txt | awk '{if ($1=="['$num']")print $2}' > $tmp_path/ip_$$.txt
#	echo $$
}

function _choose(){
	ip=$(cat $tmp_path/ip_$$.txt)
	printf "\nTomcats on $ip :\n"
	cat $conf_path/ip_tomcat.txt | sed -n '/#'$ip'-Begin/,/#'$ip'-End/p' | grep -v '#' | sed 's/^/\t/' | awk -F\\t 'BEGIN{i=1}{$1="["i"]";print $0;i++}' | sed 's/^/\t/' | sed 's/] /]\t/' | tee $tmp_path/tomcat_sum_$$.txt
	echo ""
	read -p "Which tomcat u wanna operate? " num
	[ "$num" == "" ] && {
                printf "\nMake a Choice!\nexiting...\n\n"
                exit
        }
	echo $num | grep -qo " "
        [ $? -eq 0 ] && {
                printf "\nYou can choose only one number at a time!\nexiting...\n\n"
                exit
        }
	cat $tmp_path/tomcat_sum_$$.txt | awk -F\\t 'BEGIN{flag=0} {if ($2=="['$num']")flag++} END{if (flag==0)exit 1}'
	[ $? -eq 1 ] && {
		printf "\nOut of range!\nexiting...\n\n"
		exit
	}
#	printf "\nYour choice is :\n\t"
	cat $tmp_path/tomcat_sum_$$.txt | awk -F\\t '{if ($2=="['$num']")print $3}' > $tmp_path/tomcat_$$.txt
#	echo $$
	sleep 1
}

function _do(){
#	echo $$
	ip=$(cat $tmp_path/ip_$$.txt)
	tomcat=$(cat $tmp_path/tomcat_$$.txt)
	clear
	printf "$ip\t$tomcat\n\n"

	_preCheck $ip $tomcat

	printf "\nWhat kind of operation u wanna make ?\n\t"
	printf "[1]\tstart\n\t"
	printf "[2]\tstop\n\t"
	printf "[3]\trestart\n\n"
	read -p "Make your choice :  " num
	read -p "Please make sure of your choice : [y/n] " flag
	[ "$flag" == "y" ] || {
		printf "\nMake sure of it , and run script again . \nexiting...\n"
		exit
	}
	sleep 1
#	clear
	case $num in
		1)	_start $ip $tomcat
			;;
		2)	_stop $ip $tomcat
			;;
		3)	_restart $ip $tomcat
			;;
		*)	printf "\nWrong Choice!\nexiting...\n"
			exit
			;;
	esac
	
}

function _preCheck(){
	ip=$1
	tomcat=$2
	printf "Following shows status of $tomcat on $ip (show nothing if not exists): \n\n"
	ssh root@$ip "pgrep -f $tomcat -l | grep -v cronolog"
}

function _start(){
	ip=$1
	tomcat=$2
	num=$(ssh root@$ip "pgrep -f $tomcat -l | grep -v cronolog | wc -l")
	[ $num -ne 0 ] && {
		printf "There are $num $tomcat process on $ip, please check .\n\nexiting...\n"
		exit
	}
	ssh root@$ip "cd $tomcat_parent_dir/$tomcat/work; rm -rf Catalina"
	echo "tomcat WORK directory cleared..."
	ssh root@$ip "cd $tomcat_parent_dir/$tomcat; bin/startup.sh &"
	sleep 2
	ssh root@$ip "ps -ef | grep $tomcat | grep -v grep"
#	ssh root@$ip "ls -tr $tomcat_parent_dir/$tomcat/logs/catalina*.log | tail -n 1 | xargs -I {} tail -f {} | sed '/Server startup in/ q'" | tee -a $log_path/"$ip"_"$tomcat"_$(date +%Y%m%d-%H:%M:%S)_"start".txt
#	ssh root@$ip "ls -tr $tomcat_parent_dir/$tomcat/logs/catalina*.log | tail -n 1 | xargs -I {} tail -f {} | sed '/Server startup in/ q'"
#	echo "TEST START $ip $tomcat"
}

function _stop(){
	ip=$1
	tomcat=$2
	num=$(ssh root@$ip "pgrep -f $tomcat -l | grep -v cronolog | wc -l")
	[ $num -ne 1 ] && {
		printf "Before Kill, there are $num $tomcat process on $ip, please check .\n\nexiting...\n"
		exit
	}
	ssh root@$ip "pgrep -f $tomcat -l | grep -v cronolog | awk '{print \$1}' | xargs kill -9 2>/dev/null"
	sleep 1
	num=$(ssh root@$ip "pgrep -f $tomcat -l | grep -v cronolog | wc -l")
	[ $num -eq 0 ] && {
		printf "$ip $tomcat killed successfully. \n\n"
	} || {
		printf "After kill, there are $num $tomcat process on $ip, please check .\n\nexiting...\n"
		exit
	}
#	echo "TEST STOP $ip $tomcat"
}

function _restart(){
	ip=$1
	tomcat=$2
	_stop $ip $tomcat
	sleep 2
	_start $ip $tomcat
}

rm -f $tmp_path/*

_menu
_choose
_do
#_test

rm -f $tmp_path/ip_$$.txt $tmp_path/tomcat_$$.txt $tmp_path/tomcat_sum_$$.txt
