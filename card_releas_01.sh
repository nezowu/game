#!/usr/bin/env bash
IP=$2
prot="\x6e\x65\x7a\x61\x62\x75\x64\x6b\x61\x40\x6c\x69\x6e\x75\x78\x69\x6d\x2e\x72\x75\x0a"
black_card='\U1F0A0'
declare -a onestaf
declare -a twostaf
declare -a battlestaf
declare -a trashstaf
declare -a shuf_card
switch(){
	if [[ $flag == 0 ]]; then
		STATUSSTR="Ход партнера"
		flag=1
	else
		STATUSSTR="Ваш ход"
		flag=0
fi
}
reader(){
	echo ${onestaf[@]} >&${COPROC[1]}
	echo ${twostaf[@]} >&${COPROC[1]}
	echo ${battlestaf[@]} >&${COPROC[1]}
	echo ${trashstaf[@]} >&${COPROC[1]}
	echo ${shuf_card[@]} >&${COPROC[1]}
}
reader1(){
	read -u ${COPROC[0]} -a twostaf
	read -u ${COPROC[0]} -a onestaf
	read -u ${COPROC[0]} -a battlestaf
	read -u ${COPROC[0]} -a trashstaf
	read -u ${COPROC[0]} -a shuf_card
}
razdacha(){
	local p=0
	local s=0
	for ((i=35; i>23; i--)); do
		if [[ $[ $i%2 ] == 0 ]]; then
			onestaf[p]=${shuf_card[i]}
			((p+=1))
			unset shuf_card[i]
		else
			twostaf[s]=${shuf_card[i]}
			((s+=1))
			unset shuf_card[i]
		fi
	done
unset i
}
printColor(){
	for tin in $@; do
		if [[ $tin -gt 127150 && $tin -lt 127185 ]]; then
			tput setaf 1
			printf '%b ' "\U$(bc<<<"obase=16;$tin")"
			tput sgr0
		else
			printf '%b ' "\U$(bc<<<"obase=16;$tin")"
		fi
	done
}
printHead(){
	tput cup 1 15
	tput el
	if [[ ${#battlestaf[@]} == 10 ]]; then
		printf '%s' "Сдача"
	else
		printf '%s' "$STATUSSTR"
	fi
	tput cup 2 1
	tput el
	printColor ${shuf_card[@]:0:1}
	if [[ ${#shuf_card[@]} -gt 1 ]]; then
		tput setaf 4
		printf '%b' "$black_card"
		tput sgr0
	fi
	tput cup 6 48
	tput el
	if [[ ${#trashstaf} -gt 0 ]]; then
		tput setaf 4
		printf '%b' "$black_card"
		tput sgr0
	fi
	tput cup 10 15
	tput el
	if [[ ${#battlestaf[@]} -gt 0 ]]; then
		printColor ${battlestaf[@]}
	fi
	tput cup 14 1
	tput el
	printColor ${onestaf[@]}
	tput cup 16 30
	tput el
	for ((i=0; i<${#twostaf[@]}; i++)); do
		tput setaf 4
		printf '%b ' "$black_card"
	done
	tput sgr0
}

if [[ $IP ]]; then
	coproc nc -w 5 $1 $2
	flag=$((RANDOM%2))
	echo "$flag" >&${COPROC[1]}
	read -u ${COPROC[0]} flagek
else
	coproc nc -l -p $1
	read -u ${COPROC[0]} flagek
	flag=$(((flagek+1)%2))
	echo "$flag" >&${COPROC[1]}
fi
[[ $flagek && $((flag+flagek)) == 1 ]] || exit
while true; do	
if [[ $flag == 0 ]]; then
	STATUSSTR="Ваш ход"
	number_min=$(bc<<<"ibase=16;1F0A1")
	number_min1=$(bc<<<"ibase=16;1F0A6")
	number_min2=$(bc<<<"ibase=16;1F0AD")
	#number_min=$(printf '%d' '0X1F0A7')
	#number_min="$(printf '%b' '\U1F0A1')"
	number_max1=$(bc<<<"ibase=16;1F0AB")
	number_max2=$(bc<<<"ibase=16;1F0AE")
	##Запишим набор одной масти в асоциативный массив
	z=1
	declare -A monst
	while read monst["num$z"]; do
		#monst[num$z]
		#echo ${monst["num$z"]}
		((z+=1))
	done <<<"$number_min
	$(seq $number_min1 $number_max1)
	$(seq $number_min2 $number_max2)" 
	unset monst["num$z"]
	##Создадим полный набор одной колоды и запишем в массив
	declare -a arrvar
	a=0
	for ((i=0; i<4; i++)); do
		for y in ${!monst[@]}; do
			arrvar[$a]=${monst[$y]}
			((a+=1))
			((monst[$y]+=16))
		done
	done
	##Перемешаем колоду
	s=0
	for p in $(shuf -i 0-35); do
		shuf_card[p]=${arrvar[@]:s:1}
		((s+=1))
	done
	##раздаем карты в 2 поля(массива) но предусмотренно еще два "бой" и "полебоя"
	razdacha
	echo ${onestaf[@]} >&${COPROC[1]}
	echo ${twostaf[@]} >&${COPROC[1]}
	echo ${shuf_card[@]} >&${COPROC[1]}
else
	STATUSSTR="Ход партнера"
	read -u ${COPROC[0]} -a twostaf
	read -u ${COPROC[0]} -a onestaf
	read -u ${COPROC[0]} -a shuf_card
fi

tput civis
stty -icanon
tput clear
printHead
while true; do  #главный цикл "движок"
	trap 'break' 2
	if [[ $flag == 1 ]]; then
		echo -en "\e[?9l"
		read -u ${COPROC[0]} FLAG
		if [[ $FLAG == 0 ]]; then
			twostaf_back=(${twostaf[@]})
			battlestaf_back=(${battlestaf[@]})
			read -u ${COPROC[0]} -a twostaf
			if [[ ${twostaf[@]} == ${onestaf_back[@]} ]]; then
				onestaf=(${twostaf[@]})
				twostaf=(${twostaf_back[@]})
			fi
			read -u ${COPROC[0]} -a battlestaf
		elif [[ $FLAG == 1 ]]; then
			:
		elif [[ $FLAG == 2 ]]; then
			:
		elif [[ $FLAG == 3 ]]; then
			if [[  ${#battlestaf[@]} == 10 ]]; then
				reader1
			else
				reader1
				switch
			fi
		fi
	elif [[ $flag == 0 && ${#battlestaf[@]} != 10 ]] && [[ $FLAG == 1 ]]; then #бита
		tput cup 1 15
		tput el
		printf '%s' "Бита"
		sleep 1
		trashstaf+=(${battlestaf[@]})
		battlestaf=()
		y=$((6-${#onestaf[@]}))
		if [[ ${#shuf_card[@]} -ge $y ]]; then
			z=$y
		else
			z=${#shuf_card[@]}
		fi
		lim=$((${#shuf_card[@]}-z))
		onestaf+=(${shuf_card[@]:lim})
		for i in $(seq $z); do
			unset shuf_card[lim]
			((lim++))
		done
		y=$((6-${#twostaf[@]}))
		if [[ ${#shuf_card[@]} -ge $y ]]; then
			z=$y
		else
			z=${#shuf_card[@]}
		fi
		lim=$((${#shuf_card[@]}-z))
		twostaf+=(${shuf_card[@]:lim})
		for i in $(seq $z); do
			unset shuf_card[lim]
			((lim++))
		done
		echo "3" >&${COPROC[1]}
		reader
		FLAG=0
		switch
	elif [[ $flag == 0 && ${#battlestaf[@]} != 10 ]] && [[ $FLAG == 2 ]]; then #забрал
		tput cup 1 15
		tput el
		printf '%s' "Забрал"
		sleep 1
		twostaf+=(${battlestaf[@]})
		battlestaf=()
		y=$((6-${#onestaf[@]}))
		if [[ ${#shuf_card[@]} -ge $y ]]; then
			z=$y
		else
			z=${#shuf_card[@]}
		fi
		lim=$((${#shuf_card[@]}-z))
		onestaf+=(${shuf_card[@]:lim})
		for i in $(seq $z); do
			unset shuf_card[lim]
			((lim++))
		done
		echo "3" >&${COPROC[1]}
		reader
		FLAG=0
		switch
	elif [[ $flag == 0 && ${#battlestaf[@]} == 10 ]] && [[ $FLAG == 0 ]]; then
		sleep 1
		trashstaf+=(${battlestaf[@]})
		battlestaf=()
		y=$((6-${#onestaf[@]}))
		if [[ ${#shuf_card[@]} -ge $y ]]; then
			z=$y
		else
			z=${#shuf_card[@]}
		fi
		lim=$((${#shuf_card[@]}-z))
		onestaf+=(${shuf_card[@]:lim})
		for i in $(seq $z); do
			unset shuf_card[lim]
			((lim++))
		done
		y=$((6-${#twostaf[@]}))
		if [[ ${#shuf_card[@]} -ge $y ]]; then
			z=$y
		else
			z=${#shuf_card[@]}
		fi
		lim=$((${#shuf_card[@]}-z))
		twostaf+=(${shuf_card[@]:lim})
		for i in $(seq $z); do
			unset shuf_card[lim]
			((lim++))
		done
		echo "3" >&${COPROC[1]}
		reader
	else
		echo -en "\e[?9h"
		read -rsn 6 x
		string="$(hexdump -C <<<$x)" #конвертируем кракозябки в данные из цифр
		CLICK=${string:19:2}
		X=$((16#${string:22:2}))
		Y=$((16#${string:25:3}))
		if [[ $((X%2)) == 0 ]]; then #карта состоит из двух столбцов объединим это 
			ZNAK=$(((X-33)/2))
		else
			ZNAK=$(((X-34)/2))
		fi
		if [[ $CLICK == 21 ]]; then
			echo "0" >&${COPROC[1]}
			echo ${twostaf_back[@]} >&${COPROC[1]}
			echo ${battlestaf_back[@]} >&${COPROC[1]}
			battlestaf=(${battlestaf_back[@]})
			twostaf=(${onestaf_back[@]})
		elif [[ $CLICK == 22 && $Y == 43 ]]; then
			((ZNAK-=7))
			[[ ${battlestaf[ZNAK]} ]] || continue
			if [[ $(( ${#battlestaf[@]} % 2 )) == 0 ]]; then 
				echo "1" >&${COPROC[1]}
			elif [[ $(( ${#battlestaf[@]} % 2 )) == 1 ]]; then
				echo "2" >&${COPROC[1]}
			fi
		else
			[[ $CLICK == 20 && $Y == 47 ]] || continue
			[[ ${onestaf[ZNAK]} ]] || continue
			onestaf_back=(${onestaf[@]})
			battlestaf+=(${onestaf[ZNAK]})
			unset onestaf[ZNAK]
			onestaf_tmp=(${onestaf[@]})
			onestaf=(${onestaf_tmp[@]})
			echo "0" >&${COPROC[1]}
			echo ${onestaf[@]} >&${COPROC[1]}
			echo ${battlestaf[@]} >&${COPROC[1]}
		fi
	fi
	switch
	printHead
	if [[ ${#onestaf[@]} == 0 || ${#twostaf[@]} == 0 ]] && [[ ${#shuf_card[@]} == 0 ]]; then
		tput cup 1 15
		tput el
		if [[ $flag == 0 ]]; then
			tput setaf 1
			printf '%s' "Вы проиграли"
		elif [[ $flag == 1 ]]; then
			tput setaf 2
			printf '%s' "Вы выиграли"
		fi
		tput sgr0
		sleep 3
		break
	fi
done
battlestaf=()
trashstaf=()
echo -en "\e[?9l"
stty icanon
tput clear
declare -l TRANC
if [[ $flag == 1 ]]; then
	echo "Вы выиграли"
else
	echo "Вы проиграли"
fi
sleep 1
read -n 1 -p "Еще партию? [yn]" TRANC
if [[ $TRANC = "y" ]]; then
	continue
else
	break
	echo "До встречи"
fi
sleep 2
done
tput clear
echo -e $prot 
tput cvvis
exit
