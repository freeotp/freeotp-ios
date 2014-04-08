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

#import "URLImageView.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation URLImageView
- (void)setUrl:(NSURL *)url {
    _url = url;

    if (url.isFileURL) {
        self.image = [UIImage imageWithContentsOfFile:url.path];
        return;
    }

    if ([url.scheme isEqualToString:@"assets-library"]) {
        ALAssetsLibrary* al = [[ALAssetsLibrary alloc] init];
        [al assetForURL:url
            resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                @autoreleasepool {
                    CGImageRef iref = [rep fullScreenImage];
                    if (iref) {
                        UIImage *image = [UIImage imageWithCGImage:iref];
                        self.image = image;
                        iref = nil;
                    }
                }
            }
           failureBlock:nil];
        return;
    }
}
@end
