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

#import "AddTokenViewController.h"
#import "TokenStore.h"
#import <float.h>

#define isChecked(x) ((x) == UITableViewCellAccessoryCheckmark)

@implementation AddTokenViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ([indexPath section]) {
    case 0:
        switch ([indexPath row]) {
        case 0: // Time-based Token
            [self.totp setAccessoryType:UITableViewCellAccessoryCheckmark];
            [self.hotp setAccessoryType:UITableViewCellAccessoryNone];
            [self.intervalTitle setText:NSLocalizedString(@"Interval", nil)];
            [self.interval setMaximumValue:300];
            [self.interval setMinimumValue:5];
            [self.interval setValue:30];
            break;
        case 1: // Counter-based Token
            [self.totp setAccessoryType:UITableViewCellAccessoryNone];
            [self.hotp setAccessoryType:UITableViewCellAccessoryCheckmark];
            [self.intervalTitle setText:NSLocalizedString(@"Counter", nil)];
            [self.interval setMaximumValue:DBL_MAX];
            [self.interval setMinimumValue:0];
            [self.interval setValue:0];
            break;
        }
        [self intervalClicked:self.interval];
        break;
    case 2:
        switch ([indexPath row]) {
        case 0:
            [self.md5 setAccessoryType:UITableViewCellAccessoryCheckmark];
            [self.sha1 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha256 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha512 setAccessoryType:UITableViewCellAccessoryNone];
            break;
        case 1:
            [self.md5 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha1 setAccessoryType:UITableViewCellAccessoryCheckmark];
            [self.sha256 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha512 setAccessoryType:UITableViewCellAccessoryNone];
            break;
        case 2:
            [self.md5 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha1 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha256 setAccessoryType:UITableViewCellAccessoryCheckmark];
            [self.sha512 setAccessoryType:UITableViewCellAccessoryNone];
            break;
        case 3:
            [self.md5 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha1 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha256 setAccessoryType:UITableViewCellAccessoryNone];
            [self.sha512 setAccessoryType:UITableViewCellAccessoryCheckmark];
            break;
        }
        break;

    default:
        break;
    }
}

- (IBAction)requiredValueChanged:(id)sender {
    BOOL allValues = ![[self.issuer text] isEqualToString:@""] &&
                     ![[self.uid text] isEqualToString:@""] &&
                      [[self.secret text] length] > 0 &&
                      [[self.secret text] length] % 8 == 0;
    [self.navigationItem.rightBarButtonItem setEnabled:allValues];
}

- (IBAction)intervalClicked:(id)sender {
    int value = (int)[((UIStepper*) sender) value];
    [self.intervalLabel setText:[NSString stringWithFormat:@"%d", value]];
}

- (IBAction)digitsClicked:(id)sender {
    int value = (int)[((UIStepper*) sender) value];
    [self.digitsLabel setText:[NSString stringWithFormat:@"%d", value]];
}

- (IBAction)addClicked:(id)sender {
    // Get algorithm
    const char *algo = "sha1";
    if (isChecked(self.md5.accessoryType))
        algo = "md5";
    else if (isChecked(self.sha256.accessoryType))
        algo = "sha256";
    else if (isChecked(self.sha512.accessoryType))
        algo = "sha512";
    
    // Built URI
    NSURLComponents* urlc = [[NSURLComponents alloc] init];
    urlc.scheme = @"otpauth";
    urlc.host = isChecked(self.totp.accessoryType) ? @"totp" : @"hotp";
    urlc.path = [NSString stringWithFormat:@"/%@:%@", self.issuer.text, self.uid.text];
    urlc.query = [NSString stringWithFormat:@"algorithm=%s&digits=%lu&secret=%@&%s=%lu",
                  algo, (unsigned long) self.digits.value, self.secret.text,
                  isChecked(self.totp.accessoryType) ? "period" : "counter",
                  (unsigned long) self.interval.value];

    // Make token
    Token* token = [[Token alloc] initWithURL:[urlc URL]];
    if (token != nil)
        [[[TokenStore alloc] init] add:token];
    
    // Return
    if (self.popover == nil)
        [self.navigationController popViewControllerAnimated:YES];
    else {
        [self.popover dismissPopoverAnimated:YES];
        [self.popover.delegate popoverControllerDidDismissPopover:self.popover];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* newstr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    const char *newbuf = [newstr UTF8String];
    
    BOOL unpadded = NO;
    for (unsigned long i = [newstr length]; i > 0; i--) {
        if (!unpadded) {
            if (newbuf[i - 1] == '=')
                continue;
            else
                unpadded = YES;
        }
        if (!strchr("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ234567",
                    newbuf[i - 1]))
            return NO;
    }
    
    return YES;
}
@end
