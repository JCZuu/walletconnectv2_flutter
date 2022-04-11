import Flutter
import UIKit
import WalletConnect
import WalletConnectUtils

extension String: Error {}

public class SwiftWalletconnectv2FlutterPlugin: NSObject, FlutterPlugin, WalletConnectClientDelegate {
    var client: WalletConnectClient?
    var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "walletconnectv2_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftWalletconnectv2FlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("walletconectv2 handle", call.method, call.arguments)
        do{
            switch call.method {
            case "init":
                try onInit(call, result: result)
            case "pair":
                if self.client == nil {
                    throw "尚未初始化"
                }
                guard let uri = call.arguments as? String else {
                    throw "传递参数异常"
                }
                try self.client!.pair(uri: uri)
            case "getPlatformVersion":
                result("iOS " + UIDevice.current.systemVersion)
            default:
                result(FlutterMethodNotImplemented);
            }
        }
        catch {
            result(FlutterError(code: "0", message: "\(error)", details: nil))
        }
        print("walletconectv2 handle done", call.method, call.arguments)
    }
    
    public func didUpdate(sessionTopic: String, accounts: Set<Account>) {
        print("walletconectv2 didUpdate", sessionTopic, accounts)
    }
    
    public func didReceive(sessionProposal: Session.Proposal) {
        do {
            self.channel?.invokeMethod("onProposal", arguments: [
                "proposer": String(data: try JSONEncoder().encode(sessionProposal.proposer), encoding: .utf8),
                "permissions": [
                    "blockchains": Array(sessionProposal.permissions.blockchains),
                    "methods": Array(sessionProposal.permissions.methods),
                ]
            ], result: { res in
                print("walletconectv2 didReceive sessionProposal: res", res)
                if res is FlutterError {
                    let err = (res as! FlutterError);
                    self.client?.reject(proposal: sessionProposal, reason: RejectionReason.disapprovedChains)
                } else {
                    self.client?.approve(proposal: sessionProposal, accounts: Set((res as! [String]).map({Account($0)!})))
                }
            })
        } catch {
            print("didReceive error", error)
        }
    }
    
    public func didReceive(sessionRequest: Request) {
        do {
            let sessions = self.client!.getSettledSessions()
            let sessionIndex = sessions.firstIndex(where: { s in
                s.topic == sessionRequest.topic
            })!
            self.channel?.invokeMethod("onRequest", arguments: [
                "proposer":String(data: try JSONEncoder().encode(sessions[sessionIndex].peer), encoding: .utf8),
                "request": String(data: try JSONEncoder().encode(sessionRequest), encoding: .utf8),
            ], result: { res in
                if res is FlutterError {
                    let err = (res as! FlutterError);
                    self.client?.respond(topic: sessionRequest.topic, response: JsonRpcResult.error(JSONRPCErrorResponse.init(id: sessionRequest.id, error: JSONRPCErrorResponse.Error.init(code: 5000, message: err.message!))))
                } else {
                    let response = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: AnyCodable(res as! String))
                    self.client?.respond(topic: sessionRequest.topic, response: JsonRpcResult.response(response))
                }
            })
        } catch {
            print("didReceive error", error)
        }
    }
    
    public func didDelete(sessionTopic: String, reason: Reason) {
        print("walletconectv2 didDelete", sessionTopic, reason)
    }
    
    public func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
        print("walletconectv2 didUpgrade", sessionTopic, permissions)
    }
    
    public func didSettle(session: Session) {
        print("walletconectv2 didSettle", session)
    }
    
    private func onInit(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if self.client != nil {
            throw "已初始化"
        }
        guard let arguments = call.arguments as? [String: Any] else {
            throw "传递参数异常"
        }
        
        let metadata = try JSONDecoder().decode(AppMetadata.self, from: (arguments["metadata"] as! String).data(using: .utf8)!)
        self.client = WalletConnectClient(metadata: metadata, projectId: arguments["projectId"] as! String, relayHost: arguments["relayHost"] as! String)
        self.client!.delegate = self
        print("walletconectv2 oninit", metadata, arguments["isController"], arguments["relayHost"])
        result(nil)
    }
}
