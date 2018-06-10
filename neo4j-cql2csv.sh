#!/bin/bash

# 設定
export LC_ALL=en_US.UTF-8
readonly DIR_CURRENT=`dirname $0`
readonly SCRIPT_DIR="`cd $DIR_CURRENT; pwd`/"
STATUS=0
FILE_DEL=0
PROGRESS=0
ROW=0
COUNT=0
ARR_NODES_LABEL=()
ARR_EDGES_LABEL=()


# 引数解析
usage_exit() {
    echo "Usage: `basename $0` [cql file | zip file]" 1>&2
    echo "Options:" 1>&2
    echo " -p    Display of progress" 1>&2
    echo " -x    Xtrace" 1>&2
    echo " -h    Display this help and exit" 1>&2
    exit 1
}

while getopts pxh OPT; do
    case $OPT in
        p)  PROGRESS=1
            ;;
        x)  set -xv
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done
shift $((OPTIND - 1))


# ファイルチェック
if [ $# -ne 1 ]; then
    echo -e "Please specify the file\n"
    usage_exit
fi

if [ ! -f $1 ]; then
    echo -e "Please specify the file\n"
    usage_exit
fi

FILE=$1
if [ "gzip" = `file -b ${FILE} | awk -F' ' '{print $1}'` ]; then
    # gunzip $FILE
    FILE_TMP=`echo $FILE | sed 's/\.[^\.]*$//'`
    gunzip -c $FILE > $FILE_TMP
    FILE=$FILE_TMP
    FILE_DEL=1
    unset FILE_TMP
fi


if [ $PROGRESS -eq 1 ]; then
    ROW=`wc -l $FILE | awk -F' ' '{print $1}'`
fi


# 本処理
while read LINE; do
    if [[ ! "$LINE" =~ ^create ]]; then
        if [ $PROGRESS -eq 1 ]; then
            echo "( $(( ++COUNT )) / ${ROW})"
        fi
        continue
    fi
    if [ $PROGRESS -eq 1 ]; then
        echo -e "( $(( ++COUNT )) / ${ROW})\t${LINE}"
    fi

    LABEL=`echo $LINE | awk -F'\`' '{print $2}'`
    if [[ "$LINE" =~ -\[: ]]; then
        # リレーションシップ
        PUT_FILE="edges_${LABEL}.csv"
        if [ 0 -eq `echo ${ARR_EDGES_LABEL[@]} | grep -c ${LABEL}` ]; then
            ARR_EDGES_LABEL+=($LABEL)
            echo ":START_ID,:END_ID,:TYPE" > $PUT_FILE
        fi

        echo -n `echo $LINE | sed -e "s/^.*(\(.*\)).*(\(.*\))/\1,\2/g"` >> $PUT_FILE
        echo ",${LABEL}" >> $PUT_FILE
    else
        # ノード
        PUT_FILE="node_${LABEL}.csv"
        VALUE=($(echo $LINE | sed -e "s/^.*{\(.*\)})\$/\1/g" | sed -e "s/\`//g" | tr -s ',' ' '))
        if [ 0 -eq `echo ${ARR_NODES_LABEL[@]} | grep -c ${LABEL}` ]; then
            ARR_NODES_LABEL+=($LABEL)
            TEXT=":ID,"
            for ITEM in ${VALUE[@]}; do
                ITEM=(`echo ${ITEM} | tr -s ':', ' '`)
                TEXT+=${ITEM[0]}
                
                expr "${ITEM[1]}" + 1 >/dev/null 2>&1
                if [ $? -lt 2 ]; then
                    TEXT+=":int"
                elif [ ${ITEM[1]} = "true" -o ${ITEM[1]} = "false" ]; then
                    TEXT+=":boolean"
                fi

                TEXT+=","
            done
            TEXT+=":LABEL"
            echo $TEXT > $PUT_FILE
        fi

        ID=`echo $LINE | sed -e "s/^create (\([^:]*\):.*\$/\1/g"`
        echo -n "${ID}," >> $PUT_FILE
        for ITEM in ${VALUE[@]}; do
            ITEM=(`echo ${ITEM} | tr -s ':', ' '`)
            echo -n "${ITEM[1]}," >> $PUT_FILE
        done
        echo $LABEL >> $PUT_FILE
    fi
done < $FILE

STATUS=1


# 終了・中断処理
trap "
if [ $FILE_DEL -eq 1 ]; then
    rm -fr $FILE
fi

if [ $STATUS -eq 1 ]; then
    done_print
else
    echo 'fail.'
    rm -fr node_*.csv edges_*.csv
fi
" 0


done_print() {
    echo "done."
    echo -n "use command: neo4j-import --into $NEO4J_HOME/data/databases/[dbname]"
    
    for ITEM in ${ARR_NODES_LABEL[@]}; do
        echo -n " --nodes ${SCRIPT_DIR}node_${ITEM}.csv"
    done

    for ITEM in ${ARR_EDGES_LABEL[@]}; do
        echo -n " --relationships ${SCRIPT_DIR}edges_${ITEM}.csv"
    done

    echo ''
}