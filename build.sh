#!/bin/bash

set -e
CWD=`pwd`
srcDir="./vendor"

while getopts "hd:p:e:t:f:" OPT; do
    case $OPT in
        p)
            PACKAGE="$OPTARG";;
        d)
            DENPEND="$OPTARG";;
        e)
            EXCLUDE="$OPTARG";;
        t)
            IMAGE="$OPTARG";;
        f)
            FROM="$OPTARG";;
        ?|h)
            echo "Usage: ./build.sh [OPTTIONS]
            -d get the depend packages packages by the point packages
            -p point the golang packages
            -e exclude golang packages
            -t dokcer build image target"
            ;;
    esac
done

#env init
PATH=$PATH:$GOPATH/bin
if ! type govendor; then
    go get -u github.com/kardianos/govendor
fi

#run
allPaths=()
for p in ${DENPEND[@]}; do
    for d in $GOPATH/src/$p; do
        allPaths+=($d)
    done
done

allPkgs=()
for dir in ${allPaths[@]}; do
    cd $dir
    list=`govendor list | awk '{print $2}'`
    for pkg in ${list[@]}; do
        [ ! -d $GOPATH/src/$pkg ] && go get $pkg
        rootPkg=`echo $pkg | grep -o '^[0-9a-zA-Z\.\_-]\+/[0-9a-zA-Z\.\_-]\+/\?[0-9a-zA-Z\.\_-]\+\?'`
        allPkgs+=($rootPkg)
    done
done

for p in ${PACKAGE[@]}; do
    for d in $GOPATH/src/$p; do
        pkg=${d#"$GOPATH/src/"}
        allPkgs+=($pkg)
    done
done
pkgSet=`echo ${allPkgs[@]} | awk 'BEGIN{RS=" "} {if (!keys[$1]) print $1; keys[$1] = 1;}'`

cd $CWD
[ -d $srcDir ] && rm -rf $srcDir
mkdir $srcDir
for pkg in ${pkgSet[@]}; do
    if [ ! -z $EXCLUDE ]; then
        hit=`echo $pkg | grep -c $EXCLUDE || echo 0`
        if [ "$hit" == "1" ]; then
            continue
        fi 
    fi

    echo $pkg
    from=$GOPATH/src/$pkg
    to=`dirname $srcDir/$pkg`
    mkdir -p $to
    # echo "copy from $from to $to"
    cp -rf $from $to
done

#docker build
cd $CWD
[ -z $FROM ] && cat Dockerfile > build.Dockerfile || sed "1s#^FROM.*#FROM $FROM#g" Dockerfile > build.Dockerfile
docker build -t $IMAGE . -f build.Dockerfile