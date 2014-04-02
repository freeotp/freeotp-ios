//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2013  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "TokenStore.h"

#define TOKEN_ORDER @"tokenOrder"

static NSMutableArray*
getTokenOrder(NSUserDefaults* def)
{
    NSMutableArray* order = [NSMutableArray arrayWithArray:[def objectForKey:TOKEN_ORDER]];
    if (order == nil) {
        order = [[NSMutableArray alloc] init];
        [def setObject:order forKey:TOKEN_ORDER];
        [def synchronize];
    }

    return order;
}

@implementation TokenStore
{
    NSUserDefaults* def;
}

- (id)init
{
    self = [super init];

    def = [NSUserDefaults standardUserDefaults];
    if (def == nil)
        return nil;

    return self;
}

- (NSUInteger)count
{
    NSMutableArray* order = getTokenOrder(def);
    return order.count;
}

- (void)add:(Token*)token
{
    [self add:token atIndex:0];
}

- (void)add:(Token*)token atIndex:(NSUInteger)index
{
    if ([def stringForKey:token.uid] != nil)
        return;

    NSMutableArray* order = getTokenOrder(def);
    [order insertObject:token.uid atIndex:index];
    [def setObject:order forKey:TOKEN_ORDER];
    [def setObject:token.description forKey:token.uid];
    [def synchronize];
}

- (void)del:(NSUInteger)index
{
    NSMutableArray* order = getTokenOrder(def);
    NSString* key = [order objectAtIndex:index];
    if (key == nil)
        return;

    [order removeObjectAtIndex:index];
    [def setObject:order forKey:TOKEN_ORDER];
    [def removeObjectForKey:key];
    [def synchronize];
}

- (Token*)get:(NSUInteger)index
{
    NSMutableArray* order = getTokenOrder(def);
    if ([order count] < 1)
        return nil;

    NSString* key = [order objectAtIndex:index];
    if (key == nil)
        return nil;

    return [[Token alloc] initWithString:[def objectForKey:key] internal:YES];
}

- (void)save:(Token*)token
{
    if ([def stringForKey:token.uid] == nil)
        return;

    [def setObject:token.description forKey:token.uid];
    [def synchronize];
}

- (void)moveFrom:(NSUInteger)fromIndex to:(NSUInteger)toIndex
{
    NSMutableArray* order = getTokenOrder(def);
    NSString* key = [order objectAtIndex:fromIndex];
    if (key == nil)
        return;

    [order removeObjectAtIndex:fromIndex];
    [order insertObject:key atIndex:toIndex];

    [def setObject:order forKey:TOKEN_ORDER];
    [def synchronize];
}
@end
