//
//  ViewController.m
//  ObjCLoadWebviewImage
//
//  Created by huangyibiao on 15/10/16.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import <AFNetworking/AFNetworking.h>
#import "UIImageView+AFNetworking.h"

@interface ViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableArray *imageViews;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.scalesPageToFit = YES;
  [self.view addSubview:self.webView];
  
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
  NSString *html = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
  
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<img\\ssrc[^>]*/>" options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
  NSArray *result = [regex matchesInString:html options:NSMatchingReportCompletion range:NSMakeRange(0, html.length)];
  
  NSMutableDictionary *urlDicts = [[NSMutableDictionary alloc] init];
  NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
  
  for (NSTextCheckingResult *item in result) {
    NSString *imgHtml = [html substringWithRange:[item rangeAtIndex:0]];
    
    NSArray *tmpArray = nil;
    if ([imgHtml rangeOfString:@"src=\""].location != NSNotFound) {
      tmpArray = [imgHtml componentsSeparatedByString:@"src=\""];
    } else if ([imgHtml rangeOfString:@"src="].location != NSNotFound) {
      tmpArray = [imgHtml componentsSeparatedByString:@"src="];
    }
    
    if (tmpArray.count >= 2) {
      NSString *src = tmpArray[1];
      
      NSUInteger loc = [src rangeOfString:@"\""].location;
      if (loc != NSNotFound) {
        src = [src substringToIndex:loc];
        
        NSLog(@"正确解析出来的SRC为：%@", src);
        if (src.length > 0) {
          NSString *localPath = [docPath stringByAppendingPathComponent:[self md5:src]];
          // 先将链接取个本地名字，且获取完整路径
          [urlDicts setObject:localPath forKey:src];
        }
      }
    }
  }
  
  // 遍历所有的URL，替换成本地的URL，并异步获取图片
  for (NSString *src in urlDicts.allKeys) {
    NSString *localPath = [urlDicts objectForKey:src];
    html = [html stringByReplacingOccurrencesOfString:src withString:localPath];
    
    // 如果已经缓存过，就不需要重复加载了。
    if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
      [self downloadImageWithUrl:src];
    }
  }
  
  NSLog(@"%@", html);
  
  [self.webView loadHTMLString:html baseURL:url];
}

- (void)downloadImageWithUrl:(NSString *)src {
  // 注意：这里并没有写专门下载图片的代码，就直接使用了AFN的扩展，只是为了省麻烦而已。
  UIImageView *imgView = [[UIImageView alloc] init];
  
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:src]];
  [imgView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
    NSData *data = UIImagePNGRepresentation(image);
    NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *localPath = [docPath stringByAppendingPathComponent:[self md5:src]];
    
    if (![data writeToFile:localPath atomically:NO]) {
      NSLog(@"写入本地失败：%@", src);
    }
  } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
    NSLog(@"download image url fail: %@", src);
  }];
  
  if (self.imageViews == nil) {
    self.imageViews = [[NSMutableArray alloc] init];
  }
  [self.imageViews addObject:imgView];
}

- (NSString *)md5:(NSString *)sourceContent {
  if (self == nil || [sourceContent length] == 0) {
    return nil;
  }
  
  unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
  CC_MD5([sourceContent UTF8String], (int)[sourceContent lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
  NSMutableString *ms = [NSMutableString string];
  
  for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [ms appendFormat:@"%02x", (int)(digest[i])];
  }
  
  return [ms copy];
}

@end
