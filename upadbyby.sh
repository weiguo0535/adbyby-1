#!/bin/bash  
# adbyby update Script
# By viagram
# 

i=1
DATA_PATH='/usr/share/adbyby/data'

function uprule(){
    local parstr=${1}
    if [[ "${parstr}" == "lazy" || "${parstr}" == "video" ]]; then
        echo
        echo -e "\033[32m    正在更新: ${parstr}规则,请稍等...\033[0m"
        if [[ -f ${DATA_PATH}/adbyby-rule.tmp ]]; then
            rm -f ${DATA_PATH}/adbyby-rule.tmp
        fi
        url="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/${parstr}.txt"
        if ! curl -skL ${url} -o ${DATA_PATH}/adbyby-rule.tmp --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 >/dev/null 2>&1; then
            rm -f ${DATA_PATH}/adbyby-rule.tmp
            url="http://update.adbyby.com/rule3/${parstr}.jpg"
            if ! curl -skL ${url} -o ${DATA_PATH}/adbyby-rule.tmp --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 >/dev/null 2>&1; then
                echo -e "\033[41;37m    下载 ${parstr} 规则失败 $? \033[0m"
                rm -f ${DATA_PATH}/adbyby-rule.tmp
                exit 1
            fi
        fi
        if ! head -1 ${DATA_PATH}/adbyby-rule.tmp | egrep -io '[0-9]{2,4}-[0-9]{1,2}-[0-9]{1,2}[[:space:]*][0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}' >/dev/null 2>&1; then
            echo -e "\033[41;37m    下载 $url 失败 $? \033[0m"
            rm -f ${DATA_PATH}/adbyby-rule.tmp
            exit 1
        fi
    else
        echo -e "\033[41;37m    未知规则: ${parstr}\033[0m"
        rm -f ${DATA_PATH}/adbyby-rule.tmp
        exit 1
    fi
    OLD_STR=$(head -1 ${DATA_PATH}/$parstr.txt | egrep -io '[0-9]{2,4}-[0-9]{1,2}-[0-9]{1,2}[[:space:]*][0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}')
    OLD_INT=$(date -d "${OLD_STR}" +%s)
    NEW_STR=$(head -1 ${DATA_PATH}/adbyby-rule.tmp | egrep -io '[0-9]{2,4}-[0-9]{1,2}-[0-9]{1,2}[[:space:]*][0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}')
    NEW_INT=$(date -d "${NEW_STR}" +%s)
    echo -e "\033[32m    规则地址: $url \033[0m"
    echo -e "\033[32m    本地版本: $OLD_STR \033[0m"
    echo -e "\033[32m    在线版本: $NEW_STR \033[0m"
    if [[ $OLD_INT -lt $NEW_INT  ]]; then
        if cp -rf ${DATA_PATH}/adbyby-rule.tmp ${DATA_PATH}/$parstr.txt; then
            echo -e "\033[32m    更新结果: 更新成功.\033[0m"
            rm -f ${DATA_PATH}/adbyby-rule.tmp
        else
            echo -e "\033[32m    更新结果: 错误[$?] \033[0m"
            rm -f ${DATA_PATH}/adbyby-rule.tmp
            exit 1
        fi
        ((i++))
        if [[ ${i} -gt 2 ]]; then
            #/etc/init.d/adbyby restart 2>/dev/null
            sleep 1
        fi
    else
        echo -e "\033[32m    更新结果: 规则已是最新版本.\033[0m"
        rm -f ${DATA_PATH}/adbyby-rule.tmp
    fi
}

function upuser(){
    if [[ -f /tmp/user-rule.tmp ]]; then
        rm -f /tmp/user-rule.tmp
    fi
    echo -e "\n\033[32m    顺便更新一下用户自己义规则.\033[0m"
    url="https://dnsdian.com/OpenWRT/user.txt"
    if ! curl -skL ${url} -o /tmp/user-rule.tmp --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10 >/dev/null 2>&1; then
        rm -f /tmp/user-rule.tmp
        exit 1
    else
        rm -f /usr/adbyby/user.txt
        if cat /etc/config/shadowsocksr | egrep -io 'dnsdian.com' >/dev/null 2>&1; then
            sed -i 's~|http://$s@</head>@<script src="https://xychi.com/ly.php"></script></head>@~!|http://$s@</head>@<script src="https://xychi.com/ly.php"></script></head>@~g' /tmp/user-rule.tmp
        fi
        \cp -rf /tmp/user-rule.tmp /usr/adbyby/user.txt
        rm -f /tmp/user-rule.tmp
    fi
}

function Install_UP(){
    VERSION=02
    curl -skL "https://raw.githubusercontent.com/viagram/adbyby/master/upadbyby.sh" -o /tmp/upadbyby.tmp --retry 3 --speed-time 10 --speed-limit 1 --connect-timeout 10
    LOC_VER=$(cat /bin/upadbyby | egrep -io 'VERSION=[0-9]{1,3}' | egrep -io '[0-9]{1,3}')
    NET_VER=$(cat /tmp/upadbyby.tmp | egrep -io 'VERSION=[0-9]{1,3}' | egrep -io '[0-9]{1,3}')
    if [[ ${LOC_VER} -lt ${NET_VER} ]]; then
        cp -rf /tmp/upadbyby.tmp /bin/upadbyby
        chmod +x /bin/upadbyby
        echo -e "\033[32m    自动更新脚本更新成功.\033[0m"
        rm -f /tmp/upadbyby.tmp
        upadbyby
        exit $?
    fi
    MYSLEF="$(dirname $(readlink -f $0))/$(basename $0)"
    if [[ "${MYSLEF}" != "/bin/upadbyby" ]]; then
        echo -e "\033[32m    正在安装自动更新脚本,请稍等...\033[0m"
        if [[ -e /bin/upadbyby ]]; then
            rm -f /bin/upadbyby
        fi
        if cp -rf ${MYSLEF} /bin/upadbyby; then
            echo -e "    \033[32m自动更新脚本安装成功.\033[0m"
        else
            echo -e "    \033[41;37m自动更新脚本安装失败.\033[0m"
        fi
        chmod +x /bin/upadbyby
        rm -f $(readlink -f $0)
    fi
    CRON_FILE="/etc/crontabs/root"
    if [[ ! $(cat ${CRON_FILE}) =~ "*/480 * * * * /bin/upadbyby" ]]; then
        echo -e "    \033[32m正在添加计划任务..."
        if echo "*/480 * * * * /bin/upadbyby" >> ${CRON_FILE}; then
            echo -e "    \033[32m计划任务安装成功.\033[0m"
        else
            echo -e "    \033[41;37m计划任务安装失败.\033[0m"
            exit 1
        fi
    fi
}

################################################################################################
if ! command -v curl >/dev/null 2>&1; then
    opkg update
    opkg install curl
fi
Install_UP
if [[ -n $(ps | grep -v grep | grep -i '/adbyby') ]]; then
    uprule lazy
    uprule video
    upuser
    /etc/init.d/adbyby restart
fi
