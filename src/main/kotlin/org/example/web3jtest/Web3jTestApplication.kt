package org.example.web3jtest

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class Web3jTestApplication

fun main(args: Array<String>) {
    runApplication<Web3jTestApplication>(*args)
}


// web3j generate solidity -b src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1CollectionCreator.bin -a src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1CollectionCreator.abi -o src/main/kotlin -p org.example.web3jtest.contracts.erc721.wrapper
// web3j generate solidity -b src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1Collection.bin -a src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1Collection.abi -o src/main/kotlin -p org.example.web3jtest.contracts.erc721.wrapper