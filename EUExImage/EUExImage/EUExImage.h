//
//  EUExImage.h
//  EUExImage
//
//  Created by Cerino on 15/9/23.
//  Copyright © 2015年 AppCan. All rights reserved.
//




#import <Foundation/Foundation.h>
#import <AppCanKit/AppCanKit.h>

extern NSString * const cUexImageCallbackIsCancelledKey;
extern NSString * const cUexImageCallbackDataKey;
extern NSString * const cUexImageCallbackIsSuccessKey;




@interface EUExImage : EUExBase

@property(nonatomic,assign)BOOL isJudgePic;//是否拥有照片权限

-(void)presentViewController:(UIViewController *)vc animated:(BOOL)flag;
-(void)dismissViewController:(UIViewController *)vc
                    animated:(BOOL)flag
                  completion:(void (^)(void))completion;
-(NSString *)saveImage:(UIImage *)image quality:(CGFloat)quality usePng:(BOOL)usePng;
@end



@protocol EUExImageWidget <NSObject>

@required
-(instancetype)initWithEUExImage:(EUExImage*)EUExImage;
-(void)open;
-(void)clean;
@optional

@end
