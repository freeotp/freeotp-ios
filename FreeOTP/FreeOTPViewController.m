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
#import "Token.h"

@implementation FreeOTPViewController
{
    NSMutableArray* tokens;
    NSMutableArray* order;
    NSTimer* timer;
    uint8_t empty;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return empty + tokens.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (empty)
        return [tableView dequeueReusableCellWithIdentifier:@"empty"];

    Token* token = [tokens objectAtIndex:[indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[token type]];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    char value[[token digits] + 1];
    for (int i = 0; i < sizeof(value) - 1; i++)
        value[i] = '-';
    value[sizeof(value) - 1] = '\0';
    [label setText:[NSString stringWithFormat:@"%s", value]];
    
    label = (UILabel *)[cell.contentView viewWithTag:2];
    [label setText:[token issuer]];
    
    label = (UILabel *)[cell.contentView viewWithTag:3];
    [label setText:[token label]];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !empty;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return !empty;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    Token* token = [tokens objectAtIndex:[sourceIndexPath row]];
    if (token == nil)
        return;
    
    [order removeObjectAtIndex:[sourceIndexPath row]];
    [tokens removeObjectAtIndex:[sourceIndexPath row]];
    [order insertObject:[token uid] atIndex:[destinationIndexPath row]];
    [tokens insertObject:token atIndex:[destinationIndexPath row]];
    
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setObject:order forKey:TOKEN_ORDER];
    [def synchronize];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;
    
    Token* token = [tokens objectAtIndex:[indexPath row]];
    if (token == nil)
        return;
    
    [order removeObjectAtIndex:[indexPath row]];
    [tokens removeObjectAtIndex:[indexPath row]];
    
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setObject:order forKey:TOKEN_ORDER];
    [def removeObjectForKey:[token uid]];
    [def synchronize];

    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                    withRowAnimation:UITableViewRowAnimationLeft];

    empty = tokens.count == 0 ? 1 : 0;
    self.navigationItem.leftBarButtonItem.enabled = !empty;
    [self.tableView reloadData];

    // If we are in edit mode and we deleted the last item, exit edit mode.
    if (empty && self.tableView.isEditing)
        [self editButtonClicked:self.navigationItem.leftBarButtonItem];

    BOOL haveTOTP = NO;
    for (Token* token in tokens) {
        if ([[token type] isEqualToString:@"totp"]) {
            haveTOTP = YES;
            break;
        }
    }
    if (!haveTOTP && timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (IBAction)addButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"addToken" sender:self];

// TODO: Add Camera support
//    [[[UIActionSheet alloc]
//      initWithTitle:@"How will we add the token?"
//      delegate:self
//      cancelButtonTitle:@"Cancel"
//      destructiveButtonTitle:nil
//      otherButtonTitles:@"Scan QR Code", @"Manual Entry", nil]
//     showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            [self performSegueWithIdentifier:@"addToken" sender:self];
    }
}

- (IBAction)editButtonClicked:(id)sender {
    if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Edit"]) {
        self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
        self.navigationItem.leftBarButtonItem.title = @"Done";
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.tableView beginUpdates];
        [self.tableView setEditing:YES animated:YES];
        [self.tableView endUpdates];
    } else {
        self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStylePlain;
        self.navigationItem.leftBarButtonItem.title = @"Edit";
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.tableView beginUpdates];
        [self.tableView setEditing:NO animated:YES];
        [self.tableView endUpdates];
    }
}

- (void)timerCallback:(NSTimer*)timer {
    for (int i = 0; i < tokens.count; i++) {
        Token* token = [tokens objectAtIndex:i];
        if (![[token type] isEqualToString:@"totp"])
            continue;
        NSUInteger idx[2] = { 0, i };
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2]];
        if (cell == nil)
            continue;
        
        UILabel *l = (UILabel *)[cell.contentView viewWithTag:1];
        [l setText:[token value]];
        
        UIProgressView* pv = (UIProgressView*)[cell.contentView viewWithTag:4];
        pv.progress = [token progress];
    }
}

- (void)startTimer:(Token*)token {
    if (![[token type] isEqualToString:@"totp"] || timer != nil)
        return;
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target: self
                     selector: @selector(timerCallback:)
                     userInfo: nil repeats: YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tokens.count == 0)
        return;

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Token* token = [tokens objectAtIndex:[indexPath row]];
    if (![[token type] isEqualToString:@"hotp"])
        return;
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1];
    [label setText:[token value]];
    [token increment];
    
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setObject:[token description] forKey:[token uid]];
    [def synchronize];
}

- (void)viewWillAppear:(BOOL)animated {
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    
    // Load token order
    NSArray* tmp = [def objectForKey:TOKEN_ORDER];
    if (tmp == nil) {
        order = [[NSMutableArray alloc] init];
        [def setObject:order forKey:TOKEN_ORDER];
        [def synchronize];
    } else
        order = [NSMutableArray arrayWithArray:tmp];
    
    // Load tokens
    tokens = [[NSMutableArray alloc] init];
    for (NSString* key in order) {
        NSString* uri = [def objectForKey:key];
        if (uri == nil)
            continue;
        
        Token* token = [[Token alloc] initWithString:uri];
        if (token == nil)
            continue;
        
        [tokens addObject:token];
        [self startTimer:token];
    }

    empty = tokens.count == 0 ? 1 : 0;
    self.navigationItem.leftBarButtonItem.enabled = !empty;

    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
