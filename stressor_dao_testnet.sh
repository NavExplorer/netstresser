#!/bin/bash 
#PS4='Line ${LINENO}: '
navpath=/home/cluster/aguycalled/navcoin-core/src
seconds=1200
sleep_time=10

bool_proposal=1
bool_proposal_vote=1
bool_consultation=1
bool_consultation_vote=1
###Chances of entering the functions when stressing in % (50 = 50%) integers only
chances_create_proposal=30
chances_create_payment_request=50
chances_create_range_consultation=20
chances_create_answer_consultation=20
chances_create_no_answer_consultation=20
chances_create_consensus_consultation=20
chances_add_answer_consultation=50


function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

function dice_proposal {
	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_create_proposal ];
	then
		python3 random_sentence.py 2> /dev/null
		random_sentence=$(cat random_sentence.txt)
		amount=$(bc <<< "$RANDOM % 1000")
		deadline=$(bc <<< "$RANDOM % 1000000")
		address=$($navpath/navcoin-cli -devnet ${array_stressing_nodes[$node]} getnewaddress)
		$navpath/navcoin-cli -devnet createproposal $address $amount $deadline "$random_sentence"
	fi

	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_create_payment_request ];
	then
		proposals=($($navpath/navcoin-cli -devnet listproposals mine|jq -r ".[]|.hash"|tr "\n" " "))
		array_proposals=($proposals)
		for p in ${array_proposals[@]}
		do
			proposal=$($navpath/navcoin-cli -devnet getproposal $p)
			address=$(echo $proposal|jq -r .paymentAddress)
			status=$(echo $proposal|jq -r .status)
			if [[ "$status" == "accepted" ]];
			then
				python3 random_sentence.py 2> /dev/null
				random_sentence=$(cat random_sentence.txt)
				maxAmount=$(echo $proposal|jq -r .notRequestedYet)
				if (( $(echo "$maxAmount > 0"|bc -l) ));
				then
					hash=$(echo $proposal|jq -r .hash)
					requestAmount=$(bc <<< "$RANDOM % $maxAmount")
					$navpath/navcoin-cli -devnet createpaymentrequest $hash $requestAmount "$random_sentence"
				fi
			fi
		done
	fi
}

function dice_consultation {

	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_create_no_answer_consultation ];
	then
		python3 random_sentence.py 2> /dev/null
		random_sentence=$(cat random_sentence.txt)
		random_max_answer=$( shuf -i 2-10 -n 1 )
		$navpath/navcoin-cli -devnet createconsultation "$random_sentence" $random_max_answer 2> /dev/null
	fi

	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_create_answer_consultation ];
	then 
		python3 random_sentence.py 2> /dev/null
		random_sentence=$(cat random_sentence.txt)
		random_max_answer=$( shuf -i 2-10 -n 1 )
		user_propose_new_answer=$( bc <<< "$RANDOM%2" )
		if [ "$user_propose_new_answer" == 1 ];
		then
			bool_user_propose_new_answer=true
		else
			bool_user_propose_new_answer=false
		fi
		for i in $(seq 0 1 $( bc <<< "$random_max_answer-1" ));
		do
			python3 random_sentence.py 2> /dev/null
			array_random_answer[$i]=$(cat random_sentence.txt)
		done
		consultation_answer=$(join_by '\",\"' "${array_random_answer[@]}")
		eval "\$navpath/navcoin-cli -devnet createconsultationwithanswers \"$random_sentence\" \"[\\\"$consultation_answer\\\"]\" $random_max_answer $bool_user_propose_new_answer" 2> /dev/null
	fi

	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_create_range_consultation ];
	then 
		python3 random_sentence.py 2> /dev/null
		random_sentence=$(cat random_sentence.txt)
		random_upper_limit=$RANDOM
		random_lower_limit=$( shuf -i 0-$random_upper_limit -n 1)
		$navpath/navcoin-cli -devnet createconsultation "$random_sentence" $random_lower_limit $random_upper_limit true 2> /dev/null
	fi


	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_create_consensus_consultation ];
	then
		consensus=$( bc <<< "$RANDOM % 24" )
		case $consensus in
			"0")
				value=$( shuf -i 5-20 -n 1)
				;;
			"1" | "2" | "19" )
				value=$(echo "$( shuf -i 15-500 -n 1)0")
				;;
			"3" | "4" | "5" | "6" | "13" | "18")
				value=$( shuf -i 0-10 -n 1)
				;;
			"7" | "8" | "12" | "17" | "21" | "22" | "23" )
				value=$(echo "$( shuf -i 1-1000 -n 1)00000000")
				;;
			"9" | "10" | "11" | "14" | "15" | "16" | "20")
				value=$(echo "$( shuf -i 1-100 -n 1)00")
				;;
			*)
				;;
		esac
		$navpath/navcoin-cli -devnet proposeconsensuschange $consensus $value 2> /dev/null
	fi

	dice=$(bc <<< "$RANDOM % 100")

	if [ $dice -lt $chances_add_answer_consultation ];
	then
		consultations=($($navpath/navcoin-cli -devnet listconsultations | jq -r ".[]|.hash"|tr "\n" " "))
		for c in ${consultations[@]}
		do
			consultation=$($navpath/navcoin-cli -devnet getconsultation $c)
			hash=$(echo $consultation|jq -r .hash)
			status=$(echo $consultation|jq -r .status)
			version=$(echo $consultation | jq -r .version)
			question=$(echo $consultation | jq -r .question | tr -d "\"" | cut -c 23- )
			if [[ "$status" == "waiting for support" ]] || [[ "$status" == "waiting for support, waiting for having enough supported answers" ]];
			then
				if [[ "$version" == 13 ]];
				then
					match_found=0
					for i in $(seq 0 1 23);
					do
						if [[ "$question" == "${consensus_parameter_name[$i]}" ]];
						then
							case $i in
								"0")
									value=$( shuf -i 5-20 -n 1)
									;;
								"1" | "2" | "19" )
									value=$(echo "$( shuf -i 15-500 -n 1)0")
									;;
								"3" | "4" | "5" | "6" | "13" | "18")
									value=$( shuf -i 0-10 -n 1)
									;;
								"7" | "8" | "12" | "17" | "21" | "22" | "23" )
									value=$(echo "$( shuf -i 1-1000 -n 1)00000000")
									;;
								"9" | "10" | "11" | "14" | "15" | "16" | "20")
									value=$(echo "$( shuf -i 1-100 -n 1)00")
									;;
								*)
									;;
							esac
							$navpath/navcoin-cli -devnet proposeanswer $hash $consensus $value 2> /dev/null
							match_found=1
						fi
					done
					if [[ "$match_found" == 0 ]];
					then
						echo "something wrong, none matched the consensus parameter"
					fi
				elif [[ "$version" == 5 ]];
				then
					python3 random_sentence.py 2> /dev/null
					random_sentence=$(cat random_sentence.txt)
					$navpath/navcoin-cli -devnet proposeanswer $hash "$random_sentence" 2> /dev/null
				fi
			fi
		done
	fi

}

function voter_dice_proposal {

	proposals=($($navpath/navcoin-cli -devnet  proposalvotelist|jq -r ".null[]|.hash"))
	for i in ${proposals[@]};
	do
		dice=$(bc <<< "$RANDOM % 2")
		if [ $dice -eq 1 ];
		then
			$navpath/navcoin-cli -devnet proposalvote $i yes 2> /dev/null
		else
			$navpath/navcoin-cli -devnet proposalvote $i no 2> /dev/null
		fi
	done

	prequests=($($navpath/navcoin-cli -devnet paymentrequestvotelist|jq -r ".null[]|.hash?"))

	for i in ${prequests[@]};
	do
		dice=$(bc <<< "$RANDOM % 2")
		if [ $dice -eq 1 ];
		then
			$navpath/navcoin-cli -devnet paymentrequestvote $i yes 2> /dev/null
		else
			$navpath/navcoin-cli -devnet paymentrequestvote $i no 2> /dev/null
		fi
	done
}

function voter_dice_consultation {

	consultations=($($navpath/navcoin-cli -devnet listconsultations|jq -r ".[]|.hash"|tr "\n" " "))
	all_consultation_answers=($($navpath/navcoin-cli -devnet listconsultations|jq -r ".[].answers[]|.hash"|tr "\n" " "))
	for i in ${consultations[@]};
	do
		consultation=$($navpath/navcoin-cli -devnet getconsultation $i)
		version=$(echo $consultation | jq -r .version)
		status=$(echo $consultation | jq -r .status)
		if [[ "$status" == "waiting for support" ]] || [[ "$status" == "waiting for support, waiting for having enough supported answers" ]];
		then
			if [ "$version" == 3 ] || [ "$version" == 7 ];
			then
				dice=$(bc <<< "$RANDOM % 2")
				if [ $dice -eq 1 ];
				then
					$navpath/navcoin-cli -devnet support $i 2> /dev/null
				else
					$navpath/navcoin-cli -devnet support $i false 2> /dev/null
				fi
			else
				for k in ${all_consultation_answers[@]};
				do
					dice=$(bc <<< "$RANDOM % 1")
					if [ $dice -eq 0 ];
					then
						$navpath/navcoin-cli -devnet support $k 2> /dev/null
					else
						$navpath/navcoin-cli -devnet support $k false 2> /dev/null
					fi
				done
			fi

		elif [[ "$status" == "voting started" ]];
		then
			if [ "$version" == 3 ] || [ "$version" == 7 ];
			then
				dice=$(bc <<< "$RANDOM % 2")
				if [ $dice -eq 1 ];
				then
					$navpath/navcoin-cli -devnet consultationvote $i $RANDOM 2> /dev/null
				fi
			else
				$navpath/navcoin-cli -devnet consultationvote $i remove
				consultation_answers=($($navpath/navcoin-cli -devnet getconsultation $i| jq -r ".answers[].hash" | tr "\n" " "))
				for k in ${consultation_answers[@]};
				do
					$navpath/navcoin-cli -devnet consultationvote $k remove 2> /dev/null
				done
				
				if [ "$version" == 13 ];
				then
					dice=$(bc <<< "$RANDOM % 5")
					if [ $dice -eq 1 ];
					then
						$navpath/navcoin-cli -devnet consultationvote $i abs 2> /dev/null
					else
						yes_answer=$( bc <<< "$RANDOM % ${#consultation_answers[@]}" )
						$navpath/navcoin-cli -devnet consultationvote ${consultation_answers[$yes_answer]} yes 2> /dev/null
					fi
				else
					dice=$(bc <<< "$RANDOM % 5")
					if [ $dice -eq 1 ];
					then
						$navpath/navcoin-cli -devnet consultationvote $i abs 2> /dev/null
					else
						for k in ${consultation_answers[@]};
						do
							dice=$(bc <<< "$RANDOM % 2")
							if [ $dice -eq 1 ];
							then
								$navpath/navcoin-cli -devnet consultationvote $k yes 2> /dev/null
							fi
						done
					fi
				fi
			fi

		fi

	done
}

function stress {
	
	time=$(bc <<< $(date +%s)+$1)
	while [ $time -gt $(date +%s) ]
	do
		if [ "$bool_proposal" == 1 ];
		then
			dice_proposal
		fi
		if [ "$bool_proposal_vote" == 1 ];
		then
			voter_dice_proposal
		fi
		if [ "$bool_consultation" == 1 ];
		then
			dice_consultation
		fi
		if [ "$bool_consultation_vote" == 1 ];
		then
			voter_dice_consultation
		fi
		sleep $sleep_time
	done
	donation=$(bc <<< "$RANDOM % 1000")
	$navpath/navcoin-cli -devnet donatefund $donation 2> /dev/null
}

echo Stressing for $seconds seconds...
stress $seconds

