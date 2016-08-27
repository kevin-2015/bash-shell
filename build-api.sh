#!/bin/bash
#author: microc

echo "程序初始化..."

# 程序初始化配置
app_base=/data/project/
app_name=(tx-pb tx-service-api tx-app-api)
deploy_base=/data/apps/
config_base=/data/setting/
# branch_name=`get_branch_name`
if [ $# -gt 0 ]; then
    branch_name=$1
else
    branch_name=`echo ${0#*_} | cut -d "." -f1`
fi

# 编译发布项目
for name in ${app_name[@]};
do
    echo -e "\n"
    cd $app_base$name
    echo "[$name] 获取最新代码"
    git checkout $branch_name
    git pull origin $branch_name
    echo "[$name] 编译项目..."
    mvn clean install -Dmaven.test.skip=true
    if [ $? = 0 ]; then
        echo "[$name] 项目编译完成"
    else
        echo "[$name] 编译项目失败"
        exit 1;
    fi
    target_file=$app_base$name/target/$name
    if [ -e $target_file.jar ]; then
        # echo "非WEB项目: $name"
	continue
    fi
    if [ -e $target_file.war ]; then
        if [ ! -e $deploy_base$name ]; then
	    echo "[$name] 创建发布目录"
            mkdir -p $deploy_base$name
	else
	    echo "[$name] 备份项目: $name-`date +%y%m%d%H%M%S`.tar.gz"
	    cd $deploy_base
	    tar -zcf $deploy_base$name-`date +%y%m%d%H%M%S`.tar.gz $name
	    echo "[$name] 清理发布目录"
	    rm -rf $deploy_base$name/*
	fi
	echo "[$name] 发布项目..."
        unzip $target_file.war -d $deploy_base$name 1>/dev/null 2>&1
	echo "[$name] 修改配置..."
        rm -rf $deploy_base$name/WEB-INF/classes/setting.properties
	cp -f $config_base$name.properties $deploy_base$name/WEB-INF/classes/setting.properties
	echo "[$name] 项目发布完成"
    else
        echo "[$name] 程序异常, 未找到编译生成文件"
	exit
    fi
done

echo "Done."
