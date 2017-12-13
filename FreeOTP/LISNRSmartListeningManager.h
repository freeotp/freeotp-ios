//
//  LISNRSmartListeningManager.h
//  LISNR-SDK-iOS 6.0.0.1 
//
//  Copyright (c) 2015 LISNR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LISNRService.h"

typedef NS_ENUM(NSInteger, SmartListeningServerStatus) {
    SmartListeningServerStatusUnavailable,
    SmartListeningServerStatusEnabled,
    SmartListeningServerStatusDisabled
};

@protocol LISNRSmartListeningDelegate <NSObject>

@optional
/**
 *  Asks the delegate if listening can be started by Smart Listening Manager when a smart listening rule period is entered. The answer to this is almost always YES, unless your application is currently playing media. You can also use this method to make changes that must be made BEFORE listening is started by LISNRSmartListeningManager, like changes to your application's audio configuration, before returning YES.
 *
 *  If unimplemented LISNRSmartListeningManager will start listening by default.
 *
 *  @return Whether LISNRSmartListeningManager should begin Smart Listening. If YES LISNRSmartListeningManager will attempt to start listening immediately. If NO LISNRSmartListeningManager will try again in approximately ten minutes if a smart listening rule is still active.
 */
- (BOOL) shouldStartListening;

/**
 *  Called when LISNRSmartListeningManger is unable to initially make contact with the server to get the smart listening server status and rules ("Configuration"). If unable to reach the server, the SDK will default to not listening and attempt to update it's configuration every 30 minutes. The SDK will not start listening until it successfully updates the smart listening configuration and is within a listening rule.
 *
 *  If LISNRSmartListeningManager has already successfully reached the Portal to configure itself but later becomes unable to reach the Portal while refreshing the configuration, it will continue to follow the initial configuration until it can update via the Portal.
 *
 *  This method is offered so that in the event of a user not having network connectivity you can opt for a default behavior e.g. to end Smart Listening and just start listening on LISNRService.
 */
- (void) unableToUpdateSmartListeningConfiguration;

@end

@interface LISNRSmartListeningManager : NSObject

/**
 *  Returns the LISNRSmartListeningManager singleton object.
 *
 *  @return The LISNRSmartListeningManager singleton.
 */
+ (nonnull instancetype) sharedSmartListeningManager;

/**
 *  Configures LISNRSmartListeningManager. You must call this method on the LISNRSmartListeningManager singleton to use LISNRSmartListeningManager.
 *
 *  @param lisnrService This is always going to be '[LISNRService sharedService]'
 *
 *  @warning You must use this method to initialize an instance of LISNRSmartListeningManager.
 *  @warning You must call this method with the LISNRService sharedService object.
 *  @warning You must call this method on the LISNRSmartListeningManager singleton to use LISNRSmartListeningManager.
 */
- (void) configureWithLISNRService:(nonnull LISNRService *)lisnrService;

/**
 *  When called LISNRSmartListeningManager will check for listening rules and then call 'startListening' on LISNRService if smart listening is enabled and the user is currently within a smart listening period or if smart listening is currently disabled. 'didFailToStartListeningWithError:' will be called on the delegate if unable to start listening. 
 *
 *   Smart Listening Rules are currently updated from the portal every 60 minutes or when the next currently known smart listening rule starts or ends, whichever is shorter.
 *
 *  @warning You should only call beginSmartListening on SmartListeningManager in the block passed as a paramter in the LISNRService instance method configureWithApiKey:completion or after it has been called. Calling beginSmartListening before configureWithApiKey:completion: completes results in undefined behavior.
 *  @warning While smart listening is active do not directly call startListening or stopListening on LISNRService
 *  @warning You must set the LISNRSmartListeningManager delegate before calling this method if you want to receive the didStartListening and didFailToStartListeningWithError: delegate callbacks
 */
- (void) beginSmartListening;

/**
 *  Ends LISNRSmartListeningManager smart listening. If LISNRService is currently listening stopListening will not be called on LISNRService.
 *
 *  @warning You must set the LISNRSmartListeningManager delegate before calling this method if you want to receive the didStopListening callback
 */
- (void) endSmartListening;

/**
 *  Returns whether Smart Listening is currently active on the client. This will be true if you have called 'beginSmartListening' and have not yet ended smart listening.
 */
@property (readonly) BOOL smartListeningActive;

/**
 *  Returns whether smart listening is enabled on the portal. If the portal cannot be reached, returns the status 'SmartListeningServerStatusUnavailable'.
 */
@property (readonly) SmartListeningServerStatus smartListeningServerStatus;

/**
 *  The LISNRSmartListeningDelegate that will be called when listening starts, fails to start, or stops
 */
@property (weak, nonatomic, nullable) id<LISNRSmartListeningDelegate> delegate;

/**
 *  Returns the time period before the chronologically next smart listening rule will be in effect. Returns -1.0 if smart listening is disabled or smart listening is enabled but no current or future smart listening rules are available. Returns 0.0 if you are currently within a Smart Listening rule's time range.
 *
 *  @return An NSTimeInterval that gives the time until the next smart listening rule will be in effect
 */
- (NSTimeInterval) timeIntervalUntilNextSmartListeningSession;

/**
 *  Set timeout time for smart listening in seconds. If a tone is not heard for the length of the timeout period LISNRSmartListeningManager will stop listening and call endSmartListening on itself. Set to 0 or a negative value to disable timeout. Initialized with a value of -1 by configureWithLISNRService:. If you update this value the current reset time count is reset to 0.
 */
@property (nonatomic) NSTimeInterval listeningTimeoutTime;

/**
 * Controls how rules are downloaded if your app begins smart listening while in the background.
 *
 * Due to OS threading configuration, when launching in the the LISNR SDK can only start listening from the main thread from applicationDidFinishLaunchingWithOptions:. Therefore when launching in the background the Smart Listening configuration can only be updated and still start listening via a synchronous network request on the main thread. While this tkaes place the main thread is blocked and could cause a delay opening your application (where the user will just see the splashscreen) if your user happens to open your application while the synchronous rule request takes place. This property gives you the ability to turn off the synchronous Smart Listening configuration update.
 *
 * Smart Listening Rules will only be synchronously downloaded if your application launches in the background, this property is set to true, and the LISNRService singleton properties 'shouldStartListeningInBackground' and 'enableBackgroundListening' are both set to true.
 *
 * Refer to our Background Listening Guide for more information about starting listening while your application isn't in the foreground, and the threading issues the LISNR SDK faces.
 * 
 * This property defaults to true
 */
@property BOOL synchronouslyDownloadRulesWhenAppLaunchesInBackground;

/**
 * Controls the request timeout time used when rules are permitted to be synchronously downloaded.
 * 
 * This timeout time apples to two requests - the first to find out if Smart Listening is enabled, and the second to actually download the Smart Listening Rules. If either request times out (or fails for any other reason) cached preferences from the last time Smart Listening configuration data was downloaded will be used to determine if listening should be started in the background. 
 *
 * The default value of this property is 2 seconds.
 */
@property NSTimeInterval synchronousRuleDownloadTimeoutTime;

@end
