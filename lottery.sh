#!/bin/bash

md5 lottery.sh participants.txt | md5

# 总抽奖人数
lucky_total=$1

# 判断总抽奖人数合法性
if  [ ! -n "$lucky_total" ] ;then
  echo "请输入要抽奖的人数, usage: $BASH_SOURCE [num]"
  exit
elif echo "$lucky_total" | grep "[^0-9]";then
  echo "抽奖的人数必须为整数"
  exit
fi

# 参与者们
readonly PARTICIPANTS_FILE='participants.txt'

# 打乱文件行顺序
participants=`awk 'BEGIN{srand()}{b[rand()NR]=$0}END{for(x in b)print b[x]}' $PARTICIPANTS_FILE | grep -vE "^$|^[#;]"`
total_num=`cat $PARTICIPANTS_FILE | grep -vE "^$|^[#;]" | wc -l`

# 判断参与者数合法性
if [ $lucky_total -gt $total_num ];then
  echo "抽奖的人比总人数都多，你在逗我吗"
  exit
fi

# 没有什么卵用的承诺书
read -p "我承诺:保证本次抽奖的公平、公正、公开(y/N) > " agreement

if [ "$agreement" == "Y" -o "$agreement" == "y" ];then
  clear
  echo '正在进入抽奖程序...'
  sleep 1
else
  echo '爱抽抽不爱抽滚'
  exit
fi

# 幸运人儿们
lucky_ones=()
# 当前被抽中的人
lucky_one=-1
# 当前抽奖的轮数
loop_index=1

# 工具函数，判断数组中是否有指定元素
# $1 arr 给定数组
# $2 ele 给定元素
# attention: 数组作为参数传递需要使用 "${arr[*]}"，否则会只传递第一个元素
function include() {
  arr=$1
  ele=$2
  # 如果使用 ${arr[*]} =~ $ele 为部分匹配，例如如果数组中含有 14，那么 4 会为 true
  # 完全匹配
  if echo "${arr[*]}" | grep -w $ele &>/dev/null;then
    return 1
  fi
}

# 绘制 UI
# $1 current_pos 被抽中（高亮）的位置
# $2 speed 速度
function render() {
  current_pos=$1
  speed=$2
  clear
  index=0
  echo -e "  \033[32m进行第 $loop_index 次抽奖...\033[0m \n"
  for name in $participants
  do
    include "${lucky_ones[*]}" $index
    if [ $? -eq 1 ];then
      echo -e "\033[31m√ $name\033[0m"
    elif [ $current_pos = $index ];then
      echo -e "\033[32m→ $name\033[0m"
    else
      echo "  $name"
    fi
    let index++
  done
  sleep $speed
}

# 滚动抽奖
# $1 final_stop_pos 最后停止的地方
function scroll() {
  final_stop_pos=$1
  # 默认多滚两遍
  pre_scroll_times=$[ total_num * 2 ]
  scroll_times=$[ pre_scroll_times + final_stop_pos ]
  for ((i=0; i<=$scroll_times; i++));do
    include "${lucky_ones[*]}" $[i % total_num]
    if [ $? -eq 1 ];then
      continue
    elif [ $i -le $[scroll_times - 10] ];then
      render $[i % total_num] 0.05
    else
      # 倒数 10 个起开始放慢速度，而且越来越慢，直到 1 秒
      speed=`echo "scale=3;1 - 0.095 * ($scroll_times - $i)" | bc`
      render $[i % total_num] `printf "%.2f" $speed`
    fi
  done
  lucky_ones[$loop_index - 1]=$final_stop_pos
  # 最后调用一次 render 以确保被抽中者标红
  render -1 0
  let loop_index++
}

# 抽奖
function create_lucky_one() {
  # 随机数
  random=`echo $((RANDOM % $total_num))`
  # 或许再加上 CPU 使用率和内存使用率使之真正随机

  lucky_one=$random

  include "${lucky_ones[*]}" $lucky_one
  if [ $? -eq 1 ];then
    # 已被抽中过，重新抽一次
    create_lucky_one
  fi
}

# kickoff
for ((lottery_time=0; lottery_time<$lucky_total; lottery_time++));do
  create_lucky_one
  scroll $lucky_one
done

# delete itself, make sure we can't run it twice
rm $BASH_SOURCE
