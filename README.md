# web3j-ganache-test

필요 도구

- ganache (로컬 테스트용 블록체인)
- solc (솔리디티 컴파일러)
- web3j

ganache는 solidity 0.8.19까지만 지원함

- solc 컴파일 시 최신 버전으로 컴파일 되지 않게 주의

8.19 버전 솔리디티 컴파일

```kotlin
docker run --platform linux/amd64 --rm -v $(pwd):/sources ethereum/solc:0.8.19 --overwrite --abi --bin -o /sources/src/main/kotlin/org/example/web3jtest/contracts/erc721/output /sources/src/main/kotlin/org/example/web3jtest/contracts/erc721/MsNftV1CollectionCreator.sol ``
```

solidity → java wrapper class
```kotlin
web3j generate solidity -b src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1CollectionCreator.bin -a src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1CollectionCreator.abi -o src/main/kotlin -p org.example.web3jtest.contracts.erc721.wrapper
web3j generate solidity -b src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1Collection.bin -a src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1Collection.abi -o src/main/kotlin -p org.example.web3jtest.contracts.erc721.wrapper
```
