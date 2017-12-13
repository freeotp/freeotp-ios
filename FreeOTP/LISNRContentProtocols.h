//
//  LISNRContent.h
//  LISNR-SDK-iOS 6.0.0.1
//
//  Copyright (c) 2015 LISNR. All rights reserved.
//

#import <Foundation/Foundation.h>

# pragma - mark Base Content

/**
 *  A base protocol that represents shared content properties
 *
 * @warning You should never directly conform to this protocol.
 */
@protocol LISNRBaseContentProtocol <NSObject>

/**
 *  The title of the piece of contet
 *
 *  @return the title
 */
- (nullable NSString *) contentTitle;

/**
 *  The alert body of the local notification that should be presented if the app is in the background
 *
 *  @return alert body
 */
- (nullable NSString *) contentNotificationText;

@end

# pragma - mark Notification Content

/**
 * A protocol that represents a local notification.
 * The body is empty because it completely conforms to the LISNRBaseContentProtocol
 * but was defined so the type could be explicitly checked with:
 *
 *      `[obj conformsToProtocol:@protocol(LISNRNotificationContentProtocol)]`
 *
 */
@protocol LISNRNotificationContentProtocol <LISNRBaseContentProtocol>
 // Left empty intentionally so you can be explicit about the type, but there are no additional methods
@end

# pragma - mark Image Content

/**
 * A protocol that represents a single image.
 */
@protocol LISNRImageContentProtocol <LISNRBaseContentProtocol>

/**
 *  The URL (remote or local) of the image resource
 *
 *  @return the image's URL
 */
- (nonnull NSURL *) contentImageUrl;

/**
 *  The URL (remote or local) of the image thumbnail
 *
 *  @return the image thumbnail URL
 */
- (nullable NSURL *) contentThumbnailUrl;

@end

# pragma - mark Video Content

/**
 * A protocol that represents an HLS encoded video.
 */
@protocol LISNRVideoContentProtocol <LISNRBaseContentProtocol>

/**
 *  The URL of the video resource, video resource should comform to HLS and be of type .m3u8
 *
 *  @return the video's URL
 */
- (nonnull NSURL *) contentVideoUrl;

@end

# pragma - mark Web Content

/**
 * A protocol that represents an external webpage
 */
@protocol LISNRWebContentProtocol <LISNRBaseContentProtocol>

/**
 *  The URL of the website to be shown
 *
 *  @return webpage's URL
 */
- (nonnull NSURL *) contentUrl;

@end
