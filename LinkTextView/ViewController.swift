//
//  ViewController.swift
//  LinkTextView
//
//  Created by 林達也 on 2016/12/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var textView: LinkTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        textView.texts = [
            .string("あいうえお"),
            .link("かきくけこ", { _ in print("かきくけこ") }),
            .string("さしすせそ"),
            .string("なにぬねの"),
            .link("はひふへほマミムメモ", { _ in })
        ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
