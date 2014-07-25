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

#import "CollectionViewController.h"

#import "AddTokenViewController.h"
#import "QRCodeScanViewController.h"
#import "RenameTokenViewController.h"
#import "TokenImagePickerController.h"

#import "BlockActionSheet.h"
#import "TokenCell.h"
#import "TokenStore.h"

@interface CollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController* popover;
@end

@implementation CollectionViewController
{
    TokenStore* store;
    NSIndexPath* lastPath;
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

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    UICollectionViewCell* cell = nil;

    // Get the current index path.
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *currPath = [self.collectionView indexPathForItemAtPoint:p];

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (currPath != nil)
                cell = [self.collectionView cellForItemAtIndexPath:currPath];
            if (cell == nil)
                return; // Invalid state

            lastPath = currPath;

            cell = [self.collectionView cellForItemAtIndexPath:currPath];
        {[UIView animateWithDuration:0.3f animations:^{
            cell.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
            [self.collectionView bringSubviewToFront:cell];
        }];}

        case UIGestureRecognizerStateChanged:
            if (lastPath != nil)
                cell = [self.collectionView cellForItemAtIndexPath:lastPath];
            if (cell == nil)
                return; // Invalid state

            if (currPath != nil && lastPath.row != currPath.row) {
                // Move the display.
                [self.collectionView moveItemAtIndexPath:lastPath toIndexPath:currPath];

                // Scroll the display to handle moving tokens up or down.
                if (lastPath.row < currPath.row)
                    [self.collectionView scrollToItemAtIndexPath:currPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
                else
                    [self.collectionView scrollToItemAtIndexPath:currPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];

                // Write changes.
                TokenStore* ts = [[TokenStore alloc] init];
                [ts moveFrom:lastPath.row to:currPath.row];

                // Reset state.
                cell.transform = CGAffineTransformMakeScale(1.1f, 1.1f); // Moving the token resets the size...
                [self.collectionView bringSubviewToFront:cell]; // ... and Z index.
                lastPath = currPath;
            }

            cell.center = [gestureRecognizer locationInView:self.collectionView];
            return;

        case UIGestureRecognizerStateEnded:
            if (lastPath == nil) {
                [self.collectionView reloadData];
                return; // Invalid state
            }

            // Animate back to the original state, but in the new location.
            cell = [self.collectionView cellForItemAtIndexPath:lastPath];
        {[UIView animateWithDuration:0.3f animations:^{
            UICollectionViewLayout* l = self.collectionView.collectionViewLayout;
            cell.center = [l layoutAttributesForItemAtIndexPath:lastPath].center;
            cell.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        } completion:^(BOOL c){
            lastPath = nil;
        }];}
            return;

        case UIGestureRecognizerStateCancelled:
            if (lastPath == nil) {
                [self.collectionView reloadData];
                return; // Invalid state
            }

            [self.collectionView reloadData];
            return;

        default:
            return;
    }
}

- (IBAction)addClicked:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self performSegueWithIdentifier:@"addToken" sender:self];
        return;
    }

    AddTokenViewController* c = [self.storyboard instantiateViewControllerWithIdentifier:@"addToken"];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:c];

    c.popover = self.popover = [[UIPopoverController alloc] initWithContentViewController:nc];
    self.popover.delegate = self;
    self.popover.popoverContentSize = CGSizeMake(320, 715);
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)scanClicked:(id)sender
{
    [self performSegueWithIdentifier:@"scanToken" sender:self];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
    [self.collectionView reloadData];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;

    // Get the index path.
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath == nil)
        return;

    // Get the cell.
    TokenCell* cell = (TokenCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell == nil)
        return;

    // Create the action sheet.
    BlockActionSheet* as = [[BlockActionSheet alloc] init];

    // On iPads, the sheet points to the token.
    // Otherwise, add a title to make the context clear.
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
        as.title = [NSString stringWithFormat:@"%@\n%@", cell.issuer.text, cell.label.text];

    // If the token is active, show the copy button.
    TokenCode* tc = cell.state;
    if (tc != nil && tc.currentCode != nil)
        [as addButtonWithTitle:NSLocalizedString(@"Copy", nil)];

    // Add the remaining buttons.
    [as addButtonWithTitle:NSLocalizedString(@"Change Icon", nil)];
    [as addButtonWithTitle:NSLocalizedString(@"Rename", nil)];
    as.destructiveButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

    [as showFromRect:cell.frame inView:self.collectionView animated:YES];
    as.callback = ^(NSInteger offset) {
        switch (offset) {
            case 1: { // Delete
                BlockActionSheet* as = [[BlockActionSheet alloc] init];

                as.title = NSLocalizedString(@"Are you sure?", nil);
                if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
                    as.title = [NSString stringWithFormat:@"%@\n\n%@\n%@", as.title, cell.issuer.text, cell.label.text];

                as.destructiveButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
                as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [as showFromRect:cell.frame inView:self.collectionView animated:YES];
                as.callback = ^(NSInteger offset) {
                    if (offset != 1)
                        return;

                    [[[TokenStore alloc] init] del:indexPath.row];
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                };

                break;
            }

            case 2: { // Rename
                RenameTokenViewController* c = [self.storyboard instantiateViewControllerWithIdentifier:@"renameToken"];
                c.token = indexPath.row;
                UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:c];
                if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
                    [self presentViewController:nc animated:YES completion:nil];
                } else {
                    c.popover = self.popover = [[UIPopoverController alloc] initWithContentViewController:nc];
                    self.popover.delegate = self;
                    self.popover.popoverContentSize = CGSizeMake(320, 375);

                    [self.popover presentPopoverFromRect:cell.frame inView:self.collectionView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                }

                break;
            }

            case 3: { // Change Icon
                TokenImagePickerController* ipc = [[TokenImagePickerController alloc] initWithTokenID:indexPath.row];
                if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
                    [self presentViewController:ipc animated:YES completion:nil];
                } else {
                    ipc.popover = self.popover = [[UIPopoverController alloc] initWithContentViewController:ipc];
                    self.popover.delegate = self;
                    [self.popover presentPopoverFromRect:cell.frame inView:self.collectionView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                }
            }

            case 4: { // Copy
                TokenCode* tc = cell.state;
                if (tc != nil) {
                    NSString* code = tc.currentCode;
                    if (code != nil)
                        [[UIPasteboard generalPasteboard] setString:code];
                }
                break;
            }
        }
    };
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup store.
    store = [[TokenStore alloc] init];

    // Setup collection view.
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.delegate = self;

    // Setup pan.
    UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handlePan:)];
    pgr.minimumNumberOfTouches = 1;
    pgr.maximumNumberOfTouches = 1;
    [self.collectionView addGestureRecognizer:pgr];

    // Setup long-press.
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0;
    [self.collectionView addGestureRecognizer:lpgr];

    // Setup buttons.
    UIBarButtonItem* add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClicked:)];
    if ([AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] == nil) {
        self.navigationItem.rightBarButtonItems = @[add];
    } else {
        id icon = [UIImage imageNamed:@"qrcode.png"];
        id scan = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStylePlain target:self action:@selector(scanClicked:)];
        self.navigationItem.rightBarButtonItems = @[add, scan];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

@end
