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

#import "CircleProgressView.h"
#import "Token.h"
#import "TokenCode.h"
#import "URLImageView.h"

@interface TokenCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet URLImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *code;
@property (weak, nonatomic) IBOutlet UILabel *issuer;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *placeholder;
@property (weak, nonatomic) IBOutlet CircleProgressView *outer;
@property (weak, nonatomic) IBOutlet CircleProgressView *inner;
@property (strong, nonatomic) TokenCode* state;
- (BOOL)bind:(Token*)token;
@end
