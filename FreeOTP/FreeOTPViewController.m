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

@import AVFoundation;
#import "FreeOTPViewController.h"
#import "CircleProgressView.h"
#import "TokenStore.h"

@implementation FreeOTPViewController
{
    TokenStore* store;
    NSTimer* timer;
    uint8_t empty;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return empty + store.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (empty)
        return [tableView dequeueReusableCellWithIdentifier:@"empty"];

    Token* token = [store get:[indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[token type]];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    char value[token.digits + 1];
    value[token.digits] = '\0';
    for (long i = token.digits - 1; i >= 0; i--)
        value[i] = '-';
    [label setText:[NSString stringWithFormat:@"%s", value]];
    
    label = (UILabel *)[cell.contentView viewWithTag:2];
    [label setText:[token issuer]];
    
    label = (UILabel *)[cell.contentView viewWithTag:3];
    [label setText:[token label]];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !empty;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !empty;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [store moveFrom:sourceIndexPath.row to:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;

    Token* token = [store get:[indexPath row]];
    if (token == nil)
        return;

    [store del:[indexPath row]];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                    withRowAnimation:UITableViewRowAnimationLeft];

    empty = store.count == 0 ? 1 : 0;
    self.navigationItem.leftBarButtonItem.enabled = !empty;
    [self.tableView reloadData];

    // If we are in edit mode and we deleted the last item, exit edit mode.
    if (empty && self.tableView.isEditing)
        [self editButtonClicked:self.navigationItem.leftBarButtonItem];
}

- (IBAction)addButtonClicked:(id)sender
{
    // If no capture device exists (mainly the simulator), don't show the menu.
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device == nil) {
        [self performSegueWithIdentifier:@"addToken" sender:self];
        return;
    }

    [[[UIActionSheet alloc]
      initWithTitle:NSLocalizedString(@"How will we add the token?", nil)
      delegate:self
      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
      destructiveButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"Scan QR Code", nil),
                        NSLocalizedString(@"Manual Entry", nil),
                        nil]
     showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
    case 0:
        [self performSegueWithIdentifier:@"scanToken" sender:self];
        break;
    case 1:
        [self performSegueWithIdentifier:@"addToken" sender:self];
        break;
    }
}

- (IBAction)editButtonClicked:(id)sender
{
    if ([self.navigationItem.leftBarButtonItem.title isEqualToString:NSLocalizedString(@"Edit", nil)]) {
        self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Done", nil);
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.tableView beginUpdates];
        [self.tableView setEditing:YES animated:YES];
        [self.tableView endUpdates];

        for (long i = [self.tableView numberOfRowsInSection:0] - 1; i >= 0; i--) {
            NSUInteger idx[2] = { 0, i };
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2]];
            if (cell == nil)
                continue;

            UIView* v = (CircleProgressView*)[cell.contentView viewWithTag:4];
            if (v == nil)
                continue;

            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 CGRect f = v.frame;
                                 f.origin.x -= 26;
                                 v.frame = f;
                             }
                             completion:^(BOOL finished) {}];
        }
    } else {
        for (long i = [self.tableView numberOfRowsInSection:0] - 1; i >= 0; i--) {
            NSUInteger idx[2] = { 0, i };
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2]];
            if (cell == nil)
                continue;

            UIView* v = (CircleProgressView*)[cell.contentView viewWithTag:4];
            if (v == nil)
                continue;

            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options: UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 CGRect f = v.frame;
                                 f.origin.x += 26;
                                 v.frame = f;
                             }
                             completion:^(BOOL finished) {}];
        }

        self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStylePlain;
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Edit", nil);
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.tableView beginUpdates];
        [self.tableView setEditing:NO animated:YES];
        [self.tableView endUpdates];
    }
}

- (void)timerCallback:(NSTimer*)timer
{
    long totpCount = 0;
    for (long i = store.count - 1; i >= 0; i--) {
        Token* token = [store get:i];
        if (![[token type] isEqualToString:@"totp"])
            continue;
        totpCount++;

        NSUInteger idx[2] = { 0, i };
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2]];
        if (cell == nil)
            continue;
        
        UILabel* l = (UILabel*)[cell.contentView viewWithTag:1];
        [l setText:[token value]];
        [l setTextColor:[UIColor blackColor]];

        CircleProgressView* cpv = (CircleProgressView*)[cell.contentView viewWithTag:4];
        cpv.progress = [token progress];
    }

    // If we have no TOTP tokens, we can cancel the timer.
    if (totpCount == 0) {
        [self->timer invalidate];
        self->timer = nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Token* token = [store get:[indexPath row]];
    if (token == nil)
        return;
    if (![[token type] isEqualToString:@"hotp"])
        return;

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    [label setText:[token value]];
    [label setTextColor:[UIColor blackColor]];
    [token increment];
    
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setObject:[token description] forKey:[token uid]];
    [def synchronize];
}

- (void)viewDidLoad
{
    store = [[TokenStore alloc] init];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    empty = store.count == 0 ? 1 : 0;
    self.navigationItem.leftBarButtonItem.enabled = !empty;
    [self.tableView reloadData];
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self
                                           selector: @selector(timerCallback:)
                                           userInfo: nil repeats: YES];
}
@end
