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

    self.inner = 0.0;
    self.outer = 0.0;
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self == nil)
        return nil;

    self.inner = 0.0;
    self.outer = 0.0;
    return self;
}

- (void)setDonut:(BOOL)donut {
    _donut = donut;
    [self setNeedsDisplay];
}

- (void)setInner:(float)inner {
    _inner = inner;
    [self setNeedsDisplay];
}

- (void)setOuter:(float)outer {
    _outer = outer;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)xxx {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    int padding = 4;
    if (self.donut) {
        CGFloat outerRadius = MAX(MIN(self.bounds.size.height / 2.0, self.bounds.size.width / 2.0) - padding, 1);
        CGFloat outerRadians = MAX(MIN((1.0 - self.outer) * 2 * M_PI, 2 * M_PI), 0);
        [[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] setStroke];
        UIBezierPath* outerPath = [UIBezierPath bezierPathWithArcCenter:center radius:outerRadius
                                    startAngle:-M_PI_2 endAngle:outerRadians-M_PI_2 clockwise:YES];
        [outerPath setLineWidth:3.0];
        [outerPath stroke];

        padding += 4;
    }

    CGFloat innerRadius = MAX(MIN(self.bounds.size.height / 2.0, self.bounds.size.width / 2.0) - padding, 1);
    CGFloat innerRadians = MAX(MIN((1.0 - self.inner) * 2 * M_PI, 2 * M_PI), 0);
    if (self.inner < 0.75)
        [[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] setFill];
    else
        [[UIColor colorWithRed:1.0 green:(1 - self.inner) * 4 blue:0.0 alpha:1.0] setFill];
    UIBezierPath* innerPath = [UIBezierPath bezierPathWithArcCenter:center radius:innerRadius
                                    startAngle:-M_PI_2 endAngle:innerRadians-M_PI_2 clockwise:YES];
    [innerPath addLineToPoint:center];
    [innerPath addClip];
    UIRectFill(self.bounds);
}
@end
