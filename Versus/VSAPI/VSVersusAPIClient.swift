/*
 Copyright 2010-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License").
 You may not use this file except in compliance with the License.
 A copy of the License is located at

 http://aws.amazon.com/apache2.0

 or in the "license" file accompanying this file. This file is distributed
 on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 express or implied. See the License for the specific language governing
 permissions and limitations under the License.
 */
 

import AWSCore
import AWSAPIGateway

//@objcMembers
public class VSVersusAPIClient: AWSAPIGatewayClient {

	static let AWSInfoClientKey = "VSVersusAPIClient"

	private static let _serviceClients = AWSSynchronizedMutableDictionary()
	private static let _defaultClient:VSVersusAPIClient = {
		var serviceConfiguration: AWSServiceConfiguration? = nil
        let serviceInfo = AWSInfo.default().defaultServiceInfo(AWSInfoClientKey)
        if let serviceInfo = serviceInfo {
            serviceConfiguration = AWSServiceConfiguration(region: serviceInfo.region, credentialsProvider: serviceInfo.cognitoCredentialsProvider)
        } else if (AWSServiceManager.default().defaultServiceConfiguration != nil) {
            serviceConfiguration = AWSServiceManager.default().defaultServiceConfiguration
        } else {
            serviceConfiguration = AWSServiceConfiguration(region: .Unknown, credentialsProvider: nil)
        }
        
        return VSVersusAPIClient(configuration: serviceConfiguration!)
	}()
    
	/**
	 Returns the singleton service client. If the singleton object does not exist, the SDK instantiates the default service client with `defaultServiceConfiguration` from `AWSServiceManager.defaultServiceManager()`. The reference to this object is maintained by the SDK, and you do not need to retain it manually.
	
	 If you want to enable AWS Signature, set the default service configuration in `func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?)`
	
	     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
	        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
	        AWSServiceManager.default().defaultServiceConfiguration = configuration
	 
	        return true
	     }
	
	 Then call the following to get the default service client:
	
	     let serviceClient = VSVersusAPIClient.default()

     Alternatively, this configuration could also be set in the `info.plist` file of your app under `AWS` dictionary with a configuration dictionary by name `VSVersusAPIClient`.
	
	 @return The default service client.
	 */ 
	 
	public class func `default`() -> VSVersusAPIClient{
		return _defaultClient
	}

	/**
	 Creates a service client with the given service configuration and registers it for the key.
	
	 If you want to enable AWS Signature, set the default service configuration in `func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)`
	
	     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	         let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
	         let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialProvider)
	         VSVersusAPIClient.registerClient(withConfiguration: configuration, forKey: "USWest2VSVersusAPIClient")
	
	         return true
	     }
	
	 Then call the following to get the service client:
	
	
	     let serviceClient = VSVersusAPIClient.client(forKey: "USWest2VSVersusAPIClient")
	
	 @warning After calling this method, do not modify the configuration object. It may cause unspecified behaviors.
	
	 @param configuration A service configuration object.
	 @param key           A string to identify the service client.
	 */
	
	public class func registerClient(withConfiguration configuration: AWSServiceConfiguration, forKey key: String){
		_serviceClients.setObject(VSVersusAPIClient(configuration: configuration), forKey: key  as NSString);
	}

	/**
	 Retrieves the service client associated with the key. You need to call `registerClient(withConfiguration:configuration, forKey:)` before invoking this method or alternatively, set the configuration in your application's `info.plist` file. If `registerClientWithConfiguration(configuration, forKey:)` has not been called in advance or if a configuration is not present in the `info.plist` file of the app, this method returns `nil`.
	
	 For example, set the default service configuration in `func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) `
	
	     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	         let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
	         let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialProvider)
	         VSVersusAPIClient.registerClient(withConfiguration: configuration, forKey: "USWest2VSVersusAPIClient")
	
	         return true
	     }
	
	 Then call the following to get the service client:
	 
	 	let serviceClient = VSVersusAPIClient.client(forKey: "USWest2VSVersusAPIClient")
	 
	 @param key A string to identify the service client.
	 @return An instance of the service client.
	 */
	public class func client(forKey key: String) -> VSVersusAPIClient {
		objc_sync_enter(self)
		if let client: VSVersusAPIClient = _serviceClients.object(forKey: key) as? VSVersusAPIClient {
			objc_sync_exit(self)
		    return client
		}

		let serviceInfo = AWSInfo.default().defaultServiceInfo(AWSInfoClientKey)
		if let serviceInfo = serviceInfo {
			let serviceConfiguration = AWSServiceConfiguration(region: serviceInfo.region, credentialsProvider: serviceInfo.cognitoCredentialsProvider)
			VSVersusAPIClient.registerClient(withConfiguration: serviceConfiguration!, forKey: key)
		}
		objc_sync_exit(self)
		return _serviceClients.object(forKey: key) as! VSVersusAPIClient;
	}

	/**
	 Removes the service client associated with the key and release it.
	 
	 @warning Before calling this method, make sure no method is running on this client.
	 
	 @param key A string to identify the service client.
	 */
	public class func removeClient(forKey key: String) -> Void{
		_serviceClients.remove(key)
	}
	
	init(configuration: AWSServiceConfiguration) {
	    super.init()
	
	    self.configuration = configuration.copy() as! AWSServiceConfiguration
	    var URLString: String = "https://fbl7cib36f.execute-api.us-east-1.amazonaws.com/Launch"
	    if URLString.hasSuffix("/") {
	        URLString = URLString.substring(to: URLString.index(before: URLString.endIndex))
	    }
	    self.configuration.endpoint = AWSEndpoint(region: configuration.regionType, service: .APIGateway, url: URL(string: URLString))
	    let signer: AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: configuration.credentialsProvider, endpoint: self.configuration.endpoint)
	    if let endpoint = self.configuration.endpoint {
	    	self.configuration.baseURL = endpoint.url
	    }
	    self.configuration.requestInterceptors = [AWSNetworkingRequestInterceptor(), signer]
	}

	
    /*
     
     
     @param a 
     
     return type: VSAIModel
     */
    public func aiGet(a: String?) -> AWSTask<VSAIModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/ai", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSAIModel.self) as! AWSTask<VSAIModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSCGCModel
     */
    public func cgcGet(a: String?, b: String?) -> AWSTask<VSCGCModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/cgc", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSCGCModel.self) as! AWSTask<VSCGCModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSCommentModel
     */
    public func commentGet(a: String?, b: String?) -> AWSTask<VSCommentModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/comment", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSCommentModel.self) as! AWSTask<VSCommentModel>
	}

	
    /*
     
     
     @param body 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func commenteditPost(body: VSCommentEditModel, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("POST", urlString: "/commentedit", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param body 
     @param c 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func commentputPost(body: VSCommentPutModel, c: String?, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("POST", urlString: "/commentput", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param c 
     @param d 
     @param a 
     @param b 
     
     return type: VSCommentsListModel
     */
    public func commentslistGet(c: String?, d: String?, a: String?, b: String?) -> AWSTask<VSCommentsListModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["d"] = d
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/commentslist", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSCommentsListModel.self) as! AWSTask<VSCommentsListModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: Empty
     */
    public func deleteGet(a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/delete", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSEmailGetModel
     */
    public func getemailGet(a: String?, b: String?) -> AWSTask<VSEmailGetModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/getemail", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSEmailGetModel.self) as! AWSTask<VSEmailGetModel>
	}

	
    /*
     
     
     @param a 
     
     return type: VSLeaderboardModel
     */
    public func leaderboardGet(a: String?) -> AWSTask<VSLeaderboardModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/leaderboard", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSLeaderboardModel.self) as! AWSTask<VSLeaderboardModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPIVModel
     */
    public func pivGet(a: String?, b: String?) -> AWSTask<VSPIVModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/piv", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPIVModel.self) as! AWSTask<VSPIVModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPIVSingle
     */
    public func pivsingleGet(a: String?, b: String?) -> AWSTask<VSPIVSingle> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/pivsingle", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPIVSingle.self) as! AWSTask<VSPIVSingle>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPostModel
     */
    public func postGet(a: String?, b: String?) -> AWSTask<VSPostModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/post", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostModel.self) as! AWSTask<VSPostModel>
	}

	
    /*
     
     
     @param body 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func posteditPost(body: VSPostEditModel, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("POST", urlString: "/postedit", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPostInfoModel
     */
    public func postinfoGet(a: String?, b: String?) -> AWSTask<VSPostInfoModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/postinfo", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostInfoModel.self) as! AWSTask<VSPostInfoModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPostInfoMultiModel
     */
    public func postinfomultiGet(a: String?, b: String?) -> AWSTask<VSPostInfoMultiModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/postinfomulti", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostInfoMultiModel.self) as! AWSTask<VSPostInfoMultiModel>
	}

	
    /*
     
     
     @param body 
     @param c 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func postputPost(body: VSPostPutModel, c: String?, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("POST", urlString: "/postput", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPostQModel
     */
    public func postqGet(a: String?, b: String?) -> AWSTask<VSPostQModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/postq", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostQModel.self) as! AWSTask<VSPostQModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSPostQMultiModel
     */
    public func postqmultiGet(a: String?, b: String?) -> AWSTask<VSPostQMultiModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/postqmulti", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostQMultiModel.self) as! AWSTask<VSPostQMultiModel>
	}

	
    /*
     
     
     @param c 
     @param d 
     @param a 
     @param b 
     
     return type: VSPostsListModel
     */
    public func postslistGet(c: String?, d: String?, a: String?, b: String?) -> AWSTask<VSPostsListModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["d"] = d
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/postslist", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostsListModel.self) as! AWSTask<VSPostsListModel>
	}

	
    /*
     
     
     @param c 
     @param a 
     @param b 
     
     return type: VSPostsListCompactModel
     */
    public func postslistcompactGet(c: String?, a: String?, b: String?) -> AWSTask<VSPostsListCompactModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/postslistcompact", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSPostsListCompactModel.self) as! AWSTask<VSPostsListCompactModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSProfileInfoModel
     */
    public func profileinfoGet(a: String?, b: String?) -> AWSTask<VSProfileInfoModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/profileinfo", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSProfileInfoModel.self) as! AWSTask<VSProfileInfoModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSRecordPutModel
     */
    public func recordGet(a: String?, b: String?) -> AWSTask<VSRecordPutModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/record", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSRecordPutModel.self) as! AWSTask<VSRecordPutModel>
	}

	
    /*
     
     
     @param body 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func recordPost(body: VSRecordPutModel, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("POST", urlString: "/record", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param c 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func setemailGet(c: String?, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/setemail", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: VSUserGetModel
     */
    public func userGet(a: String?, b: String?) -> AWSTask<VSUserGetModel> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/user", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: VSUserGetModel.self) as! AWSTask<VSUserGetModel>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: Empty
     */
    public func userHead(a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("HEAD", urlString: "/user", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param a 
     @param b 
     
     return type: Empty
     */
    public func userputGet(a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/userput", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param body 
     @param c 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func userputPost(body: VSUserPutModel, c: String?, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["c"] = c
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("POST", urlString: "/userput", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: Empty.self) as! AWSTask<Empty>
	}

	
    /*
     
     
     @param e 
     @param c 
     @param d 
     @param a 
     @param b 
     
     return type: Empty
     */
    public func vGet(e: String?, c: String?, d: String?, a: String?, b: String?) -> AWSTask<Empty> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    var queryParameters:[String:Any] = [:]
	    queryParameters["e"] = e
	    queryParameters["c"] = c
	    queryParameters["d"] = d
	    queryParameters["a"] = a
	    queryParameters["b"] = b
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/v", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: Empty.self) as! AWSTask<Empty>
	}




}
