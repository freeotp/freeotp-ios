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

#import "TokenCode.h"

static uint64_t currentTimeInMilli()
{
    struct timeval tv;

    if (gettimeofday(&tv, NULL) != 0)
        return 0;

    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

@implementation TokenCode
{
    TokenCode* nextCode;
    NSString* codeText;
    uint64_t startTime;
    uint64_t endTime;
}

- (id)initWithCode:(NSString*)code startTime:(time_t)start endTime:(time_t)end
{
    codeText = code;
    startTime = start * 1000;
    endTime = end * 1000;
    nextCode = nil;
    return self;
}

- (id)initWithCode:(NSString*)code startTime:(time_t)start endTime:(time_t)end nextTokenCode:(TokenCode*)next
{
    self = [self initWithCode:code startTime:start endTime:end];
    nextCode = next;
    return self;
}

- (NSString*)currentCode
{
    uint64_t now = currentTimeInMilli();

    if (now < startTime)
        return nil;

    if (now < endTime)
        return codeText;

    if (nextCode != nil)
        return [nextCode currentCode];

    return nil;
}

- (float)currentProgress
{
    uint64_t now = currentTimeInMilli();

    if (now < startTime)
        return 0.0;

    if (now < endTime) {
        float totalTime = (float) (endTime - startTime);
        return 1.0 - (now - startTime) / totalTime;
    }

    if (nextCode != nil)
        return [nextCode currentProgress];

    return 0.0;
}

- (float)totalProgress
{
    uint64_t now = currentTimeInMilli();
    TokenCode* last = self;

    if (now < startTime)
        return 0.0;

    // Find the last token code.
    while (last->nextCode != nil)
        last = last->nextCode;

    if (now < last->endTime) {
        float totalTime = (float) (last->endTime - startTime);
        return 1.0 - (now - startTime) / totalTime;
    }

    return 0.0;
}

- (NSUInteger)totalCodes {
    if (nextCode == nil)
        return 1;

    return nextCode.totalCodes + 1;
}
@end
