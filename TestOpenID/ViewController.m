//
//  ViewController.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "ViewController.h"
#import "OIDOpenIdManager.h"

#import <WebKit/WebKit.h>

@interface ViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic) OIDOpenIdManager *manager;
@property (nonatomic) NSString *alias;
@property (nonatomic) NSData *macKey;

@end

@implementation ViewController

- (OIDOpenIdManager *)manager
{
    if (! _manager) {
       _manager = [[OIDOpenIdManager alloc] init];
        _manager.returnTo = @"https://www.openid-example.com/";
        _manager.realm = @"https://www.openid-example.com/";
    }
    return _manager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.manager lookupEndpoint:@"http://steamcommunity.com/openid" callback:^(OIDEndpoint *endpoint) {
        NSLog(@"%@", endpoint);
        self.alias = endpoint.alias;
        
        [self.manager lookupAssociation:endpoint callback:^(OIDAssociation *association) {
            NSLog(@"%@", association);
            self.macKey = association.rawMacKey;

            NSString *url = [self.manager getAuthenticationUrl:endpoint association:nil];
            NSLog(@"Open the authentication URL in browser: %@", url);

            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        }];
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    
    if (navigationAction.navigationType == WKNavigationTypeFormSubmitted) {
        NSString *url = navigationAction.request.URL.absoluteString;
        if ([url hasPrefix:self.manager.returnTo]) {
            NSLog(@"After successfully sign on in browser, enter the URL of address bar in browser: %@", url);

            OIDAuthentication *authentication = [self.manager authentication:navigationAction.request key:self.macKey alias:self.alias];
            if (authentication) {
                NSLog(@"Login Success Identity: %@", authentication.identity);
            } else {
                NSLog(@"Login failure.");
            }

            [webView loadHTMLString:authentication.description baseURL:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
