//
//  EUExImage.m
//  EUExImage
//
//  Created by Cerino on 15/9/23.
//  Copyright © 2015年 AppCan. All rights reserved.
//

#import "EUExImage.h"

#import "uexImageWidgets.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AppCanKit/AppCanKit.h>



#import <Photos/Photos.h>
//#import "EUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>


#import <Photos/PhotosTypes.h>


NSString * const cUexImageCallbackIsCancelledKey    = @"isCancelled";
NSString * const cUexImageCallbackDataKey           = @"data";
NSString * const cUexImageCallbackIsSuccessKey      = @"isSuccess";
@interface EUExImage()
@property (nonatomic,assign)UIStatusBarStyle initialStatusBarStyle;
@property (nonatomic,strong)UIPopoverController *iPadPop;
@property (nonatomic,assign)BOOL usingPop;

@property (nonatomic,strong)uexImageCropper *cropper;
@property (nonatomic,strong)uexImagePicker *picker;
@property (nonatomic,strong)uexImageBrowser *browser;

@property (nonatomic,assign)BOOL enableIpadPop;





@end
@implementation EUExImage


#pragma mark - EUExBase Method



- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine
{
    self = [super initWithWebViewEngine:engine];
    if (self) {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
            _usingPop = YES;
        }else{
            _usingPop = NO;
        }
        _initialStatusBarStyle=[UIApplication sharedApplication].statusBarStyle;
        _enableIpadPop = YES;
    }
    return self;
}


#pragma mark - APIs


- (void)openPicker:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    if(!info){
        return;
    }
    
    if(!self.picker){
        self.picker = [[uexImagePicker alloc]initWithEUExImage:self];
    }
    [self.picker clean];
    self.picker.cb = cb;
    if([info objectForKey:@"min"]){
        self.picker.min = [[info objectForKey:@"min"] integerValue];
    }
    if([info objectForKey:@"max"]){
        self.picker.max = [[info objectForKey:@"max"] integerValue];
    }
    if([info objectForKey:@"quality"]){
        self.picker.quality = [[info objectForKey:@"quality"] floatValue];
    }
    if([info objectForKey:@"usePng"]){
        self.picker.usePng = [[info objectForKey:@"usePng"] boolValue];
    }
    if([info objectForKey:@"title"]){
        self.picker.title = [info objectForKey:@"title"];
    }
    if([info objectForKey:@"detailedInfo"]){
        self.picker.detailedInfo = [[info objectForKey:@"detailedInfo"] boolValue];
    }
    [self.picker open];
}

#pragma mark -compressImage(图片压缩)；

- (void)compressImage:(NSMutableArray*)inArguments{
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    NSString * imagePath = [self absPath:[info objectForKey:@"srcPath"]];
    UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
    
    //图像压缩
    UIImage *images = [self scaleFromImage:image];
    NSInteger imageLength = [[info objectForKey:@"desLength"] intValue];
    // 原始数据
    NSData *imgData = UIImageJPEGRepresentation(images, 1.0);
    // 原始图片
    UIImage *result = [UIImage imageWithData:imgData];
    
    if  (imgData.length > imageLength) {
        imgData = UIImageJPEGRepresentation(result,0.5);
    }
    
    UEX_ERROR errs ;
    if(imgData){
        NSFileManager *fmanager = [NSFileManager defaultManager];
        NSString *uexImageSaveDir=[self getSaveDirPath];
        if (![fmanager fileExistsAtPath:uexImageSaveDir]) {
            [fmanager createDirectoryAtPath:uexImageSaveDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *timeStr = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSinceReferenceDate]];
        NSString *imgName = [NSString stringWithFormat:@"%@.jpg",[timeStr substringFromIndex:([timeStr length]-6)]];
        NSString *imgTmpPath = [uexImageSaveDir stringByAppendingPathComponent:imgName];
        if ([fmanager fileExistsAtPath:imgTmpPath]) {
            [fmanager removeItemAtPath:imgTmpPath error:nil];
        }
        [imgData writeToFile:imgTmpPath atomically:YES];
        NSMutableDictionary * dicct = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"ok",@"status",imgTmpPath,@"filePath", nil];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexImage.cbCompressImage" arguments:ACArgsPack(dicct.ac_JSONFragment)];
        errs = kUexNoError;
        
        [cb executeWithArguments:ACArgsPack(errs,dicct.ac_JSONFragment)];
        
    } else {
        NSMutableDictionary * dicct = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"fail",@"status",@"",@"filePath", nil];
        errs = @([@"1" integerValue]);
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexImage.cbCompressImage" arguments:ACArgsPack(dicct.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(errs,dicct.ac_JSONFragment)];
        
    }
    
}

// 图像压缩
//==========================
- (UIImage *)scaleFromImage:(UIImage *)image
{
    if (!image){
        return nil;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    CGFloat dataSize = data.length/1024;
    CGFloat width  = image.size.width;
    CGFloat height = image.size.height;
    CGSize size;
    
    if (dataSize<=30)//小于50k
    {
        return image;
    }
    else if (dataSize<=100)//小于100k
    {
        size = CGSizeMake(width/2.f, height/2.f);
    }
    else if (dataSize<=200)//小于200k
    {
        size = CGSizeMake(width/3.f, height/3.f);
    }
    else if (dataSize<=500)//小于500k
    {
        size = CGSizeMake(width/3.f, height/3.f);
    }
    else if (dataSize<=1000)//小于1M
    {
        size = CGSizeMake(width/3.f, height/3.f);
    }
    else if (dataSize<=2000)//小于2M
    {
        size = CGSizeMake(width/3.f, height/3.f);
    }
    else//大于2M
    {
        size = CGSizeMake(width/20.f, height/20.f);
    }
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *newImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (!newImage)
    {
        return image;
    }
    return newImage;
}


- (NSString *)getSaveDirPath{
    NSString *tempPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/apps"];
    NSString *wgtTempPath=[tempPath stringByAppendingPathComponent:self.webViewEngine.widget.widgetId];
    return [wgtTempPath stringByAppendingPathComponent:@"uexImage"];
}



- (void)openCropper:(NSMutableArray *)inArguments{
    if(!self.cropper){
        self.cropper = [[uexImageCropper alloc]initWithEUExImage:self];
    }
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    [self.cropper clean];
    if(info){
        if([info objectForKey:@"quality"]){
            self.cropper.quality = [[info objectForKey:@"quality"] floatValue];
        }
        if([info objectForKey:@"uesPng"]){
            self.cropper.usePng = [[info objectForKey:@"usePng"] floatValue];
        }
        if([info objectForKey:@"mode"]){
            self.cropper.shape = [[info objectForKey:@"mode"] integerValue];
        }
        if([info objectForKey:@"src"]){
            UIImage *imageToBeCropped = [UIImage imageWithContentsOfFile:[self absPath:[info objectForKey:@"src"]]];
            self.cropper.imageToBeCropped = imageToBeCropped;
        }
    }
    self.cropper.cb = cb;
    [self.cropper open];
}



- (void)openBrowser:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    if(!self.browser){
        self.browser=[[uexImageBrowser alloc]initWithEUExImage:self];
    }
    
    [self.browser clean];
    self.browser.cb = cb;
    [self.browser setDataDict:info];
    [self.browser open];
    
}



- (void)saveToPhotoAlbum:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    NSString *path = stringArg(info[@"localPath"]);
    NSString *extra = stringArg(info[@"extraInfo"]);
    UIImage *image = [UIImage imageWithContentsOfFile:[self absPath:path]];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:extra forKey:@"extraInfo"];
        UEX_ERROR err = kUexNoError;
        if(error){
            err = uexErrorMake(1,[error localizedDescription]);
            [dict setValue:@(NO) forKey:cUexImageCallbackIsSuccessKey];
            [dict setValue:[error localizedDescription] forKey:@"errorStr"];
        }else{
            [dict setValue:@(YES) forKey:cUexImageCallbackIsSuccessKey];
        }
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexImage.cbSaveToPhotoAlbum" arguments:ACArgsPack(dict.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(err,error.localizedDescription)];
    }];
    
}



- (UEX_BOOL)clearOutputImages:(NSMutableArray *)inArguments{
    BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:[self saveDirPath] error:NULL];
    return ret ? UEX_TRUE : UEX_FALSE;
}

- (void)setIpadPopEnable:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    self.enableIpadPop=[inArguments[0] boolValue];
}



#pragma mark - Tools
//restore initial StatusBar
- (void)restoreStatusBar{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setStatusBarStyle:self.initialStatusBarStyle];
        NSNumber *statusBarHidden = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIStatusBarHidden"];
        if ([statusBarHidden boolValue] == YES) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        }
        
    });
    
}

- (void)presentViewController:(UIViewController *)vc animated:(BOOL)flag{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.usingPop && self.enableIpadPop){
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:vc];
            self.iPadPop = popover;
            [popover presentPopoverFromRect:CGRectMake(0, 0, 300, 300) inView:self.webViewEngine.webView permittedArrowDirections:UIPopoverArrowDirectionAny animated:flag];
        }else{
            [[self.webViewEngine viewController]presentViewController:vc animated:flag completion:nil];
            
        }
    });
    
}

- (void)dismissViewController:(UIViewController *)vc
                     animated:(BOOL)flag
                   completion:(void (^)(void))completion{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.usingPop && self.enableIpadPop){
            [self.iPadPop dismissPopoverAnimated:flag];
            if(completion){
                completion();
            }
            self.iPadPop=nil;
        }else{
            [vc dismissViewControllerAnimated:flag completion:completion];
        }
        [self restoreStatusBar];
    });
}




- (NSString *)saveDirPath{
    NSString *tempPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/apps"];
    NSString *wgtTempPath=[tempPath stringByAppendingPathComponent:[[self.webViewEngine widget] widgetId]];
    return [wgtTempPath stringByAppendingPathComponent:@"uexImage"];
}

- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

// save to Disk
- (NSString *)saveImage:(UIImage *)image quality:(CGFloat)quality usePng:(BOOL)usePng{
    NSData *imageData;
    NSString *imageSuffix;
    
    image = [self normalizedImage:image];

    if(usePng){
        imageData = UIImagePNGRepresentation(image);
        imageSuffix = @"png";
    }else{
        imageData = UIImageJPEGRepresentation(image, quality);
        imageSuffix = @"jpg";
    }
    
    if(!imageData){
        return nil;
    }
    
    NSFileManager *fmanager = [NSFileManager defaultManager];
    
    NSString *uexImageSaveDir = [self saveDirPath];
    if (![fmanager fileExistsAtPath:uexImageSaveDir]) {
        [fmanager createDirectoryAtPath:uexImageSaveDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *timeStr = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSinceReferenceDate]];
    
    NSString *imgName = [NSString stringWithFormat:@"%@.%@",[timeStr substringFromIndex:([timeStr length]-6)],imageSuffix];
    NSString *imgTmpPath = [uexImageSaveDir stringByAppendingPathComponent:imgName];
    if ([fmanager fileExistsAtPath:imgTmpPath]) {
        [fmanager removeItemAtPath:imgTmpPath error:nil];
    }
    if([imageData writeToFile:imgTmpPath atomically:YES]){
        return imgTmpPath;
    }else{
        return nil;
    }
    
}



@end
