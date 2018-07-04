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
 

import Foundation
import AWSCore

@objcMembers
public class VSUserPutModel : AWSModel {
    
    var ai: String?
    var b: NSNumber?
    var bd: String?
    var cs: String?
    var em: String?
    //var fn: String?
    var g: NSNumber?
    var _in: NSNumber?
    //var ln: String?
    var ph: String?
    var pi: NSNumber?
    var s: NSNumber?
    var t: String?
    
   	public override static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
		var params:[AnyHashable : Any] = [:]
		params["ai"] = "ai"
		params["b"] = "b"
		params["bd"] = "bd"
		params["cs"] = "cs"
		params["em"] = "em"
		//params["fn"] = "fn"
		params["g"] = "g"
		params["_in"] = "in"
		//params["ln"] = "ln"
		params["ph"] = "ph"
		params["pi"] = "pi"
		params["s"] = "s"
		params["t"] = "t"
		
        return params
	}
}
