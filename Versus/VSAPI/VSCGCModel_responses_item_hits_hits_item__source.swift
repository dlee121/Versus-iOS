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
public class VSCGCModel_responses_item_hits_hits_item__source : AWSModel {
    
    var a: String?
    var pr: String?
    var ci: NSNumber?
    var r: String?
    var u: NSNumber?
    var d: NSNumber?
    var pt: String?
    var t: String?
    var m: NSNumber?
    var ct: String?
    
   	public override static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
		var params:[AnyHashable : Any] = [:]
		params["a"] = "a"
		params["pr"] = "pr"
		params["ci"] = "ci"
		params["r"] = "r"
		params["u"] = "u"
		params["d"] = "d"
		params["pt"] = "pt"
		params["t"] = "t"
		params["m"] = "m"
		params["ct"] = "ct"
		
        return params
	}
}
