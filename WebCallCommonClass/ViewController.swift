//
//  ViewController.swift
//  WebCallCommonClass
//
//  Created by mac-2 on 20/05/19.
//  Copyright © 2019 mac-2. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /*
         
         http://192.168.0.102:821/taste/get_restaurants/index.php
         
         {"pass_data": {"userid": "1", "lati": "32.9697", "longi": "-96.80322"}}
         
         */
        
        let dictParams : [String : Any] =
            ["userid" : "1",
             "lati" : "32.9697",
             "longi" : "-96.80322"]
        
        let dictJson : [String : Any] = [ "pass_data" : dictParams ]
        
        let headers : [String : String] = ["Content-Type" : "application/json"]
        
        APIManager(httpMethod: .post, apiName: "get_restaurants/index.php", headers: headers, params: dictJson).completion { (response) in
            
            switch response {
            case .failureResponse(let error):
                print(error)
            case .successResponse(let dict):
                print(dict)
            }
            
        }

        
    }

}

