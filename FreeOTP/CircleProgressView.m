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

#import "CircleProgressView.h"

@implementation CircleProgressView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil)
        return nil;

    self.progress = 0.0;
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self == nil)
        return nil;

    self.progress = 0.0;
    return self;
}

- (void)setProgress:(float)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)xxx {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MIN(self.bounds.size.height / 2.0, self.bounds.size.width / 2.0);
    CGFloat radians = MAX(MIN((1.0 - self.progress) * 2 * M_PI, 2 * M_PI), 0);

    UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:center radius:radius
                            startAngle:-M_PI_2 endAngle:radians-M_PI_2 clockwise:YES];
    [path addLineToPoint:center];
    [path addClip];
    [[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] setFill];
    UIRectFill(self.bounds);
}
@end
