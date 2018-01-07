//
//  LISNRTextTone.h
//  LISNR-SDK-iOS 6.0.0.1
//
//  Created by Jon Schneider on 12/18/15.
//  Copyright © 2015 LISNR. All rights reserved.
//

#import "LISNRTone.h"

@interface LISNRTextTone : LISNRTone

 /**
 *  The text content of this tone.
 */
@property (strong, nonatomic, readonly, nonnull) NSString * text;

/**
 *  Creates a tone with a text playload.
 *
 *  @param text       The text to be sent. This text must be ASCII-compliant, which can be tested using the NSString method 'canBeConvertedToEncoding:', e.g. [text canBeConvertedToEncoding:NSASCIIStringEncoding];
 *  @param iterations The number of iterations of this tone you would like to generate
 *  @param sampleRate The sample rate of the tone audio file you will create in hertz. Suggested input is LISNRToneSampleRateDefault.
 *  @param error An NSError ** that will be set to an NSError if there is an initialization error.
 *
 *  @return A LISNRTextTone object that can be used to broadcast this tone.
 */
+ (LISNRTextTone * _Nullable) toneWithText:(NSString * _Nonnull)text iterations:(int)iterations sampleRate:(LISNRToneSampleRate)sampleRate error:(NSError * _Nullable * _Nullable)error;

/**
 *  Creates a tone with a text playload.
 *
 *  @param text       The text to be sent. This text must be ASCII-compliant, which can be tested using the NSString method 'canBeConvertedToEncoding:', e.g. [text canBeConvertedToEncoding:NSASCIIStringEncoding];
 *  @param iterations The number of iterations of this tone you would like to generate
 *  @param sampleRate The sample rate of the tone audio file you will create in hertz. Suggested input is LISNRToneSampleRateDefault.
 *  @param profile The profile of the tone tobe used when broadcasting the tone
 *  @param error An NSError ** that will be set to an NSError if there is an initialization error.
 *
 *  @return A LISNRTextTone object that can be used to broadcast this tone.
 */
+ (LISNRTextTone * _Nullable) toneWithText:(NSString * _Nonnull)text iterations:(int)iterations sampleRate:(LISNRToneSampleRate)sampleRate profile:(NSString* _Nonnull)profile error:(NSError * _Nullable * _Nullable)error;
@end
