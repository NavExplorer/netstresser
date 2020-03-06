# netstresser
NavCoin network stresser

Run new_qt.sh to create a new qt wallet (need to configure devnet or testnet).

Run new_daemon.sh to delete the ~/.navcoin4/devnet folder and create a navcoind instance (need to configure devnet or testnet).

Run stressor_dao_testnet.sh to create random propoasls and consutlations. Configuration is needed to make it work.

Needs:

```
sudo apt install bc jq
pip3 install tensorflow
pip3 install textgenrnn
```
