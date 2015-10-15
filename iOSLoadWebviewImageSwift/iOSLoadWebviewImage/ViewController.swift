//
//  ViewController.swift
//  iOSLoadWebviewImage
//
//  Created by huangyibiao on 15/10/15.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

import UIKit


extension String {
  var md5 : String{
    let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
    let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen);
    
    CC_MD5(str!, strLen, result);
    
    let hash = NSMutableString();
    for i in 0 ..< digestLen {
      hash.appendFormat("%02x", result[i]);
    }
    result.destroy();
    
    return String(format: hash as String)
  }
}

class ViewController: UIViewController {
  var webView = UIWebView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    webView.frame = self.view.bounds
    self.view.addSubview(webView)
    
    webView.scalesPageToFit = true
    
    let path = NSBundle.mainBundle().pathForResource("test", ofType: "html")
    let url = NSURL(fileURLWithPath: path!)
    
    do {
      let html = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
      //      print(html)
      
      // 获取所有img src中的src链接，并将src更改名称
      // 这里直接采用同步获取数据，异步也是一样的道理，为了方便写demo，仅以同步加载图片为例。
      // 另外，这不考虑清除缓存的问题。
      do {
        let regex = try NSRegularExpression(pattern: "<img\\ssrc[^>]*/>", options: .AllowCommentsAndWhitespace)
        
        let result = regex.matchesInString(html, options: .ReportCompletion, range: NSMakeRange(0, html.characters.count))
        
        var content = html as NSString
        var sourceSrcs: [String: String] = ["": ""]
        
        for item in result {
          let range = item.rangeAtIndex(0)
          
          let imgHtml = content.substringWithRange(range) as NSString
          var array = [""]
          
          if imgHtml.rangeOfString("src=\"").location != NSNotFound {
            array = imgHtml.componentsSeparatedByString("src=\"")
          } else if imgHtml.rangeOfString("src=").location != NSNotFound {
            array = imgHtml.componentsSeparatedByString("src=")
          }
          
          if array.count >= 2 {
            var src = array[1] as NSString
            if src.rangeOfString("\"").location != NSNotFound {
              src = src.substringToIndex(src.rangeOfString("\"").location)
              
              // 图片链接正确解析出来
              print(src)
              
              // 加载图片
              // 这里不处理重复加载的问题，实际开发中，应该要做一下处理。
              // 也就是先判断是否已经加载过，且未清理掉该缓存的图片。如果
              // 已经缓存过，否则才执行下面的语句。
              let data = NSData(contentsOfURL: NSURL(string: src as String)!)
              let localUrl = self.saveImageData(data!, name: (src as String).md5)
              
              // 记录下原URL和本地URL
              // 如果用异步加载图片的方式，先可以提交将每个URL起好名字，由于这里使用的是原URL的md5作为名称，
              // 因此每个URL的名字是固定的。
              sourceSrcs[src as String] = localUrl
            }
          }
        }
        
        for (src, localUrl) in sourceSrcs {
          if !localUrl.isEmpty {
            content = content.stringByReplacingOccurrencesOfString(src as String, withString: localUrl, options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, content.length))
          }
        }
        
        print(content as String)
        webView.loadHTMLString(content as String, baseURL: url)
      } catch {
        print("match error")
      }
    } catch {
      print("load html error")
    }
  }
  
func saveImageData(data: NSData, name: String) ->String {
  let docPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
  
  let path = docPath.stringByAppendingPathComponent(name)
  
  // 若已经缓存过，就不需要重复操作了
  if NSFileManager.defaultManager().fileExistsAtPath(path) {
    return path
  }
  
  do {
    try data.writeToFile(path, options: NSDataWritingOptions.DataWritingAtomic)
  } catch {
    print("save image data with name: \(name) error")
  }
  
  return path
}

}

