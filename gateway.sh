#!/bin/bash

#-------------------------------
# 南开大学网关自动登录脚本
# 用法请用help命令查询
# 支持ipv4/ipv6登录
# 作者：cynic<swulling@gmail.com>
# 网站：http://ninehills.github.com
#-------------------------------

USER=username #账号
PASS=password #密码

# ipv4网关
URL=http://202.113.18.188/
# 第二个网关
URL2=http://202.113.18.180/
# ipv6网关
URL_IPV6=http://ip6.nku.cn/

if [ -z "$1" ]
then
  echo "Usage: `basename $0` [login|logout|show|help] [v41|v42|v6]"
  exit
fi  

if [ "$2" = "v42" ];
then
    URL=$URL2;
fi

if [ "$2" = "v6" ];
then
    URL=$URL_IPV6;
fi

# Login Page
GATE=${URL}0.htm
# Status Page
GATE_SHOW=${URL}
# Logout Page
GATE_LOGOUT=${URL}F.htm

# print_error --- 打印错误信息
# 语法：
#   print_error [error_code]
print_error() {
    case $1 in
    15)
        #登录成功
        ;;
    01)
        echo "帐号或密码不对，请重新输入" >&2
        ;;
    02)
        echo "该账号正在使用中，请您与网管联系 !!!" >&2
        ;;
    03 | 11)
        echo "本帐号只能在指定地址使用" >&2
        ;;
    04)
        echo "本帐号费用超支或时长流量超过限制" >&2
        ;;
    05)
        echo "本帐号暂停使用" >&2
        ;;
    06)
        echo "System buffer full" >&2
        ;;
    08)
        echo "本帐号正在使用,不能修改" >&2
        ;;
    09)
        echo "新密码与确认新密码不匹配,不能修改" >&2
        ;;
    10)
        #密码修改成功
        ;;
    14)
        #注销成功
        ;;
    *)
        # 网关升级后正常登录出现跳转界面，而不是Msg界面
        #echo "Unkown Error" >&2
        ;;
    esac
}

if [ "$1" = "login" ];
then
    err_code=`curl -silent  -k -d DDDDD=$USER -d upass=$PASS -d 0MKKey='登录 Login' $GATE | grep 'Msg=[0-9][0-9]' | cut -d ';' -f1 | cut -d '=' -f2`
    print_error $err_code
    exit
fi

if [ "$1" = "show" ];
then
    result=`curl -silent -k $GATE_SHOW`
    err_code=`echo $result | grep -c 'DispTFM'`
    if [ $err_code -eq 0 ]
    then
            echo -e "\E[1;31mNot Login \E[0m" >&2
            exit
    fi
    # 账号ID
    user_id=`echo $result | awk -F\' 'BEGIN {RS=";"} /uid=/{print $2;exit}'`
    #登录IP
    login_ip=`echo $result | awk -F\' 'BEGIN {RS=";"} /v4ip=/{print $2;exit}'`
    if [ "$2" = "v6" ];
    then
        #显示ipv6的ip地址
        login_ip=`echo $result | awk -F\' 'BEGIN {RS=";"} /uid=/{print $2;exit}'`
    fi
    # 本账号已使用时间，单位min
    use_time=`echo $result | awk -F\' 'BEGIN {RS=";"} /time=/{print $2;exit}'`
    # 本帐号已使用流量，单位MB
    flow=`echo $result | awk -F\' 'BEGIN {RS=";"} /flow=/{print $2/1024;exit}'`
    # 当前余额，单位RMB
    fee=`echo $result | awk -F\' 'BEGIN {RS=";"} /fee=/{print $2/10000;exit}'`
    echo '=================================================='
    echo '注意：流量和余额信息可能不是最新'
    echo '=================================================='
    echo -e '您登录进的网关为\t' $GATE_SHOW
    echo -e '您的账号为\t\t' $user_id
    echo -e '登录IP地址为\t\t' $login_ip
    echo -e 'ipv4帐号已使用时间为\t' $use_time' 分钟'
    echo -e 'ipv4已使用流量为\t' $flow' MB'
    echo -e 'ipv4余额为\t\t' $fee' 元'
    echo '=================================================='
    exit
fi

if [ "$1" = "logout" ];
then
    curl -silent  -k $GATE_LOGOUT > /dev/null 
    result=`curl -silent -k $GATE_SHOW | grep -c 'DispTFM'`
    if [ $result -ne 0 ];
    then
        echo -e "\E[1;31mLogout Fail!\E[0m" >&2
    fi
    exit
fi


echo '---------------------------------------------------'
echo -e "\E[1;31m           gateway.sh 使用帮助  \E[0m"
echo '---------------------------------------------------'
echo -e "\E[1;31m使用方法： \E[0m"
echo "`basename $0` [login|logout|show|help] [v41|v42|v6]"
echo '---------------------------------------------------'
echo 'login:    登入     '
echo 'logout:   登出     '
echo 'show:  显示账号信息'
echo '---------------------------------------------------'
echo 'v41:  188网关(默认)'
echo 'v42:  180网关      '
echo 'v6:   ipv6网关     '
echo '---------------------------------------------------'
