package org.example.web3jtest

import io.reactivex.disposables.Disposable
import org.example.web3jtest.contracts.erc721.wrapper.MsNftV1CollectionCreator
import org.junit.jupiter.api.Test
import org.web3j.abi.FunctionEncoder
import org.web3j.abi.TypeReference
import org.web3j.abi.datatypes.Address
import org.web3j.abi.datatypes.Event
import org.web3j.abi.datatypes.Function
import org.web3j.abi.datatypes.Utf8String
import org.web3j.crypto.Credentials
import org.web3j.crypto.Hash
import org.web3j.crypto.RawTransaction
import org.web3j.protocol.Web3j
import org.web3j.protocol.core.DefaultBlockParameterName
import org.web3j.protocol.core.methods.request.EthFilter
import org.web3j.protocol.core.methods.response.Log
import org.web3j.protocol.http.HttpService
import org.web3j.tx.Contract
import org.web3j.tx.RawTransactionManager
import org.web3j.tx.gas.ContractGasProvider
import org.web3j.tx.gas.StaticGasProvider
import java.math.BigInteger
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit


class Web3jTestApplicationTests {

    // val web3j: Web3j = Web3j.build(HttpService("http://localhost:8545"))
    val web3j: Web3j = Web3j.build(HttpService("HTTP://127.0.0.1:7545"))

    //  val privateKey = "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bcdcc237f75ad3d7c8984f59"
    val privateKey = "0x040cfb4250104b9d57fd2916aed39549fe9d0361b7db0cfc435cdff18287931f"
    val credentials = Credentials.create(privateKey)
    private val rawTransactionManager = RawTransactionManager(web3j, credentials)

    @Test
    fun getBalance() {
        println(web3j.ethGetBalance("0x784242863096dD58eBBecFc16692110CA6A3492a", DefaultBlockParameterName.LATEST).send().balance)
        println(web3j.ethGetBalance("0x5eEC34d5Cc09e57941B68Bb03DF17256E1eA64E5", DefaultBlockParameterName.LATEST).send().balance)
        println(web3j.ethGetBalance("0x2272F3B46614eAB2Af01Ec6b01d72bB504aC47bf", DefaultBlockParameterName.LATEST).send().balance)
    }

    @Test
    fun deployCreatorContract() {

        val gasPrice = BigInteger.valueOf(20_000_000_000L)
        val gasLimit = BigInteger.valueOf(4_700_000L)
        val gasProvider: ContractGasProvider = StaticGasProvider(gasPrice, gasLimit)

        val nftV1CollectionCreator = MsNftV1CollectionCreator.deploy(
            web3j, credentials, gasProvider
        ).send()

        println("Contract Address: ${nftV1CollectionCreator.contractAddress}")
        //"0x12396a9bbacd97156db740e85c208a3393018328"
    }

    @Test
    fun deployCollection() {
        val collectionCreatorAddress = "0x3573821edce911a44bf2e2aabeb07d5874a8474b"
        val rawTransaction = createRawTransaction(
            collectionCreatorAddress, Function(
                "deployContract",
                listOf(
                    Utf8String("collectionName"),
                    Utf8String("collectionSymbol"),
                ),
                emptyList()
            )
        )

        val ethSendTransaction = rawTransactionManager.signAndSend(rawTransaction)

        if (ethSendTransaction.hasError()) {
            println(ethSendTransaction.error.message)
        }

        val latch = CountDownLatch(1)

        eventListener(
            collectionCreatorAddress, ethSendTransaction.transactionHash, Hash.sha3String("DeployContract(address,address)"),
            {
                val eventValues = Contract.staticExtractEventParameters(Event("DeployContract", listOf(object : TypeReference<Address>() {}, object : TypeReference<Address>() {})), it)
                val params = eventValues.nonIndexedValues
                val deployedContract = params[1].value as String
                println("배포된 컨트랙트 $deployedContract")
                //0xd7bc1800032f74912a772b24c68914b74cbbe1be
            },
            {
                it.printStackTrace()
            }
        )

        try {
            latch.await() // 로그가 수신될 때까지 대기
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }

    }

    fun getNonce() = web3j.ethGetTransactionCount(credentials.address, DefaultBlockParameterName.PENDING)?.send()?.transactionCount

    private fun createRawTransaction(contractAddress: String, function: Function): RawTransaction {
        return RawTransaction.createTransaction(
            getNonce(),
            BigInteger.valueOf(20_000_000_000L),
            BigInteger.valueOf(4_700_000L),
            contractAddress,
            FunctionEncoder.encode(function),
        )
    }

    fun eventListener(contractAddress: String, transactionHash: String, eventSignature: String, onSuccess: (Log) -> Unit, onError: (Throwable) -> Unit) {
        var disposable: Disposable? = null

        disposable = web3j.ethLogFlowable(
            EthFilter(
                DefaultBlockParameterName.EARLIEST,
                DefaultBlockParameterName.LATEST,
                contractAddress
            )
                .addSingleTopic(eventSignature)
        )
            .filter { it.transactionHash == transactionHash }
            .delay(100, TimeUnit.MILLISECONDS)
            .timeout(100, TimeUnit.SECONDS)
            .subscribe(
                {
                    onSuccess(it)
                    disposable?.dispose()
                },
                {
                    onError(it)
                    disposable?.dispose()
                }
            ) {
                disposable!!.dispose()
            }
    }
}
