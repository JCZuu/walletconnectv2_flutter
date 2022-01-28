package org.bitizen.walletconnectv2_flutter

import android.app.Application
import android.util.Log
import androidx.annotation.NonNull
import com.google.gson.Gson
import com.walletconnect.walletconnectv2.client.WalletConnect
import com.walletconnect.walletconnectv2.client.WalletConnectClient

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.collections.HashMap

class Walletconnectv2FlutterPlugin : FlutterPlugin, MethodCallHandler {
    var TAG = "Walletconnectv2FlutterPlugin"

    private lateinit var channel: MethodChannel
    private lateinit var application: Application

    private val wcHandler = object : WalletConnectClient.WalletDelegate {
        override fun onSessionDelete(deletedSession: WalletConnect.Model.DeletedSession) {
            TODO("Not yet implemented")
        }

        override fun onSessionNotification(sessionNotification: WalletConnect.Model.SessionNotification) {
            TODO("Not yet implemented")
        }

        override fun onSessionProposal(sessionProposal: WalletConnect.Model.SessionProposal) {
            Log.e(TAG, "onSessionProposal: ${Gson().toJson(sessionProposal)}")
            val icons = sessionProposal.icons.map {
                it.toString()
            }
            channel.invokeMethod("onProposal", mapOf(
                "proposer" to WalletConnect.Model.AppMetaData(
                    name = sessionProposal.name,
                    description = sessionProposal.description,
                    url = sessionProposal.url,
                    icons
                ),
                "permissions" to mapOf(
                    "blockchains" to sessionProposal.chains,
                    "methods" to sessionProposal.methods
                )
            ), object : Result {
                override fun success(result: Any?) {
                    WalletConnectClient.approve(
                        WalletConnect.Params.Approve(
                            proposal = sessionProposal,
                            accounts = result as List<String>
                        ),
                        sessionApprove = object : WalletConnect.Listeners.SessionApprove {
                            override fun onError(error: Throwable) {
                                TODO("Not yet implemented")
                            }

                            override fun onSuccess(settledSession: WalletConnect.Model.SettledSession) {
                                TODO("Not yet implemented")
                            }
                        }
                    )
                }

                override fun error(
                    errorCode: String?,
                    errorMessage: String?,
                    errorDetails: Any?
                ) {
                    WalletConnectClient.reject(
                        WalletConnect.Params.Reject(
                            rejectionReason = errorMessage.orEmpty(),
                            proposalTopic = sessionProposal.topic
                        ),
                        object : WalletConnect.Listeners.SessionReject {
                            override fun onError(error: Throwable) {
                                TODO("Not yet implemented")
                            }

                            override fun onSuccess(rejectedSession: WalletConnect.Model.RejectedSession) {
                                TODO("Not yet implemented")
                            }

                        }
                    )
                }

                override fun notImplemented() {
                    TODO("Not yet implemented")
                }
            })
        }

        override fun onSessionRequest(sessionRequest: WalletConnect.Model.SessionRequest) {
            Log.e(TAG, "onSessionRequest: ${Gson().toJson(sessionRequest)}")
            val session = WalletConnectClient.getListOfSettledSessions().find {
                it.topic == sessionRequest.topic
            }

            channel.invokeMethod("onProposal", mapOf(
                "proposer" to WalletConnect.Model.AppMetaData(
                    name = session!!.peerAppMetaData!!.name,
                    description = session.peerAppMetaData!!.description,
                    url = session.peerAppMetaData!!.url,
                    icons = session.peerAppMetaData!!.icons
                ),
                "request" to Gson().toJson(sessionRequest)
            ), object : Result {
                override fun success(result: Any?) {
                    WalletConnectClient.respond(
                        WalletConnect.Params.Response(
                            sessionRequest.topic,
                            WalletConnect.Model.JsonRpcResponse.JsonRpcResult(
                                id = sessionRequest.request.id,
                                result = result as String,
                            )
                        ),
                        object : WalletConnect.Listeners.SessionPayload {
                            override fun onError(error: Throwable) {
                                TODO("Not yet implemented")
                            }
                        }
                    )
                }

                override fun error(
                    errorCode: String?,
                    errorMessage: String?,
                    errorDetails: Any?
                ) {
                    WalletConnectClient.respond(
                        WalletConnect.Params.Response(
                            sessionRequest.topic,
                            WalletConnect.Model.JsonRpcResponse.JsonRpcError(
                                id = sessionRequest.request.id,
                                error = WalletConnect.Model.JsonRpcResponse.Error(
                                    code = 50000,
                                    message = errorMessage.orEmpty()
                                )
                            )
                        ),
                        object : WalletConnect.Listeners.SessionPayload {
                            override fun onError(error: Throwable) {
                                TODO("Not yet implemented")
                            }
                        }
                    )
                }

                override fun notImplemented() {
                    TODO("Not yet implemented")
                }
            })
        }
    }


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "walletconnectv2_flutter")
        channel.setMethodCallHandler(this)
        application = flutterPluginBinding.applicationContext as Application
        WalletConnectClient.setWalletDelegate(wcHandler)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.e(TAG, "onMethodCall: ${Gson().toJson(call)}")
        try {
            when (call.method) {
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }
                "init" -> {
                    onInit(call, result)
                }
                "pair" -> {
                    onPair(call, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error(e.toString(), null, null)
        }
    }

    private fun onPair(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.arguments as String

        val pairListener = object : WalletConnect.Listeners.Pairing {
            override fun onSuccess(settledPairing: WalletConnect.Model.SettledPairing) {
                Log.e(TAG, "onPair onSuccess: $settledPairing")
            }

            override fun onError(error: Throwable) {
                Log.e(TAG, "onPair onError: $error")
            }
        }

        WalletConnectClient.pair(WalletConnect.Params.Pair(uri), pairListener)
        result.success(null)
    }

    private fun onInit(call: MethodCall, result: Result) {
        val arguments = call.arguments as HashMap<String, Object>
        val metadata = Gson().fromJson(
            arguments.getValue("metadata") as String, WalletConnect.Model.AppMetaData::class.java
        )
        val init = WalletConnect.Params.Init(
            application,
            useTls = true,
            hostName = arguments.getValue("relayHost") as String,
            projectId = arguments.getValue("projectId") as String,
            isController = arguments.getValue("isController") as Boolean,
            metadata = metadata,
        )
        WalletConnectClient.initialize(init)
        result.success(null)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
