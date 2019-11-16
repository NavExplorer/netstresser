#!/bin/sh

mkdir -p ~/.votes
proposals=$(~/navcoin-core/src/navcoin-cli -testnet listproposals|jq -r ".[]|.hash")
for i in $proposals;
do
   if [ ! -e "$HOME/.votes/${i}" ];
   then
      dice=$(bc <<< "$RANDOM % 2")
      if [ $dice -eq 1 ];
      then
         ~/navcoin-core/src/navcoin-cli -testnet proposalvote $i yes && echo yes > ~/.votes/$i
      else
         ~/navcoin-core/src/navcoin-cli -testnet proposalvote $i no && echo no > ~/.votes/$i
      fi
   fi
done

prequests=$(~/navcoin-core/src/navcoin-cli -testnet listproposals|jq -r ".[]|.paymentRequests|.hash?")

for i in $prequests;
do
   if [ ! -e "$HOME/.votes/${i}" ];
   then
      dice=$(bc <<< "$RANDOM % 2")
      if [ $dice -eq 1 ];
      then
         ~/navcoin-core/src/navcoin-cli -testnet paymentrequestvote $i yes && echo yes > ~/.votes/$i
      else
         ~/navcoin-core/src/navcoin-cli -testnet paymentrequestvote $i no && echo no > ~/.votes/$i
      fi
   fi
done
