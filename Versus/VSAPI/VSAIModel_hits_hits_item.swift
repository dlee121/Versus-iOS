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

 
public class VSAIModel_hits_hits_item : AWSModel {
    
    var index: String?
    var type: String?
    var id: String?
    var score: NSNumber?
    var source: VSAIModel_hits_hits_item__source?
    
   	public override static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
		var params:[AnyHashable : Any] = [:]
		params["index"] = "_index"
		params["type"] = "_type"
		params["id"] = "_id"
		params["score"] = "_score"
		params["source"] = "_source"
		
        return params
	}
	class func sourceJSONTransformer() -> ValueTransformer{
	    return ValueTransformer.awsmtl_JSONDictionaryTransformer(withModelClass: VSAIModel_hits_hits_item__source.self);
	}
}
