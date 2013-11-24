//
//  QRCodeScanViewController.m
//  FreeOTP
//
//  Created by Nathaniel McCallum on 11/23/13.
//  Copyright (c) 2013 Nathaniel McCallum. All rights reserved.
//

#import "QRCodeScanViewController.h"
#include "TokenStore.h"

@interface QRCodeScanViewController ()
@end

@implementation QRCodeScanViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.session = [[AVCaptureSession alloc] init];
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    NSError* error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (input == nil) {
        NSLog(@"Input error: %@", error);
        [self.navigationController popViewControllerAnimated:TRUE];
        return;
    }
    [self.session addInput:input];

    AVCaptureVideoPreviewLayer* preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    preview.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:preview];

    [self.session startRunning];
}

- (void)viewDidAppear:(BOOL)animated
{
    /* NOTE: We start output processing in viewDidAppear() to avoid a
     * race condition when the QR code is scanned before the view appears. */
    AVCaptureMetadataOutput* output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:output];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*) connection
{
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString* qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            if (qrcode == nil)
                continue;
            NSLog(@"QR Code: %@", qrcode);

            Token* token = [[Token alloc] initWithString:qrcode];
            if (token != nil)
                [[[TokenStore alloc] init] add:token];

            [self.session stopRunning];
            [self.navigationController popViewControllerAnimated:TRUE];
            return;
        }
    }
}

@end
