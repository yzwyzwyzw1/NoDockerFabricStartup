- [mac非docker启动调试fabric](https://www.jianshu.com/p/f156b0e6649d)
- [Fabric应用开发-配置文件](https://www.jianshu.com/p/27b7d2bd7e79)
---
# 版权

&emsp;&emsp;开源共享，编者严志伟，开发公司：中国搜索公司

# 简介

&emsp;&emsp;本模板的功能是通过非docker方式快速启动docker网络,用于快速测试智能合约，脱机可用，只修修改相关路径即可，其次用于测试源码修改后生成的二进制文件是否运行正常。

# 基础环境准备

- golang
- fabric
- 几个配置文件

## fixture文件目录

### 配置文件

- configtx.yaml: github.com/hyperledger/fabric/fabric-sample/first-network/configtx.yaml
- crypto-config.yaml: github.com/hyperledger/fabric/fabric-sample/first-network/crypto-config.yaml
- core.yaml: github.com/hyperledger/fabric/sampleconfig/core.yaml (内容需要修改，这是peer节点配置文件)
- orderer.yaml:  github.com/hyperledger/fabric/sampleconfig/orderder.yaml （内容需要修改，这是orderer节点配置文件）
- chaincode: github.com/hyperledger/fabric/examples/chaincode/go/example02

### 生成二进制命令文件
```
make bin
```

### 获取二进制命令文件

```
make cpbin
```

## 单机部署

### 生成所需的配置文件

1. 生成MSP组织结构需要的证书密钥文件夹crypto-config
```
make crypto-config
```

2. 生成创世区块配置文件
```
make genesis
```

3. 生成通道配置文件
```
make channelblock
```

4. 生成锚节点更新配置文件
```
make anchors
```

### 本地启动fabric网络

1. 启动orderer节点

&emsp;&emsp;启动orderer服务需要配置环境变量，对于本地启动orderer服务，可以在终端中输入命令，也或者直接修改配置文件orderer.yaml，建议使用方式2。

对于第一种方式：
```
ORDERER_GENERAL_LOGLEVEL=DEBUG
ORDERER_GENERAL_TLS_ENABLED=false
ORDERER_GENERAL_PROFILE_ENABLED=false
ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
ORDERER_GENERAL_LISTENPORT=7050
ORDERER_GENERAL_GENESISMETHOD=file
ORDERER_GENERAL_GENESISFILE=/home/yzw/GoSpace/gopath/src/github.com/blockchaintest.com/NoDockerFabricStartup/fixture/channel-artifacts/genesis.block
ORDERER_GENERAL_LOCALMSPID=OrdererMSP
CONSENSUS_TYPE=sole
ORDERER_GENERAL_LOCALMSPDIR=crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp
```
对于第二种方式：

看配置文件orderer.yaml文件中做出的修改那部分的内容！

(新终端，root用户,非root用户)启动orderer:
```
make ordererstartup
```

> 补充说明: 如果一直使用的是root用户，需要继续使用root用户执行权限，否则会出现权限不许可的错误，以下命令均符合这条说明。

2. 启动peer节点


&emsp;&emsp;首先设置IP地址映射，修改（ubuntu下）修改/etc/hosts文件，在文件中添加如下内容：
```
127.0.0.1    peer0.org1.example.com

127.0.0.1    peer1.org1.example.com

127.0.0.1    peer0.org2.example.com

127.0.0.1    peer1.org2.example.com

127.0.0.1    orderer.example.com
```

&emsp;&emsp;启动peer服务需要配置环境变量，对于本地启动peer服务，可以在终端中输入命令，也或者直接修改配置文件core.yaml，建议使用方式2。

对于第一种方式：
```
CORE_PEER_ID=peer0.org1.example.com
CORE_CHAINCODE_MODE=dev
CORE_PEER_NETWORKID=dev
CORE_PEER_TLS_ENABLED=false
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LISTENADDRESS=0.0.0.0:7051
CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID=Org1MSP
CORE_PEER_MSPCONFIGPATH=crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp
CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052
CORE_PEER_CHAINCODEADDRESS=peer0.org1.example.com:7052
FABRIC_LOGGING_SPEC=INFO
```
对于第二种方式：

看配置文件core.yaml文件中做出的修改那部分的内容！


启动peer：
```
make peerstartup
```

### 部署链码测试

1. 创建应用通道客户端

```
make appchannel
```

2. 节点加入应用通道
```
make joinappchannel
```

3. 更新锚节点

```
make updateanchors
```

4. 部署测试链码-安装链码

```
make installchaincode
```

5. 部署测试链码-实例化链码

```
make instantiatechaincode
```

6. 部署测试链码-链码调用测试

```
make invokechaincode
```

7. 部署测试链码-查询链码测试

```
make querychaincode
```

## 其他命令


1. 快速测试

```
#bin 终端3
make bin
make cpbin

#env 终端3
make cleanenv
make createenv

#orderer 终端1
make ordererstartup

#peer 终端2
make peerstartup

#chaincode 终端3
make testchaincode
make querychaincode
```
正确的输出结果:
```
90
```



# 终端输入命令（仅供参考，不建议使用）
```
FABRIC_CFG_PATH=$PWD
CORE_PEER_ID=peer0.org1.examle.com
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID=Org1MSP
CORE_PEER_MSPCONFIGPATH=/home/yzw/GoSpace/gopath/src/github.com/blockchaintest.com/NoDockerFabricStartup/fixture/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
./peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/mychannel.tx --tls --cafile /home/yzw/GoSpace/gopath/src/github.com/blockchaintest.com/NoDockerFabricStartup/fixture/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
./peer channel join -b ./channel-artifacts/mychannal.block
./peer chaincode install -n mycc -v 1.0 -p github.com/blockchaintest.com/NoDockerFabricStartup/chaincode/example02
./peer chaincode instantiate -o orderer.example.com:7050  -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.peer')"
./peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
```


# 报错处理

**报错1**：2018-12-27 13:47:14.743 UTC [orderer.common.server] initializeLocalMsp -> FATA 002 Failed to initialize local MSP: could not load a valid signer certificate from directory /var/hyperledger/orderer/msp/signcerts: stat /var/hyperledger/orderer/msp/signcerts: no such file or directory

报错原因：orderer.yaml中，LocalMSPDir路径写的不对

解决办法：最后我改成了LocalMSPDir: crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp

**报错2**：Failed to initialize local MSP: getCertFromPem error: failed to parse x509 cert: x509: unsupported elliptic curve

报错原因：channel-artifacts和crypro-config文件夹中的文件生成的有问题

解决办法，删掉重建

**报错3**：Error: failed to create deliver client: orderer client failed to connect to orderer.example.com:7050: failed to create new connection: context deadline exceeded

报错原因： 查看一下是不是关闭了orderer.yaml和core.yaml文件夹中的tls功能，然而，在输入的命令中有增加了tls证书索引路径。还有别的原因，我的命令是通过Makefile的方式执行的，在执行的命令中
我忽略了Makefile和命令行引用环境的区别，在Makefile文件中引用环境变量需要增加“（）”,在命令行中引用环境变量不需要添加“（）”。

解决办法：在测试时首先关闭tls功能，去掉tls索引路径。之后，查看peer日志，确定具体报错问题，再解决。

**报错4**:2019-07-12 16:20:31.984 CST [committer.txvalidator] validateTx -> ERRO 046 VSCCValidateTx for transaction txId = f8fa34eb27611acd2c2144922ff0b6d570140bf77a9e25c899b143209efb9a26 returned error: validation of endorsement policy for chaincode mycc in tx 2:0 failed: signature set did not satisfy policy

报错原因：我在实例化链码时使用的背书者没有写集权限，需要参考configtx.yaml 中的有写集权限的背书者

解决办法：我查看了configtx.yaml文件中的内容，发现Org1的Org1.admin有写权限，将-P "OR ('Org1MSP.peer')"修改为了-P "OR ('Org1MSP.admin')",这样数据就能成功提交账本了
