#!/bin/sh

geth --dev --http --http.addr "0.0.0.0" --http.api "personal,eth,net,web3" --allow-insecure-unlock &
sleep 5
geth --exec 'eth.sendTransaction({from: eth.accounts[0], to: "0x2272F3B46614eAB2Af01Ec6b01d72bB504aC47bf", value: web3.toWei(1, "ether")})' attach http://127.0.0.1:8545
tail -f /dev/null
