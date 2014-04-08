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

#import "RenameTokenViewController.h"
#import "TokenStore.h"

@interface RenameTokenViewController () <UITextFieldDelegate>
@end

@implementation RenameTokenViewController
- (void)viewWillAppear:(BOOL)animated
{
    if (self.popover != nil)
        self.navigationItem.leftBarButtonItem = nil;

    TokenStore* ts = [[TokenStore alloc] init];
    Token* t = [ts get:self.token];
    self.issuer.text = t.issuer;
    self.label.text = t.label;
    self.issuerDefault.text = t.issuerDefault;
    self.labelDefault.text = t.labelDefault;

    self.issuer.delegate = self;
    self.label.delegate = self;
    [self textField:self.issuer shouldChangeCharactersInRange:NSRangeFromString(@"") replacementString:@""];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL issuer, label;

    string = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (textField == self.issuer)
        issuer = [string isEqualToString:self.issuerDefault.text];
    else
        issuer = [self.issuer.text isEqualToString:self.issuerDefault.text];

    if (textField == self.label)
        label = [string isEqualToString:self.labelDefault.text];
    else
        label = [self.label.text isEqualToString:self.labelDefault.text];

    self.button.enabled = !issuer || !label;
    return YES;
}

- (IBAction)resetClicked:(id)sender
{
    self.issuer.text = self.issuerDefault.text;
    self.label.text = self.labelDefault.text;
    [self textField:self.issuer shouldChangeCharactersInRange:NSRangeFromString(@"") replacementString:@""];
}

- (IBAction)doneClicked:(id)sender
{
    TokenStore* ts = [[TokenStore alloc] init];
    Token* t = [ts get:self.token];
    t.issuer = self.issuer.text;
    t.label = self.label.text;
    [ts save:t];

    [self cancelClicked:sender];
}

- (IBAction)cancelClicked:(id)sender {
    if (self.popover == nil)
        [self dismissViewControllerAnimated:YES completion:nil];
    else {
        [self.popover dismissPopoverAnimated:YES];
        [self.popover.delegate popoverControllerDidDismissPopover:self.popover];
    }
}
@end
