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

@import AVFoundation;

#import "ButtonsAndMenusViewController.h"

#import "AddTokenViewController.h"
#import "QRCodeScanViewController.h"
#import "RenameTokenViewController.h"
#import "TokenImagePickerController.h"

#import "BlockActionSheet.h"
#import "TokenCell.h"
#import "TokenStore.h"

@interface ButtonsAndMenusViewController () <UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController* popover;
@end

@implementation ButtonsAndMenusViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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
@end
