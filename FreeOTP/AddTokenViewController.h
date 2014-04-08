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

@interface AddTokenViewController : UITableViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableViewCell *totp;
@property (weak, nonatomic) IBOutlet UITableViewCell *hotp;
@property (weak, nonatomic) IBOutlet UITextField *issuer;
@property (weak, nonatomic) IBOutlet UITextField *uid;
@property (weak, nonatomic) IBOutlet UITextField *secret;
@property (weak, nonatomic) IBOutlet UILabel *intervalTitle;
@property (weak, nonatomic) IBOutlet UIStepper *interval;
@property (weak, nonatomic) IBOutlet UILabel *intervalLabel;
@property (weak, nonatomic) IBOutlet UIStepper *digits;
@property (weak, nonatomic) IBOutlet UILabel *digitsLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *md5;
@property (weak, nonatomic) IBOutlet UITableViewCell *sha1;
@property (weak, nonatomic) IBOutlet UITableViewCell *sha256;
@property (weak, nonatomic) IBOutlet UITableViewCell *sha512;
@property (weak, nonatomic) UIPopoverController *popover;
- (IBAction)requiredValueChanged:(id)sender;
- (IBAction)intervalClicked:(id)sender;
- (IBAction)digitsClicked:(id)sender;
- (IBAction)addClicked:(id)sender;
@end
