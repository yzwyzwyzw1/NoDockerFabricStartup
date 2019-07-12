FABRIC_PATH=github.com/hyperledger/fabric

GOPATH=/home/yzw/GoSpace/gopath

CHANNEL_NAME=mychannel

PROJECT_PATH=github.com/blockchaintest.com/NoDockerFabricStartup

#TLS 测试选择 enable for 开启，disable for 关闭
TLSenable=enable

Enable=enable


.PHONY: bin
bin:
	@cd /home/yzw/GoSpace/gopath/src/$(FABRIC_PATH)/ && make release


.PHONY: cpbin
cpbin:
	@cp /home/yzw/GoSpace/gopath/src/$(FABRIC_PATH)/release/linux-amd64/bin/* ./fixture


# 1.
.PHONY: crypto-config
crypto-config:
	@./fixture/cryptogen generate --config ./fixture/crypto-config.yaml --output ./fixture/crypto-config



FABRIC_CFG_PATH=$(PWD)/fixture

.PHONY: genesis
genesis:
	@echo $(FABRIC_CFG_PATH)
	@mkdir -p ./fixture/channel-artifacts
	@cd ./fixture && ./configtxgen -profile TwoOrgsOrdererGenesis  -outputBlock ./channel-artifacts/genesis.block
	@sleep 1
# 3.
# 不可以取名channel，不知道原因
.PHONY: channelblock 
channelblock:
	@echo $(CHANNEL_NAME)
	@cd ./fixture && ./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID $(CHANNEL_NAME)

# 4.
.PHONY: anchors
anchors:
	@cd ./fixture &&  ./configtxgen  -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $(CHANNEL_NAME) -asOrg Org1MSP
	@cd ./fixture &&  ./configtxgen  -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $(CHANNEL_NAME) -asOrg Org2MSP

# E1.
.PHONY: cleanenv
cleanenv:
	@rm -rf ./fixture/crypto-config
	@rm -f  ./fixture/channel-artifacts/*
	@rm -rf  /var/hyperledger/production

# E2.
.PHONY: createenv
createenv: crypto-config genesis channelblock  anchors



# 5.
.PHONY: ordererstartup
ordererstartup:
	@cd ./fixture && ./orderer start

# 6.
.PHONY: peerstartup
peerstartup:
	@cd ./fixture && ./peer node start
#	@echo "" > ./logs/log_peer.log
#	@cd ./fixture/peer node start >> ./logs/log_peer.log 2>&1 &
	


# 7.
.PHONY: chanagepeer
chanagepeer: export CORE_PEER_LOCALMSPID=Org1MSP
chanagepeer: export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
chanagepeer: export CORE_PEER_MSPCONFIGPATH=$(GOPATH)/src/$(PROJECT_PATH)/fixture/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
chanagepeer: export CORE_PEER_TLS_ROOTCERT_FILE=$(GOPATH)/src/$(PROJECT_PATH)/fixture/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

.PHONY: appchannel
appchannel: chanagepeer
  ifeq ($(TLSenable),$(Enable))
	@echo "able tls"
	@cd ./fixture &&  ./peer channel create -o orderer.example.com:7050 -c $(CHANNEL_NAME) -f ./channel-artifacts/mychannel.tx --tls --cafile $(GOPATH)/src/$(PROJECT_PATH)/fixture/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
	@sleep 3
	@cd ./fixture && mv ./mychannel.block ./channel-artifacts/
	@sleep 1
  else
	@echo "disable tls"
	@cd ./fixture &&  ./peer channel create -o orderer.example.com:7050 -c $(CHANNEL_NAME) -f ./channel-artifacts/mychannel.tx
	@sleep 2
	@cd ./fixture && mv mychannel.block ./channel-artifacts/
  endif
## 我在core.yaml指定了peer节点是peer0.org1.example.com,所以默认是peer0.org1.example.com的，所以可以不设环境变量，为了书写统一，和避免二义性，此处添加创建环境变量的内容
#
#
#
# 8.
.PHONY: joinchannel
joinchannel:
	@cd ./fixture && ./peer channel join -b ./channel-artifacts/mychannel.block

# 9.
.PHONY: updateanchors
updateanchors:
  
  ifeq ($(TLSenable),$(Enable))
	@echo "able tls"
	@cd ./fixture && ./peer channel update -o orderer.example.com:7050 -c $(CHANNEL_NAME) -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile $(GOPATH)/src/$(PROJECT_PATH)/fixture/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  else
	@echo "disable tls"
	@cd ./fixture && ./peer channel update -o orderer.example.com:7050 -c $(CHANNEL_NAME) -f ./channel-artifacts/Org1MSPanchors.tx
  endif

# 10.
.PHONY: installchaincode
installchaincode:
	@cd ./fixture && ./peer chaincode install -n mycc -v 1.0 -p  $(PROJECT_PATH)/chaincode/example02

# 11.
.PHONY: instantiatechaincode
instantiatechaincode:

  ifeq ($(TLSenable),$(Enable))
	@echo "able tls"
	@cd ./fixture && ./peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $(GOPATH)/src/$(PROJECT_PATH)/fixture/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $(CHANNEL_NAME) -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.admin')"
	@sleep 5
  else
	@echo "disable tls"
	@cd ./fixture && ./peer chaincode instantiate -o orderer.example.com:7050  -C $(CHANNEL_NAME) -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.admin')"
	@sleep 5
  endif

# 12.
.PHONY: invokechaincode
invokechaincode:

  ifeq ($(TLSenable),$(Enable))
	@echo "able tls"
	@cd ./fixture && ./peer chaincode invoke -o orderer.example.com:7050 --tls --cafile $(GOPATH)/src/$(PROJECT_PATH)/fixture/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $(CHANNEL_NAME) -n mycc  -c '{"Args":["invoke","a","b","10"]}'
	@sleep 2
  else
	@echo "disable tls"
	@cd ./fixture && ./peer chaincode invoke -o orderer.example.com:7050 -C $(CHANNEL_NAME) -n mycc  -c '{"Args":["invoke","a","b","10"]}'
	@sleep 2
  endif

# 13.
.PHONY: querychaincode
querychaincode:
	@cd ./fixture && ./peer chaincode query -C $(CHANNEL_NAME) -n mycc -c '{"Args":["query","a"]}'
	@sleep 2


# C1
testchaincode: appchannel joinchannel installchaincode instantiatechaincode  querychaincode invokechaincode 


