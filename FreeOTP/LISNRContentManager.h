//
//  LISNRContentManager.h
//  LISNR-SDK-iOS 6.0.0.1
//
//  Copyright (c) 2015 LISNR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LISNRService.h"
#import "LISNRContentProtocols.h"

@protocol LISNRContentManagerDelegate <NSObject>

/**
 *  Called after content is received for a detected tone. Called on a background thread.
 *
 *  Content will be fetched once per session and cached, it could be returned multiple times during a session.
 *  The content object returned will conform to one of the following protocols defined in LISNRContentProtocols.h:
 *
 *      - LISNRNotificationContentProtocol
 *      - LISNRVideoContentProtocol
 *      - LISNRImageContentProtocol
 *      - LISNRWebContentProtocol
 *
 *  @param content an object that conforms to one of the LISNRContentProtocols
 *  @param mediaId the unique ID of the tone
 */
- (void) didReceiveContent:(nonnull id<LISNRBaseContentProtocol>)content forIDToneWithId:(NSUInteger)toneId;

@end

@interface LISNRContentManager : NSObject

/**
 *  Returns the LISNRContentManager singleton object.
 *
 *  @return The LISNRContentManager singleton.
 */
+ (nonnull instancetype) sharedContentManager;

/**
 *  Configures LISNRContentManager. You must call this method on the LISNRContentManager singleton to use LISNRContentManager.
 *
 *  @param lisnrService This is always going to be '[LISNRService sharedService]'
 *
 *  @warning You must use this method to initialize an instance of LISNRContentManager.
 *  @warning You must call this method with the LISNRService sharedService object.
 *  @warning You must call this method on the LISNRContentManager singleton to use LISNRContentManager.
 */
- (void) configureWithLISNRService:(nonnull LISNRService *)lisnrService;

/**
 *  When NO, LISNRContentManager will not fetch content from the portal. Initialized with the value of YES during configureWithLISNRService:
 */
@property BOOL shouldFetchContent;

/**
 *  The LISNRContentManagerDelegate that will be called when content is received
 */
@property (weak, nonatomic, nullable) id<LISNRContentManagerDelegate> delegate;

/**
 *  Used to reload the preloaded content at a time of your choosing. By default preloaded content will automatically be refreshed when the user reopens an app after the refresh period (set on the portal) has passed, but you can use this method to trigger a reload at any time you choose.
 */
- (void) syncPreloadedContent;
               
@end
