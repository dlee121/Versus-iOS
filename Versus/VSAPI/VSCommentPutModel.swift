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
public class VSCommentPutModel : AWSModel {
    
    var a: String?
    var ci: NSNumber?
    var ct: String?
    var d: NSNumber?
    var m: NSNumber?
    var pr: String?
    var pt: String?
    var r: String?
    var rc: NSNumber?
    var t: String?
    var u: NSNumber?
    
    public override static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        var params:[AnyHashable : Any] = [:]
        params["a"] = "a"
        params["ci"] = "ci"
        params["ct"] = "ct"
        params["d"] = "d"
        params["m"] = "m"
        params["pr"] = "pr"
        params["pt"] = "pt"
        params["r"] = "r"
        params["rc"] = "rc"
        params["t"] = "t"
        params["u"] = "u"
        
        return params
    }
}
