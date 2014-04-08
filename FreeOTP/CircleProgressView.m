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

    self.hollow = false;
    self.clockwise = true;
    self.threshold = 0;
    self.progress = 0.0;
    self.backgroundColor = [UIColor clearColor];
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self == nil)
        return nil;

    self.hollow = false;
    self.clockwise = true;
    self.threshold = 0;
    self.progress = 0.0;
    self.backgroundColor = [UIColor clearColor];
    return self;
}

- (void)setHollow:(BOOL)hollow {
    _hollow = hollow;
    [self setNeedsDisplay];
}

- (void)setClockwise:(BOOL)clockwise {
    _clockwise = clockwise;
    [self setNeedsDisplay];
}

- (void)setThreshold:(float)threshold {
    _threshold = threshold;
    [self setNeedsDisplay];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)xxx {
    CGFloat progress = self.clockwise ? self.progress : (1.0f - self.progress);
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MAX(MIN(self.bounds.size.height / 2.0, self.bounds.size.width / 2.0) - 4, 1);
    CGFloat radians = MAX(MIN(progress * 2 * M_PI, 2 * M_PI), 0);

    UIColor* color = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    if (self.threshold < 0 && self.progress < fabsf(self.threshold))
        color = [UIColor colorWithRed:1.0 green:self.progress * (1 / fabsf(self.threshold)) blue:0.0 alpha:1.0];
    else if (self.threshold > 0 && self.progress > self.threshold)
        color = [UIColor colorWithRed:1.0 green:(1 - self.progress) * (1 / (1 - self.threshold)) blue:0.0 alpha:1.0];

    UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:center radius:radius
                             startAngle:-M_PI_2 endAngle:radians-M_PI_2 clockwise:self.clockwise];
    if (self.hollow) {
        [color setStroke];
        [path setLineWidth:3.0];
        [path stroke];
    } else {
        [color setFill];
        [path addLineToPoint:center];
        [path addClip];
        UIRectFill(self.bounds);
    }
}
@end
