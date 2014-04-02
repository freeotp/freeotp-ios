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

@implementation RenameTokenViewController
- (void)viewWillAppear:(BOOL)animated {
    TokenStore* ts = [[TokenStore alloc] init];
    Token* t = [ts get:self.token];
    self.issuer.text = t.issuer;
    self.label.text = t.label;
    self.issuerDefault.text = t.issuerDefault;
    self.labelDefault.text = t.labelDefault;
}

- (IBAction)resetClicked:(id)sender {
    self.issuer.text = self.issuerDefault.text;
    self.label.text = self.labelDefault.text;
}

- (IBAction)doneClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    TokenStore* ts = [[TokenStore alloc] init];
    Token* t = [ts get:self.token];
    t.issuer = self.issuer.text;
    t.label = self.label.text;
    [ts save:t];
}
@end
