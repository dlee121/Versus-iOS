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
public class VSPostsListModel_hits_hits_item__source : AWSModel {
    
    var bc: NSNumber?
    var bn: String?
    var bi: NSNumber?
    var a: String?
    var ps: NSNumber?
    var c: NSNumber?
    var pt: NSNumber?
    var q: String?
    var t: String?
    var rc: NSNumber?
    var rn: String?
    var ri: NSNumber?
    
   	public override static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
		var params:[AnyHashable : Any] = [:]
		params["bc"] = "bc"
		params["bn"] = "bn"
		params["bi"] = "bi"
		params["a"] = "a"
		params["ps"] = "ps"
		params["c"] = "c"
		params["pt"] = "pt"
		params["q"] = "q"
		params["t"] = "t"
		params["rc"] = "rc"
		params["rn"] = "rn"
		params["ri"] = "ri"
		
        return params
	}
}
