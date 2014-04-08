//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2014  Nathaniel McCallum, Red Hat
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

#import "BaseViewController.h"
#import "TokenCell.h"
#import "TokenStore.h"

@interface BaseViewController ()  <UICollectionViewDataSource, UICollectionViewDelegate>
@end

@implementation BaseViewController
{
    TokenStore* store;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return store.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((int) collectionView.frame.size.width) {
    case 1024: // iPad
    case 768:  // iPad
        return CGSizeMake(328, 96);

    case 568:  // iPhone5 landscape
    case 320:  // iPhone* portrait
        return CGSizeMake(269, 80);

    case 480:  // iPhone4 landscape
    default:
        return CGSizeMake(225, 64);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* name = nil;
    switch ((int) collectionView.frame.size.width) {
    case 1024: // iPad
    case 768:  // iPad
        name = @"iPad";
        break;

    case 568:  // iPhone5 landscape
    case 320:  // iPhone* portrait
        name = @"iPhone5";
        break;

    case 480:  // iPhone4 landscape
    default:
        name = @"iPhone4";
        break;
    }

    TokenCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:name forIndexPath:indexPath];
    return [cell bind:[store get:indexPath.row]] ? cell : nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // If the device is smaller than an iPhone5,
    // then reload the data to pick up the new cell size.
    // This is unfortunate because it resets token UI state.
    // However, this works until we get completely dynamic resizing.
    if ([[UIScreen mainScreen] bounds].size.height < 568)
        [self.collectionView reloadData];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Perform animation.
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    // Get the current cell.
    TokenCell* cell = (TokenCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell == nil)
        return;

    // Get the selected token.
    Token* token = [store get:indexPath.row];
    if (token == nil)
        return;

    // Get the token code and save the token state.
    cell.state = token.code;
    [store save:token];
}

- (void)viewDidLoad
{
    // Setup store.
    store = [[TokenStore alloc] init];

    // Setup collection view.
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.delegate = self;

    [super viewDidLoad];
}
@end
