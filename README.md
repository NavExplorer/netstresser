# netstresser
NavCoin network stresser

Run `bash dice.sh` to trigger a random action (create transaction, create proposal, create payment request or nothing). Payment Request creation can turn into a `nothing` action if the randomly chosen proposal is not owned by the node, hence the higher probability assigned in the code.

Run `bash voter_dice.sh` to assign a random vote for all the entries without one.

Needs:

```
sudo apt install bc jq
pip3 install tensorflow
pip3 install textgenrnn
```
