//
//  uexImageCropper.m
//  EUExImage
//
//  Created by CeriNo on 15/9/29.
//  Copyright © 2015年 AppCan. All rights reserved.
//

#import "uexImageCropper.h"

@interface uexImageCropper()<RSKImageCropViewControllerDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,RSKImageCropViewControllerDataSource>
@property (nonatomic,strong)RSKImageCropViewController *cropper;

@end


@implementation uexImageCropper
-(instancetype)initWithEUExImage:(EUExImage *)EUExImage{
    self=[super init];
    if(self) {
        self.EUExImage = EUExImage;
        self.imageToBeCropped = nil;
        self.quality = 0.5;
        self.shape = uexImageCropShapeSquare;
    }
    return self;
}




-(void)open{
    if(self.imageToBeCropped){
        [self openCropper];
    }else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        picker.mediaTypes = @[@"public.image"];

        [self.EUExImage presentViewController:picker animated:NO];
    }

}
-(void)clean{
    self.imageToBeCropped = nil;
    self.quality = 0.5;
    self.shape = uexImageCropShapeSquare;
    self.cropper = nil;
}



-(void)openCropper{
    RSKImageCropMode mode = RSKImageCropModeSquare;
    switch (self.shape) {
        case uexImageCropShapeSquare:
            mode = RSKImageCropModeSquare;
            break;
        case uexImageCropShapeCircle:
            mode = RSKImageCropModeCircle;
            break;
        case uexImageCropShapeRect4x3:
        case uexImageCropShapeRect16x9:
            mode = RSKImageCropModeCustom;
            break;
        default:
            break;
    }
    RSKImageCropViewController * cropper = [[RSKImageCropViewController alloc]initWithImage:self.imageToBeCropped cropMode:mode];
    cropper.delegate = self;
    cropper.dataSource = self;
    self.cropper = cropper;
    [self.EUExImage presentViewController:cropper animated:YES];


}
#pragma mark - RSKImageCropViewControllerDataSource

static CGFloat kMaskRectMinimumPadding = 20;

/**
 Asks the data source a custom rect for the mask.
 
 @param controller The crop view controller object to whom a rect is provided.
 
 @return A custom rect for the mask.
 
 @discussion Only valid if `cropMode` is `RSKImageCropModeCustom`.
 */
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = MIN(screenSize.width, screenSize.height) - 2 * kMaskRectMinimumPadding;
    CGFloat height = 0;
    
    switch (self.shape) {
        case uexImageCropShapeRect4x3:
            height = width * 3 / 4 ;
            
            break;
        case uexImageCropShapeRect16x9:
            height = width * 9 / 16 ;
            break;
        default:
            width = 0;
            break;
    }
    return CGRectMake(kMaskRectMinimumPadding, screenSize.height / 2 - height / 2, width, height);
}

/**
 Asks the data source a custom path for the mask.
 
 @param controller The crop view controller object to whom a path is provided.
 
 @return A custom path for the mask.
 
 @discussion Only valid if `cropMode` is `RSKImageCropModeCustom`.
 */
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller{
    return [UIBezierPath bezierPathWithRect:controller.maskRect];
}



/**
 Asks the data source a custom rect in which the image can be moved.
 
 @param controller The crop view controller object to whom a rect is provided.
 
 @return A custom rect in which the image can be moved.
 
 @discussion Only valid if `cropMode` is `RSKImageCropModeCustom`. If you want to support the rotation  when `cropMode` is `RSKImageCropModeCustom` you must implement it. Will be marked as `required` in version `2.0.0`.
 */
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller{
    return controller.maskRect;
}



#pragma mark - RSKImageCropViewControllerDelegate;
/**
 Tells the delegate that crop image has been canceled.
 */
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller{
    [self.EUExImage dismissViewController:controller animated:YES completion:^{
        NSDictionary *result = @{cUexImageCallbackIsCancelledKey:@(YES)};
        [self.EUExImage.webViewEngine callbackWithFunctionKeyPath:@"uexImage.onCropperClosed" arguments:ACArgsPack(result.ac_JSONFragment)];
        [self.cb executeWithArguments:ACArgsPack(uexErrorMake(-1),result)];
        [self clean];
    }];

}


/**
 Tells the delegate that the original image has been cropped. Additionally provides a crop rect and a rotation angle used to produce image.
 */
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle{
    UEXIMAGE_ASYNC_DO_IN_GLOBAL_QUEUE(^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@(NO) forKey:cUexImageCallbackIsCancelledKey];
        NSString *path = [self.EUExImage saveImage:croppedImage quality:self.quality usePng:self.usePng];
        [dict setValue:path forKey:cUexImageCallbackDataKey];
        UEX_ERROR error = path? kUexNoError : uexErrorMake(1,@"save image failed");
        
        
        [self.EUExImage dismissViewController:controller animated:YES completion:^{
            
            [self.EUExImage.webViewEngine callbackWithFunctionKeyPath:@"uexImage.onCropperClosed" arguments:ACArgsPack(dict.ac_JSONFragment)];
            [self.cb executeWithArguments:ACArgsPack(error,dict)];
            [self clean];
        }];
    });
  
    
    
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UEXIMAGE_ASYNC_DO_IN_GLOBAL_QUEUE(^{
        NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
        NSLog(@"url是=======%@",url);
        UIImage *checkImg= [info objectForKey:UIImagePickerControllerOriginalImage];
        self.imageToBeCropped=checkImg;
        [self.EUExImage dismissViewController:picker animated:YES completion:^{
            
            [self openCropper];
        }];
    });
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.EUExImage dismissViewController:picker animated:YES completion:^{
        UEX_ERROR error = uexErrorMake(-1);
        NSDictionary *dict = @{cUexImageCallbackIsCancelledKey:@(YES)};
        [self.EUExImage.webViewEngine callbackWithFunctionKeyPath:@"uexImage.onCropperClosed" arguments:ACArgsPack(dict.ac_JSONFragment)];
        [self.cb executeWithArguments:ACArgsPack(error,dict)];
        [self clean];
    }];


}
@end
