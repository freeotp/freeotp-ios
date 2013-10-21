//
//  AddTokenViewController.m
//  FreeOTP
//
//  Created by Nathaniel McCallum on 10/11/13.
//  Copyright (c) 2013 Nathaniel McCallum. All rights reserved.
//
#import "AddTokenViewController.h"
#import "Token.h"
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
                    [self.intervalTitle setText:@"Interval"];
                    [self.interval setMaximumValue:300];
                    [self.interval setMinimumValue:5];
                    [self.interval setValue:30];
                    break;
                case 1: // Counter-based Token
                    [self.totp setAccessoryType:UITableViewCellAccessoryNone];
                    [self.hotp setAccessoryType:UITableViewCellAccessoryCheckmark];
                    [self.intervalTitle setText:@"Counter"];
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
    if (token != nil) {
        // Store
        NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
        if ([def stringForKey:[token uid]] == nil) {
            NSMutableArray* order = [NSMutableArray arrayWithArray:[def objectForKey:TOKEN_ORDER]];
            [order insertObject:[token uid] atIndex:0];
            [def setObject:order forKey:TOKEN_ORDER];
        }
        [def setObject:[token description] forKey:[token uid]];
        [def synchronize];
    }
    
    // Return
    [self.navigationController popViewControllerAnimated:YES];
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
