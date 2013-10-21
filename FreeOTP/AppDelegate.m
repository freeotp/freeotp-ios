//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2013  Nathaniel McCallum, Red Hat
// see file 'COPYING' for use and warranty information
//
// This program is free software you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "AppDelegate.h"
#import "Token.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Make token
    Token* token = [[Token alloc] initWithURL:url];
    if (token == nil)
        return NO;

    // Add token
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    if ([def stringForKey:[token uid]] == nil) {
        NSMutableArray* order = [NSMutableArray arrayWithArray:[def objectForKey:TOKEN_ORDER]];
        [order insertObject:[token uid] atIndex:0];
        [def setObject:order forKey:TOKEN_ORDER];
    }
    [def setObject:[token description] forKey:[token uid]];
    [def synchronize];

    // Reload the view
    [self.window.rootViewController loadView];
    return YES;
}
@end
