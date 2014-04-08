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

#import "ReorderableViewController.h"
#import "TokenStore.h"

@implementation ReorderableViewController
{
    NSIndexPath* origPath;
    NSIndexPath* lastPath;
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

        origPath = lastPath = currPath;

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

            // Reset state.
            cell.transform = CGAffineTransformMakeScale(1.1f, 1.1f); // Moving the token resets the size...
            [self.collectionView bringSubviewToFront:cell]; // ... and Z index.
            lastPath = currPath;
        }

        cell.center = [gestureRecognizer locationInView:self.collectionView];
        return;

    case UIGestureRecognizerStateEnded:
        if (lastPath == nil || origPath == nil) {
            [self.collectionView reloadData];
            return; // Invalid state
        }

        // Write changes if successful.
        if (origPath.row != lastPath.row) {
            TokenStore* ts = [[TokenStore alloc] init];
            [ts moveFrom:origPath.row to:lastPath.row];
        }

        // Animate back to the original state, but in the new location.
        cell = [self.collectionView cellForItemAtIndexPath:lastPath];
        {[UIView animateWithDuration:0.3f animations:^{
            UICollectionViewLayout* l = self.collectionView.collectionViewLayout;
            cell.center = [l layoutAttributesForItemAtIndexPath:lastPath].center;
            cell.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        } completion:^(BOOL c){
            origPath = lastPath = nil;
        }];}
        return;

    case UIGestureRecognizerStateCancelled:
        if (lastPath == nil || origPath == nil) {
            [self.collectionView reloadData];
            return; // Invalid state
        }

        [self.collectionView reloadData];
        return;

    default:
        return;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup pan.
    UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handlePan:)];
    pgr.minimumNumberOfTouches = 1;
    pgr.maximumNumberOfTouches = 1;
    [self.collectionView addGestureRecognizer:pgr];
}
@end
