objc-openid
===========

OpenID 2.0 Objective-C implementation for OpenID sign on. (inspired by JOpenID)

QuickStart
==========

First, create an OpenIdManager instance and set your web site domain:

       _manager = [[OIDOpenIdManager alloc] init];
       _manager.returnTo = @"https://www.openid-example.com/";
       _manager.realm = @"https://*.openid-example.com";

Next, we lookup the Endpoint URL of Google:

    [self.manager lookupEndpoint:@"Google" callback:^(OIDEndpoint *endpoint) {
        NSLog(@"%@", endpoint);
    }];

Then we need to get the Association from the Endpoint URL of Google:

        [self.manager lookupAssociation:endpoint callback:^(OIDAssociation *association) {
            NSLog(@"%@", association);
        }];

After the Association is setup between your web site and Google, we can redirect the end user to Google's sign on page:

            NSString *url = [self.manager getAuthenticationUrl:endpoint association:association];
            NSLog(@"Open the authentication URL in browser: %@", url);

we can still continue to finish the sign on process:

            NSString *url = @"the URL in address bar of browser";
            NSLog(@"After successfully sign on in browser, enter the URL of address bar in browser: %@", url);
            
            OIDAuthentication *authentication = [self.manager authentication:request key:self.macKey alias:self.alias];
            if (authentication) {
                NSLog(@"Login Success Identity: %@", authentication.identity);
            } else {
                NSLog(@"Login failure.");
            }

If you want more detail, please see [JOpenID's QuickStart](https://code.google.com/p/jopenid/wiki/QuickStart).

License
=======
ObjcOpendID is made available under the New BSD License.

JOpenID is an OpenID 2.0 Java 5 implementation.
https://code.google.com/p/jopenid/

