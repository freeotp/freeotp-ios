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

#import "TokenImagePickerController.h"
#import "TokenStore.h"

@interface TokenImagePickerController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation TokenImagePickerController
{
    NSUInteger _tokenID;
}

- (id)initWithTokenID:(NSUInteger)tokenID
{
    self = [self init];
    if (self == nil)
        return nil;

    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.delegate = self;

    _tokenID = tokenID;
    return self;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL* url = [info objectForKey:UIImagePickerControllerReferenceURL];

    TokenStore* ts = [[TokenStore alloc] init];
    Token* t = [ts get:_tokenID];
    t.image = url;
    [ts save:t];

    [self cancel:nil];
}

- (void)cancel:(id)sender
{
    if (self.popover == nil) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.popover dismissPopoverAnimated:YES];
        [self.popover.delegate popoverControllerDidDismissPopover:self.popover];
    }
}

- (void)reset:(id)sender
{
    TokenStore* ts = [[TokenStore alloc] init];
    Token* t = [ts get:_tokenID];
    t.image = t.imageDefault;
    [ts save:t];

    [self cancel:sender];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (navigationController.viewControllers.count > 0 && viewController == [navigationController.viewControllers objectAtIndex:0]) {
        viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Default", nil)
                                                                                            style:UIBarButtonItemStylePlain
                                                                                           target:self
                                                                                           action:@selector(reset:)];
        if (self.popover == nil)
            viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                            target:self
                                                                                                            action:@selector(cancel:)];
    }
}
@end
