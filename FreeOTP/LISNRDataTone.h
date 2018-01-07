//
//  LISNRDataTone.h
//  LISNR-SDK-iOS 6.0.0.1
//
//  Created by Jon Schneider on 12/18/15.
//  Copyright © 2015 LISNR. All rights reserved.
//

#import "LISNRTone.h"

@interface LISNRDataTone : LISNRTone

/**
 *  The data payload of this tone
 */
@property (strong, nonatomic, readonly, nonnull) NSData * data;

/**
 *  Creates a tone with a data playload.
 *
 *  @param data    The data payload of the tone
 *  @param iterations The number of iterations of this tone you would like to generate
 *  @param sampleRate The sample rate of the tone audio file you will create in hertz. Suggested input is LISNRToneSampleRateDefault.
 *  @param error An NSError ** that will be set to an NSError if there is an initialization error.
 *
 *  @return A LISNRDataTone object that can be used to play this tone.
 */
+ (LISNRDataTone * _Nullable) toneWithData:(NSData * _Nonnull)data iterations:(int)iterations sampleRate:(LISNRToneSampleRate)sampleRate error:(NSError * _Nullable * _Nullable)error;

/**
 *  Creates a tone with a data playload.
 *
 *  @param data    The data payload of the tone
 *  @param iterations The number of iterations of this tone you would like to generate
 *  @param sampleRate The sample rate of the tone audio file you will create in hertz. Suggested input is LISNRToneSampleRateDefault.
 *  @param profile The profile of the tone for broadcast
 *  @param error An NSError ** that will be set to an NSError if there is an initialization error.
 *
 *  @return A LISNRDataTone object that can be used to play this tone.
 */
+ (LISNRDataTone * _Nullable) toneWithData:(NSData * _Nonnull)data iterations:(int)iterations sampleRate:(LISNRToneSampleRate)sampleRate profile:(NSString*)profile error:(NSError * _Nullable * _Nullable)error;


@end
