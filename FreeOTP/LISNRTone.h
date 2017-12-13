//
//  LISNRTone.h
//  LISNR-SDK-iOS 6.0.0.1
//
//  Created by Jon Schneider on 12/1/15.
//  Copyright © 2015 LISNR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LISNRToneSampleRate) {
    LISNRToneSampleRate44100 = 44100,
    LISNRToneSampleRate48000 = 48000,
    LISNRToneSampleRateDefault = LISNRToneSampleRate48000
};

@interface LISNRTone : NSObject

/**
 *  The sample rate of the audio file generated for this tone
 */
@property (readonly) int sampleRate;

/**
 *  The number of iterations you want of this tone
 */
@property (readonly) int iterations;

/**
 *  The number of iterations you want of this tone
 */
@property (readonly) NSString* profile;

/**
 *  Returns a .wav file of this tone
 *
 *  @return A .wav file of this tone, returned as NSData
 */
- (NSData * _Nonnull) WAVFileForTone;

/**
 *  Writes a .wav file of this tone to the passed path
 *
 *  @param path The path to write this tone to
 *
 *  @warning Behavior when writing to invalid paths is undefined - validate your path before calling this method
 */
- (void) writeToneToPath:(NSString * _Nonnull)path;

@end
