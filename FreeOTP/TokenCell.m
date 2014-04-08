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

#import "TokenCell.h"

@implementation TokenCell
{
    NSTimer* timer;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self == nil)
        return nil;

    self.layer.cornerRadius = 2.0f;
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil)
        return nil;

    self.layer.cornerRadius = 2.0f;
    return self;
}

- (BOOL)bind:(Token*)token
{
    self.state = nil;

    if (token == nil)
        return NO;

    unichar tmp[token.digits];
    for (NSUInteger i = 0; i < sizeof(tmp) / sizeof(unichar); i++)
        tmp[i] = [self.placeholder.text characterAtIndex:0];

    self.image.url = token.image;
    self.placeholder.text = [NSString stringWithCharacters:tmp length:sizeof(tmp) / sizeof(unichar)];
    self.outer.hidden = ![token.type isEqualToString:@"totp"];
    self.issuer.text = token.issuer;
    self.label.text = token.label;
    self.code.text = @"";

    return YES;
}

- (void)timerCallback:(NSTimer*)timer
{
    NSString* str = self.state.currentCode;
    if (str == nil) {
        self.state = nil;
        return;
    }

    self.inner.progress = self.state.currentProgress;
    self.outer.progress = self.state.totalProgress;
    self.code.text = str;
}

- (void)setState:(TokenCode *)state
{
    if (_state == state)
        return;

    if (state == nil) {
        [UIView animateWithDuration:0.5f animations:^{
            self.placeholder.alpha = 1.0f;
            self.inner.alpha = 0.0f;
            self.outer.alpha = 0.0f;
            self.image.alpha = 1.0f;
            self.code.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.outer.progress = 0.0f;
            self.inner.progress = 0.0f;
            self.code.text = @"";
        }];

        if (self->timer != nil) {
            [self->timer invalidate];
            self->timer = nil;
        }
    } else if (self->timer == nil) {
        self->timer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self
                                               selector: @selector(timerCallback:)
                                               userInfo: nil repeats: YES];

        // Setup the UI for progress.
        [UIView animateWithDuration:0.5f animations:^{
            self.placeholder.alpha = 0.0f;
            self.inner.alpha = 1.0f;
            self.outer.alpha = 1.0f;
            self.image.alpha = 0.1f;
            self.code.alpha = 1.0f;
        }];
    }

    _state = state;
}
@end
