function send_tx {
   utxos=$(~/navcoin-core/src/navcoin-cli -testnet listunspent 1|jq -r ".[]|.address"|tr "\n" " ");
   arrayutxos=($utxos);
   from=${arrayutxos[$RANDOM % ${#arrayutxos[@]} ]}
   groupings=$(~/navcoin-core/src/navcoin-cli -testnet listaddressgroupings|jq -r ".[]|.[]|.[0]"|tr "\n" " ")
   arraygroupings=($groupings)
   to=${arraygroupings[$RANDOM % ${#arraygroupings[@]} ]}
   dice=$(bc <<< "$RANDOM % 10")
   if [ $dice -eq 1 ];
   then
      to=$(~/navcoin-core/src/navcoin-cli -testnet getnewaddress)
   fi
   fee=0.001
   utxos=$(~/navcoin-core/src/navcoin-cli -testnet listunspent 1 99999999 [\"$from\"]|jq -c "[.[] | {txid: .txid,vout: .vout}]")
   amount=$(~/navcoin-core/src/navcoin-cli -testnet listunspent 1 99999999 [\"$from\"]|jq "[.[] | .amount]" | awk '{sum+=$0} END{printf "%.8f", sum}')
   change=$(bc <<< "$RANDOM % ($amount - 1)")
   rawtx=$(~/navcoin-core/src/navcoin-cli -testnet createrawtransaction $utxos "{\"$to\":$(bc <<< "$amount - $fee - $change"),\"$from\":$change}")
   sigtx=$(~/navcoin-core/src/navcoin-cli -testnet signrawtransaction $rawtx|jq -r .hex)
   ~/navcoin-core/src/navcoin-cli -testnet sendrawtransaction $sigtx 
}

function create_proposal {
   python3 random_sentence.py
   randomSentence=$(cat random_sentence.txt)
   amount=$(bc <<< "$RANDOM % 100000")
   deadline=$(bc <<< "$RANDOM % 10000000")
   address=$(~/navcoin-core/src/navcoin-cli -testnet getnewaddress)
   ~/navcoin-core/src/navcoin-cli -testnet createproposal $address $amount $deadline "$randomSentence"
}

function create_payment_request {
   python3 random_sentence.py
   randomSentence=$(cat random_sentence.txt)
   proposals=$(~/navcoin-core/src/navcoin-cli -testnet listproposals accepted|jq -r ".[]|.hash"|tr "\n" " ")
   arrayproposals=$($proposals)
   randomproposal=${ arrayproposals[ $RANDOM % ${#arrayproposals[@]} ]}
   proposaljson=$(~/navcoin-core/src/navcoin-cli -testnet getproposal $randomproposal)
   maxAmount=$(echo $proposalJson|jq -r ".notPaidYet")
   requestAmount=$(bc <<< "$RANDOM % $maxAmount")
   ~/navcoin-core/src/navcoin-cli -testnet createpaymentrequest $randomproposal $requestAmount "$randomSentence"
}

dice=$(bc <<< "$RANDOM % 100")

if (( $dice < 50 ));
then
   send_tx
elif [ $dice -eq 65 ];
then
   create_proposal
elif [ $dice -gt 95 ];
then
   create_payment_request
fi
