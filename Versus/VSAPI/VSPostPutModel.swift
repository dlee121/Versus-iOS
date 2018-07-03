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
public class VSPostPutModel : AWSModel {
    
    var a: String?
    var bc: NSNumber?
    var bi: NSNumber?
    var bn: String?
    var c: NSNumber?
    var ps: NSNumber?
    var pt: NSNumber?
    var q: String?
    var rc: NSNumber?
    var ri: NSNumber?
    var rn: String?
    var t: String?
    
   	public override static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
		var params:[AnyHashable : Any] = [:]
		params["a"] = "a"
		params["bc"] = "bc"
		params["bi"] = "bi"
		params["bn"] = "bn"
		params["c"] = "c"
		params["ps"] = "ps"
		params["pt"] = "pt"
		params["q"] = "q"
		params["rc"] = "rc"
		params["ri"] = "ri"
		params["rn"] = "rn"
		params["t"] = "t"
		
        return params
	}
}
