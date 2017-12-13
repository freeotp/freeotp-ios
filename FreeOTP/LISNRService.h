//
//  LISNRService.h
//  LISNR-SDK-iOS 6.0.0.1
//
//  Copyright (c) 2014 LISNR. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LISNRTone;

typedef void (^LisnrServiceInitializedCompletionBlock)( NSError * __nullable error );
typedef void (^LisnrServiceAttemptToStartListeningCompletionBlock)(NSError * __nullable error);
typedef void (^LisnrServiceToneBroadcastStartedCallbackBlock)(NSError * __nullable error, NSTimeInterval duration);
typedef void (^LisnrServiceToneAppearedCallbackBlock)(NSUInteger toneId);

typedef NS_ENUM(NSInteger, LisnrStatus) {
    LisnrStatusUnconfigured,
    LisnrStatusInactive,
    LisnrStatusBroadcasting,
    LisnrStatusListening,
    LisnrStatusInterrupted
};

/**
 *  A delegate for responding to events from the LISNRService
 */
@protocol LISNRServiceDelegate <NSObject>

@optional

/**
 *  Called whenever the LISNRService detects a tone. Dispatched on a background thread
 *
 *  @param toneId         The tone's unique identifier
 *  @param iterationIndex The tone's iteration index
 *  @param timestamp      The tone's timestamp
 */
- (void) didHearIDToneWithId:(NSUInteger)toneId iterationIndex:(NSUInteger)iterationIndex timestamp:(NSTimeInterval)timestamp;

/**
 *  Called when the first detection of a sequence of tones is detected. Dispatched on a background thread
 *
 *  @param toneId the unique ID of the tone
 *  @param iterationIndex The iteration index of the tone when it appeared
 *  @param timestamp      The timestamp of the tone when it appeared
 */
- (void) IDToneDidAppearWithId:(NSUInteger)toneId atIteration:(NSUInteger)iterationIndex atTimestamp:(NSTimeInterval)timestamp;

/**
 *  Called when the first detection of a sequence of tones is detected. Dispatched on a background thread
 *
 *  @param toneId the unique ID of the tone
 */
- (void) IDToneDidAppearWithId:(NSUInteger)toneId DEPRECATED_MSG_ATTRIBUTE("Use 'IDToneDidAppearWithId:atIteration:atTimestamp:' instead");

/**
 *  Called after the tone is no longer being detected. Always called after 'IDToneDidAppearWithId:atIteration:atTimestamp':. Dispatched on a background thread
 *
 *  @param toneId       the unique ID of the tone
 *  @param duration the length in seconds that the sdk was in presence of the tone
 */
- (void) IDToneDidDisappearWithId:(NSUInteger)toneId duration:(NSTimeInterval)duration;

/**
 *  Called when LISNRService hears a tone that contains byte data. Dispatched on a background thread
 *
 *  @param data The data received via tone.
 */
- (void) didHearDataToneWithPayload:(NSData * _Nonnull)data;

/**
 *  Called when LISNRService hears a tone that contains text data. Dispatched on a background thread
 *
 *  @param text The text received via tone.
 */
- (void) didHearTextToneWithPayload:(NSString * _Nonnull)text;

/**
 *  Called whenever the LISNRService experiences a pause due to an Audio Session interruption. During an interruption, status will be set to Interrupted.
 */
- (void) didPauseListening;

/**
 *  Called whenever the LISNRService resumes from an Audio Session interruption
 */
- (void) didResumeListening;

/**
 *  Called when then SDK status changes, for example from Inactive to Listening. This method will not be called when the SDK changes from Unconfigured to inactive after configureWithJWT:completion: completes. Use the callback block of configureWithJWT:completion:
 *
 *  @param status  The current status of the SDK
 *  @param oldStatus  The prior status of the SDK
 */
- (void) lisnrStatusChanged:(LisnrStatus)status oldStatus:(LisnrStatus)oldStatus;

/**
 *  Called after broadcast of a tone begins and control of the audio session is interrupted by the system. SDK status will change to Inactive when broadcast is interrupted and broadcast will not resume after the interruption ends.
 *
 *  @param tone The broadcasting tone that was interrupted
 */
- (void) broadcastOfToneInterrupted:(LISNRTone * _Nonnull)tone;

/**
 *  Called when broadcast of the currently broadcasting tone finishes.
 *
 *  @param tone The tone that finished broadcasting.
 */
- (void) broadcastOfToneDidFinish:(LISNRTone * _Nonnull)tone;

/**
 * Called when a bluetooth speaker or headset connects to the device while listening. To avoid issues with audio configuration, audio playback over bluetooth and listening cannot happen simultaniously.
 */
- (void) listeningStoppedDueToBluetoothAudioPeriphralConnection;

@end

/**
 *  The object used to interact with LISNR Smart Tones
 *
 *  @warning You must use the sharedService object.
 *  @warning You must call configureWithJWT:completion: before any other methods.
 */
@interface LISNRService : NSObject

/**
 *  Returns the LISNRService singleton instance.
 *
 *  @return The LISNRService singleton
 */
+ (nonnull instancetype) sharedService;

/**
 *  Initializes the LISNRService with your JWT. This method must be called before startListening.
 *
 *  @param jwt Your LISNR JWT for your application
 *  @param completion A block that will be called after LISNRService finishes initializing and (on the first load on a user's device) receives or is denied audio permissions by the user. If there is an error with requesting audio permissions an error will be returned for the error argument, otherwise nil is returned.
 *
 *  @warning Do not call startListening on LISNRService or beginSmartListening on LISNRSmartListeningManager before the completion block argument of this method is called. The completion block will always be called on the main thread.
 */

- (void) configureWithJWT:(nonnull NSString *)jwt completion:(nullable LisnrServiceInitializedCompletionBlock)completion;

/**
 *  Starts the LISNRService. Will call completion block with an NSError parameter if unable to start listening, or nil if listening starts successfully. The completion block will always be called on the main thread. If you attempt to start listening while broadcasting a tone broadcasting will be stopped.
 *
 *  @param completion A completion block that takes an NSError parameters.
 *
 *  @warning You should only call startListeningWithCompletion: in the block passed as a paramter to configureWithJWT:completion: or after the completion block passed to configureWithJWT:completion: has been called. Calling startListeningWithCompletion: before configureWithJWT:completion: completes results in undefined behavior.
 */
- (void) startListeningWithCompletion:(nullable LisnrServiceAttemptToStartListeningCompletionBlock)completion;

/**
 *  Stops the LISNRService
 */
- (void) stopListening;

/**
 *  Begins broadcast of the tone passed as an argument. If LISNRService is currently listening, calling 'broadcastTone:' will automatically stop listening.
 *
 *  @param tone The LISNRTone object that represents the tone to be broadcast.
 *  @param fromDeviceSpeakersOnly If true, will broadcast tone only from device speakers. If false, tones will broadcast over connected headphones or bluetooth speakers.
 *  @param onBroadcastStart A block that will be called when the passed tone either starts broadcasting or fails to start broadcasting. On success, the error parameter will be nil and the duration property will be the broadcast time for the tone. On failure, the error property will be set with an NSError object and duration will be set with -1. Dispatched on the main thread.
 *
 *  @warning If tone broadcast fails (this method returns NO) and the SDK was listening before broadcastTone:fromDeviceSpeakersOnly: was called, listening will not be restarted.
 *  @warning If you attempt to start listening while broadcasting a tone broadcast will be stopped.
 *  @warning Tones are generated prior to broadcast. To avoid runtime memory issues, we recommend you use tones with a duration of two minutes or less. Each minute of play time corresponds to about 10mb of memory usage.
 *  @warning Upon broadcast completion LISNRService does not restart listening. If you need listening to restart upon completion of tone broadcast restart listening using the delegate method 'broadcastOfToneDidFinish:'
 */
- (void) broadcastTone:(LISNRTone * _Nonnull)tone fromDeviceSpeakersOnly:(BOOL)fromDeviceSpeakersOnly onBroadcastStart:(_Nullable LisnrServiceToneBroadcastStartedCallbackBlock)onBroadcastStart;

/**
 *  Stops tone broadcast. If the LISNRService singleton is not currently broadcasting a tone, this method does nothing.
 */
- (void) stopBroadcasting;

/**
 *  Adds an Observer conforming to the LISNRServiceDelegate Protocol. Any LISNRServiceDelegate implemented by an observer will be called by LISNRService. Observers are kept with an unsafe_unretained reference, so you must deregsiter any observers of LISNRService by calling removeObserver: before an observer deallocates or your application will crash.
 *
 *  @param observer An Observer conforming to the LISNRServiceDelegate Protocol
 *
 *  @warning Always call removeObserver: on LISNRService with any object you expect to deallocate or the next observer callback will result in a crash.
 *  @warning Don't start adding observers to LISNRService until after configureWithJWT:completion: has finished.
 */
- (void)addObserver:(nonnull id<LISNRServiceDelegate>)observer;

/**
 *  Removes a LISNRService Observer. Be sure to invoke this method before any observer of LISNRService is deallocated. Generally, you want to call this method to remove 'self' in the dealloc method of any object that observes LISNRService.
 *
 *  @param observer An Observer conforming to the LISNRServiceDelegate Protocol currently receiving callbacks from LISNRService. If the object passed is not currently an observer no action is taken.
 */
- (void)removeObserver:(nonnull id<LISNRServiceDelegate>)observer;

/**
 *  When set to YES, LISNRService is able to begin listening while the application is running in the background. Default value is NO. To learn more about starting listening in the background, please request our "Background Listening Guide".
 */
@property (nonatomic) BOOL shouldStartListeningInBackground;

/**
 *  This enableBackgroundListening boolean sets whether the SDK should attempt to continue listening while the app is sent to the background while listening. If set to YES, the UIBackgroundModes array must contain "audio".
 *
 *  The default is NO.
 */
@property (nonatomic) BOOL enableBackgroundListening;

/**
 *  Sets a custom identifier developer wants associated with this installation, such as as a uuid developer already associates with a user.
 *
 *  @param customIdentifier A custom identifier developer wants to associate with this install.
 */
- (void) setUserAnalyticsIdentifier:(nullable NSString *)customIdentifier;

/**
 *  The current Lisnr SDK status.
 */
@property (nonatomic, readonly) LisnrStatus status;

/**
 *  The JWT with which the LISNRService was initialized.
 */
@property (nonatomic, readonly, nullable) NSString *JWT;

/**
 *  The installed version of the LISNR-SDK-iOS.
 */
@property (nonatomic, readonly, nonnull) NSString *version;


/**
 *  Request when in use location permission.
 */
-(void)requestLocationPermission;

/**
 *  Allows setting of custom tone profiles. These profiles can only be generated 
 */
-(void)setCustomProfile:(NSString*)profile;

@end
