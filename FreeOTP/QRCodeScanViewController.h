//
//  QRCodeScanViewController.h
//  FreeOTP
//
//  Created by Nathaniel McCallum on 11/23/13.
//  Copyright (c) 2013 Nathaniel McCallum. All rights reserved.
//

@import AVFoundation;
#import <UIKit/UIKit.h>

@interface QRCodeScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>
@property (strong) AVCaptureSession *session;
@end
