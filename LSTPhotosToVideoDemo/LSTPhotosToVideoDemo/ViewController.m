//
//  ViewController.m
//  LSTPhotosToVideoDemo
//
//  Created by 刘士天 on 2017/12/26.
//  Copyright © 2017年 刘士天. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>

@interface ViewController ()

@property (copy, nonatomic) NSMutableArray * imageArray;//处理后的图片数组
@property (strong, nonatomic) NSString * videoPath;//导出的视频路径

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageArray = [[NSMutableArray alloc] init]; //处理后的图片数组
    for (int i = 0; i<21; i++) {
        //统一图片尺寸
        [_imageArray addObject:[self originImage:[UIImage imageNamed:[NSString stringWithFormat:@"IMG_%d", i]] scaleToSize:CGSizeMake(320, 480)]];
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    //合成按钮
    [self.view addSubview:({
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, height-100, width/2.0, 100);
        button.backgroundColor = [UIColor orangeColor];
        button.titleLabel.font = [UIFont systemFontOfSize:25];
        [button setTitle:@"合成视频" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(testCompressionSession:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    })];
    
    //播放按钮
    [self.view addSubview:({
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(width/2.0, height-100, width/2.0, 100);
        button.backgroundColor = [UIColor greenColor];
        button.titleLabel.font = [UIFont systemFontOfSize:25];
        [button setTitle:@"视频播放" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(playVideoAction:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    })];
    
    //抽取视频音频按钮
    [self.view addSubview:({
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, height-200, width/2, 80);
        button.backgroundColor = [UIColor blueColor];
        button.titleLabel.font = [UIFont systemFontOfSize:25];
        [button setTitle:@"获取音频" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(videoToAudioButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    })];

}

#pragma mark - 改变图片大小
-(UIImage*) originImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}

#pragma mark - 按钮点击事件
- (void) testCompressionSession:(UIButton *) sender {
    //设置视频保存路径
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * moviePath = [paths.firstObject stringByAppendingPathComponent:@"photoVieo.mp4"];
    _videoPath = moviePath;
    
    //视频尺寸
    CGSize size = CGSizeMake(320, 480);
    NSError * error = nil;
    unlink([moviePath UTF8String]);
    AVAssetWriter * videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:moviePath] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    if (!error) {
        NSDictionary * videoSetting = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:size.width], AVVideoWidthKey, [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
        
        AVAssetWriterInput * writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSetting];
        
        NSDictionary * sourceDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        AVAssetWriterInputPixelBufferAdaptor * adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourceDic];
        
        NSParameterAssert(writerInput);
        NSParameterAssert([videoWriter canAddInput:writerInput]);
        
        if ([videoWriter canAddInput:writerInput]) {
            NSLog(@"1111111111");
        } else {
            NSLog(@"222222222");
        }
        
        [videoWriter addInput:writerInput];
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        
        //多张视频合成为一个视频
        dispatch_queue_t dispathQueue = dispatch_queue_create("mediaInputQueue", NULL);
        int __block frame = 0;
        [writerInput requestMediaDataWhenReadyOnQueue:dispathQueue usingBlock:^{
            while ([writerInput isReadyForMoreMediaData]) {
                if (++frame>=[_imageArray count]*10) {//每张图片x10
                    [writerInput markAsFinished];
                    [videoWriter finishWritingWithCompletionHandler:^{
                        
                    }];
                
                    break;
                }
                
                CVPixelBufferRef buffer = NULL;
                int idx = frame/10;
                buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[_imageArray objectAtIndex:idx] CGImage] size:size];
                if (buffer) {
                    if (![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 13)]) {//每秒钟播放图片个数
                        NSLog(@"Fail");
                    } else {
                        NSLog(@"OK");
                    }
                    
                    CFRelease(buffer);
                }
                
            }
        }];
        
    }
    
    
    
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    
    CVPixelBufferRef pxBuffer= NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxBuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxBuffer != NULL);
    CVPixelBufferLockBaseAddress(pxBuffer, 0);
    void * pxData = CVPixelBufferGetBaseAddress(pxBuffer);
    NSParameterAssert(pxData != NULL);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxData, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxBuffer, 0);
    
    return pxBuffer;
}

- (void) playVideoAction:(UIButton *) sender {
    NSLog(@"************%@",_videoPath);
    
    NSURL*sourceMovieURL = [NSURL fileURLWithPath:_videoPath];
    
    AVAsset*movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    
    AVPlayerItem*playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    
    AVPlayer*player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer*playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    
    playerLayer.frame=self.view.layer.bounds;
    
    playerLayer.videoGravity= AVLayerVideoGravityResizeAspect;
    
    [self.view.layer addSublayer:playerLayer];
    
    [player play];
    
}

- (void) videoToAudioButtonAction:(UIButton *) sender {
    
    //视频
    AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1" ofType:@".mp4"]]];
//
//    AVAsset * assetTwo = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"2" ofType:@".mp4"]]];
    
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* videoPath = [documentsDirectory stringByAppendingPathComponent:@"zxc.m4a"];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error;
    if ([manager fileExistsAtPath:videoPath]) {
        BOOL success = [manager removeItemAtPath:videoPath error:&error];
        if (success) {
            NSLog(@"Already exist. Removed!");
        }
    }
    
    NSURL *outputURL = [NSURL fileURLWithPath:videoPath];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if(exportSession.status == AVAssetExportSessionStatusCompleted){
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSLog(@">>>>>>>>>>>>>>>>%@", outputURL);
            });
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSLog(@".....failed....");
            });
        }
    }];
    
}

@end
