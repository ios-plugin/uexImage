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


#import "UexImageMySingleton.h"
#import "PhotoBrowerList.h"

#import "HUPhotoBrowser.h"
#import "PhotoCell.h"
#import "UIImageView+HUWebImage.h"


//style 为1 类型；

#import "TZImagePickerController.h"
#import <Photos/Photos.h>
//#import "EUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TZImageManager.h"

#import <Photos/PhotosTypes.h>


NSString * const cUexImageCallbackIsCancelledKey    = @"isCancelled";
NSString * const cUexImageCallbackDataKey           = @"data";
NSString * const cUexImageCallbackIsSuccessKey      = @"isSuccess";
@interface EUExImage()<TZImagePickerControllerDelegate>

{
    NSMutableArray *_selectedAssets;
    BOOL _isSelectOriginalPhoto;
}

@property (nonatomic,assign)UIStatusBarStyle initialStatusBarStyle;
@property (nonatomic,strong)UIPopoverController *iPadPop;
@property (nonatomic,assign)BOOL usingPop;

@property (nonatomic,strong)uexImageCropper *cropper;
@property (nonatomic,strong)uexImagePicker *picker;
@property (nonatomic,strong)uexImageBrowser *browser;
@property(nonatomic,strong)HUPhotoBrowser *HUPhotoB;
@property (nonatomic,assign)BOOL enableIpadPop;

@property(nonatomic,strong)NSMutableArray* selectedPhotos;
@property(nonatomic,strong)NSMutableArray * videoArray;

@property(nonatomic,strong)NSMutableArray* dataArray;
@property(nonatomic,strong)NSMutableArray* detailedInfoArray;

@property(nonatomic,strong)UIImage * imageddddd;

@property(nonatomic,strong)NSString * qualityStr;

@property (nonatomic,strong)ACJSFunctionRef *cb;

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
    
    
    if(!self.picker){
        self.picker = [[uexImagePicker alloc]initWithEUExImage:self];
    }
    [self.picker clean];
    self.picker.cb = cb;
    self.cb = cb;
    
    if([inArguments count] >0){
        
        
       // id info = [inArguments[0] ac_JSONValue];
        
        if([info isKindOfClass:[NSDictionary class]]){
            
            if ([[NSString stringWithFormat:@"%@",[info objectForKey:@"style"]]isEqualToString:@"1"]&& [[info allKeys]containsObject:@"style"]) {
                
                UexImageMySingleton * ImageLeton = [UexImageMySingleton shareMySingLeton];
                
                //NSString *  jsonStr = [inArguments objectAtIndex:0];
                
               // NSDictionary * pickerDcit = [jsonStr ac_JSONValue];
                
                NSString * mincountStr= [NSString stringWithFormat:@"%@",[info objectForKey:@"min"]];
                
                _qualityStr = [NSString stringWithFormat:@"%@",[info objectForKey:@"quality"]];
                
                ImageLeton.minCount = mincountStr.integerValue;
                
                [self pushImagePickerController:info];
                
                
            } else {
                
                if(info){
                    
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
                }
                
                [self.picker open];
            }
            
        }
    }
    
    
}

#pragma mark-----type 为 1 的 delegate方法；

- (void)pushImagePickerController: (NSDictionary*)dict {
    
    _selectedAssets = [NSMutableArray arrayWithCapacity:3];
    
    if ([NSString stringWithFormat:@"%@",[dict objectForKey:@"min"]].integerValue <= 0) {
        return;
    }
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:[NSString stringWithFormat:@"%@",[dict objectForKey:@"max"]].integerValue columnNumber:4 delegate:self pushPhotoPickerVc:YES];
    
    
#pragma mark - 四类个性化设置，这些参数都可以不传，此时会走默认设置
    imagePickerVc.isSelectOriginalPhoto = YES;
    
    if ([NSString stringWithFormat:@"%@",[dict objectForKey:@"max"]].integerValue > 1) {
        // 1.设置目前已经选中的图片数组
        imagePickerVc.selectedAssets = _selectedAssets; // 目前已经选中的图片数组
    }
    
    
    // 2. Set the appearance
    // 2. 在这里设置imagePickerVc的外观
    // imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    
    // 3. Set allow picking video & photo & originalPhoto or not
    // 3. 设置是否可以选择视频/图片/原图
    
    if ([[dict allKeys]containsObject:@"allowPickingVideo"]&&[[dict allKeys]containsObject:@"allowPickingVideo"]) {
        
        if ([[dict objectForKey:@"allowPickingVideo"] integerValue]==0)
        {
            imagePickerVc.allowPickingVideo = NO;
        } else {
            
            imagePickerVc.allowPickingVideo = YES;
            
        }
        if ([[dict objectForKey:@"allowTakePicture"] integerValue]==0)
        {
            imagePickerVc.allowTakePicture = NO; // 在内部显示拍照按钮
            
        } else {
            
            imagePickerVc.allowTakePicture = YES; // 在内部显示拍照按钮
        }
        
    } else {
        
        imagePickerVc.allowPickingVideo = NO;
        imagePickerVc.allowTakePicture = NO; // 在内部显示拍照按钮
        
    }
    
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = YES;
    
    // 4. 照片排列按修改时间升序
    imagePickerVc.sortAscendingByModificationDate = YES;
    
    // imagePickerVc.minImagesCount = 3;
    // imagePickerVc.alwaysEnableDoneBtn = YES;
#pragma mark - 到这里为止
    
    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        
    }];
    
   // [self.webViewEngine.viewController presentModalViewController:imagePickerVc animated:YES];
    
    [self.webViewEngine.viewController presentViewController:imagePickerVc animated:YES completion:^{
        NSLog(@"appcan4.0-uexImage已经跳转");
    }];
    //    [self presentViewController:imagePickerVc animated:YES completion:nil];
}


#pragma mark - TZImagePickerControllerDelegate

/// User click cancel button
/// 用户点击了取消
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    NSLog(@"cancel");
}

// The picker should dismiss itself; when it dismissed these handle will be called.
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[TZImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的代理方法
// 如果isSelectOriginalPhoto为YES，表明用户选择了原图
// 你可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _selectedPhotos = [NSMutableArray arrayWithArray:photos];
    _selectedAssets = [NSMutableArray arrayWithArray:assets];
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    //[_collectionView reloadData];
    // _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
    
    // 1.打印图片名字
    [self printAssetsName:assets];
}

// If user picking a video, this callback will be called.
// If system version > iOS8,asset is kind of PHAsset class, else is ALAsset class.
// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    
    //选择Video；
    
}

#pragma mark - Private

/// 打印图片名字
- (void)printAssetsName:(NSArray *)assets {
    
    //    for(ALAsset * asset in assets){
    //
    //        ALAssetRepresentation *representation = [asset defaultRepresentation];
    //
    //
    //    }
    
    BOOL original = YES;
    
    self.dataArray = [NSMutableArray arrayWithCapacity:10];
    self.detailedInfoArray = [NSMutableArray arrayWithCapacity:10];
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    NSString *fileName;
    for (id asset in assets) {
        
        if ([asset isKindOfClass:[PHAsset class]]) {
            
            PHAsset *phAsset = (PHAsset *)asset;
            
            fileName = [phAsset valueForKey:@"filename"];
            
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            // 同步获得图片, 只会返回1张图片
            options.synchronous = YES;
            
            CGSize size = original ? CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight) : CGSizeZero;
            
            [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                
                _imageddddd = result;
                
            }];
            
            NSString * imagePath =[self saveImage:_imageddddd quality:[_qualityStr floatValue] usePng:NO];
            
            if(imagePath){
                
                [self.dataArray addObject:imagePath];
                
                if(self.detailedInfoArray){
                    
                    NSMutableDictionary *info=[NSMutableDictionary dictionary];
                    
                    [info setValue:imagePath forKey:@"localPath"];
                    
                    [info setValue:[NSString stringWithFormat:@"%@",phAsset.creationDate] forKey:@"timestamp"];
                    
                    CLLocation *location= phAsset.location;
                    
                    if(location){
                        
                        NSLog(@"%f",location.coordinate.latitude);
                        NSLog(@"%f",location.coordinate.longitude);
                        
                        [info setValue:@(location.coordinate.latitude) forKey:@"latitude"];
                        [info setValue:@(location.coordinate.longitude) forKey:@"longitude"];
                        [info setValue:@(location.altitude) forKey:@"altitude"];
                    }
                    
                    [self.detailedInfoArray addObject:info];
                    
                    
                }
                
                
            }
            
            
            
        } else if ([asset isKindOfClass:[ALAsset class]]) {
            
            ALAsset *alAsset = (ALAsset *)asset;
            
            fileName = alAsset.defaultRepresentation.filename;
            
            ALAssetRepresentation *representation = [asset defaultRepresentation];
            
            UIImage * assetImage =[UIImage imageWithCGImage:[representation fullResolutionImage] scale:representation.scale orientation:(UIImageOrientation)representation.orientation];
            
            NSString * imagePath =[self saveImage:assetImage quality:[_qualityStr floatValue] usePng:NO];
            
            
            if(imagePath){
                
                [self.dataArray addObject:imagePath];
                
                if(self.detailedInfoArray){
                    
                    NSMutableDictionary *info=[NSMutableDictionary dictionary];
                    [info setValue:imagePath forKey:@"localPath"];
                    [info setValue:@((int)[[asset valueForProperty:ALAssetPropertyDate] timeIntervalSince1970]) forKey:@"timestamp"];
                    CLLocation *location=[asset valueForProperty:ALAssetPropertyLocation];
                    
                    
                    if(location){
                        
                        [info setValue:@(location.coordinate.latitude) forKey:@"latitude"];
                        [info setValue:@(location.coordinate.longitude) forKey:@"longitude"];
                        [info setValue:@(location.altitude) forKey:@"altitude"];
                    }
                    
                    [self.detailedInfoArray addObject:info];
                }
                
            }
            
            
        }
        
    }
    
    [dict setValue:self.dataArray forKey:cUexImageCallbackDataKey];
    [dict setObject:@(NO) forKey:cUexImageCallbackIsCancelledKey];
    
    if(self.detailedInfoArray){
        
        [dict setValue:self.detailedInfoArray forKey:@"detailedImageInfo"];
        
    }
    
    UEX_ERROR error;
    
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexImage.onPickerClosed" arguments:ACArgsPack(dict)];
    
    error = kUexNoError;
    
    [self.cb executeWithArguments:ACArgsPack(error,dict.ac_JSONFragment)];
    
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
        
    }else {
        
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
    if (!image)
    {
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

-(void)onLongClick:(NSMutableDictionary *)dict{
    
     UEX_ERROR errs ;

    [self.webViewEngine callbackWithFunctionKeyPath:@"uexImage.onImageLongClicked" arguments:ACArgsPack(dict.ac_JSONFragment)];
    
    errs = kUexNoError;
    
    [self.cb executeWithArguments:ACArgsPack(errs,dict.ac_JSONFragment)];

}


- (void)openBrowser:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    if(!self.browser){
        self.browser=[[uexImageBrowser alloc]initWithEUExImage:self];
    }
    
   // id infos = [inArguments[0] ac_JSONValue];
    
    if ([[NSString stringWithFormat:@"%@",[info objectForKey:@"style"]]isEqualToString:@"0"])
    {
        [self.browser clean];
        self.browser.cb = cb;
        [self.browser setDataDict:info];
        [self.browser open];
        
    }else{
        self.cb = cb;
        [self imageBrowser:inArguments];
        
    }
}


//openbrower

- (void)imageBrowser:(NSMutableArray *)inArguments
{
    if (inArguments.count < 1) {
        
        return;
        
    }
    
    id info = [inArguments[0] ac_JSONValue];
    
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        
        return;
    }
    
    int index = [[info objectForKey:@"startIndex"] intValue];
    
    UexImageMySingleton * uexImageshare = [UexImageMySingleton shareMySingLeton];
    
    if ([[info allKeys] containsObject:@"gridBackgroundColor"])
    {
        NSString * gridBackGroundColorStr = [info objectForKey:@"gridBackgroundColor"];
        
        uexImageshare.gridBackgroundColorStr = gridBackGroundColorStr;
        
    } else {
        
        uexImageshare.gridBackgroundColorStr = @"#000000";
        
    }
    
    if ([[info allKeys] containsObject:@"gridTitle"])
    {
        NSString * gridTitleStr = [info objectForKey:@"gridTitle"];
        
        uexImageshare.gridBrowserTitleStr = gridTitleStr;
        
    } else {
        
        uexImageshare.gridBrowserTitleStr = UEXIMAGE_LOCALIZEDSTRING(@"ImageBrowse");
        
    }
    
    NSMutableArray * dataArray = [info objectForKey:@"data"];
    
    NSMutableArray * smallImagePathArray = [NSMutableArray arrayWithCapacity:3];
    
    NSMutableArray * bigImageURLArray    = [NSMutableArray arrayWithCapacity:3];
    
    NSMutableArray * imagePathArray = [NSMutableArray arrayWithCapacity:3];
    
    for (int i = 0; i < dataArray.count; i ++) {
        
        id  dic = dataArray[i];
        
        if([dic isKindOfClass:[NSString class]]){
            
            if ([dic hasPrefix:@"http"])
            {
                //长按回调使用数组；
                [bigImageURLArray addObject:dic];
                
                [imagePathArray addObject:dic];
                
            } else {
                
                //长按回调使用数组；
                [imagePathArray addObject:dic];
                
                NSString * bigImagepath = [self absPath:dic];
                
                [bigImageURLArray addObject:bigImagepath];
                
            }
            
            
        }else if ([dic isKindOfClass:[NSDictionary class]])
        {
            
            if([[dic allKeys] containsObject:@"thumb"])
            {
                if ([dic objectForKey:@"thumb"]) {
                    
                    NSString *smallImage = [NSString stringWithFormat:@"%@",[dic objectForKey:@"thumb"]];
                    
                    NSString * smallImagePath = [self absPath:smallImage];
                    
                    [smallImagePathArray addObject:smallImagePath];
                    
                } else {
                    
                    [smallImagePathArray addObject:@"123"];
                }
                
            }
            
            if ([dic objectForKey:@"src"]) {
                
                NSString *bigImage = [NSString stringWithFormat:@"%@",[dic objectForKey:@"src"]];
                
                if ([bigImage hasPrefix:@"http"])
                {
                    //长按回调使用数组；
                    [imagePathArray addObject:bigImage];
                    
                    [bigImageURLArray addObject:bigImage];
                    
                } else {
                    
                    //长按回调使用数组；
                    [imagePathArray addObject:bigImage];
                    
                    NSString * bigImagepath = [self absPath:bigImage];
                    
                    [bigImageURLArray addObject:bigImagepath];
                    
                }
                
            }
            
            
        }
        
        
    }
    
    UexImageMySingleton * EUExsingleton = [UexImageMySingleton shareMySingLeton];
    EUExsingleton.slectImage = self;
    EUExsingleton.longImagePath = imagePathArray;
    
    EUExsingleton.placeholderArray = smallImagePathArray;

    
    if ([[info allKeys] containsObject:@"viewFramePicPreview"])
    {
        NSDictionary * PreviewDict = [info objectForKey:@"viewFramePicPreview"];
        
        CGRect frame = CGRectMake([[PreviewDict objectForKey:@"x"] intValue], [[PreviewDict objectForKey:@"y"] intValue], [[PreviewDict objectForKey:@"w"] intValue], [[PreviewDict objectForKey:@"h"] intValue]);
        UexImageMySingleton * preImagesLeton = [UexImageMySingleton shareMySingLeton];
        preImagesLeton.preframe = frame;
        
        
    } else {
        
        CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,  [UIScreen mainScreen].bounds.size.height);
        UexImageMySingleton * preImagesLeton = [UexImageMySingleton shareMySingLeton];
        preImagesLeton.preframe = frame;
        
    }
    
    
    if ([[info allKeys]containsObject:@"viewFramePicGrid"]) {
        
        NSDictionary * PicGridDict = [info objectForKey:@"viewFramePicGrid"];
        CGRect cgframe  = CGRectMake([[PicGridDict objectForKey:@"x"] intValue], [[PicGridDict objectForKey:@"y"] intValue], [[PicGridDict objectForKey:@"w"] intValue], [[PicGridDict objectForKey:@"h"] intValue]);
        UexImageMySingleton * preImagesLeton = [UexImageMySingleton shareMySingLeton];
        preImagesLeton.PicGrid = cgframe;
        
    } else {
        
        CGRect cgframe = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,  [UIScreen mainScreen].bounds.size.height);
        UexImageMySingleton * preImagesLeton = [UexImageMySingleton shareMySingLeton];
        preImagesLeton.PicGrid = cgframe;
        
    }
    
    UIImageView * imageview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, 375, 667)];
    [HUPhotoBrowser showFromImageView:imageview withImages:bigImageURLArray atIndex:index];
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //    NSMutableArray *broweitemArray = [NSMutableArray arrayWithCapacity:3];
    //    for (int i = 0; i < smallImagePathArray.count; i ++) {
    //        MSSBrowseModel *browseItem = [[MSSBrowseModel alloc]init];
    //        browseItem.bigImageUrl = bigImageURLArray[i];
    //        browseItem.smallImagePath = smallImagePathArray[i];
    //        [broweitemArray addObject:browseItem];
    //    }
    //
    //    MSSBrowseNetworkViewController *bvc = [[MSSBrowseNetworkViewController alloc]initWithBrowseItemArray:broweitemArray currentIndex:index euexObjc:self Array:bigImageURLArray anType:AnimationTypeStr];
    //    bvc.isEqualRatio = NO;
    //    [EUtility brwView:self.meBrwView presentModalViewController:bvc animated:NO];
    
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

// save to Disk
- (NSString *)saveImage:(UIImage *)image quality:(CGFloat)quality usePng:(BOOL)usePng{
    NSData *imageData;
    NSString *imageSuffix;
    
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
