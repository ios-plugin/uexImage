//
//  uexImageBrowser.m
//  EUExImage
//
//  Created by CeriNo on 15/10/8.
//  Copyright © 2015年 AppCan. All rights reserved.
//

#import "uexImageBrowser.h"
#import "MWPhotoBrowser.h"
#import "NSObject+SBJSON.h"
#import "EUtility.h"

@interface uexImageBrowser()<MWPhotoBrowserDelegate>
@property (nonatomic,strong)MWPhotoBrowser * photoBrowser;
@property (nonatomic,strong)UINavigationController *navBrowser;
@property (nonatomic,strong)NSMutableArray<MWPhoto *> * photos;
@property (nonatomic,strong)NSArray<NSString *> * photosUrl;
@property (nonatomic,strong)NSMutableDictionary<NSString *,MWPhoto *> * thumbs;
@property (nonatomic,strong) NSString *imageUrl;

@end

@implementation uexImageBrowser



-(instancetype)initWithEUExImage:(EUExImage *)EUExImage{
    self=[super init];
    if(self) {
        self.EUExImage = EUExImage;
        self.photos = [NSMutableArray array];
        self.thumbs = [NSMutableDictionary dictionary];
        self.photosUrl = [NSMutableArray array];
    }
    return self;
}




-(void)open{
    if(!self.dataDict){
        return;
    }
    UEXIMAGE_ASYNC_DO_IN_MAIN_QUEUE(^{
        if([self setupBrowser]){
            
            if([self.dataDict objectForKey:@"startIndex"]){
                [self.photoBrowser setCurrentPhotoIndex:[[self.dataDict objectForKey:@"startIndex"] integerValue]];
            } else {
                [self.photoBrowser setCurrentPhotoIndex:0];
            }
            [self.EUExImage presentViewController:self.navBrowser animated:YES];

        }
    });
}


-(void)clean{
    self.dataDict=nil;
    [self.photos removeAllObjects];
    [self.thumbs removeAllObjects];
    self.cb = nil;
}


//长安手势方法；
- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture
{
//    if(gesture.state == UIGestureRecognizerStateBegan)
//    {
//        _imageUrl = @"/var/mobile/Containers/Data/Application/4A0A6071-C89C-4F15-ACD9-2E83DE738AAA/Documents/ios/im/imageuexim_99992_1528970615255.jpg";
//        NSString * indexImagePath = [self.EUExImage absPath:_imageUrl];
//
//        NSLog(@"++++++++++++++%@",indexImagePath);
//
//        NSDictionary * longDict = [NSDictionary dictionaryWithObjectsAndKeys:indexImagePath,@"imagePath",nil];
//
//        NSString * longImagePathStr = [longDict JSONFragment];
//
//        NSString *jsStr = [NSString stringWithFormat:@"if(uexImage.onImageLongClicked!=null){uexImage.onImageLongClicked('%@');}", longImagePathStr];
//
//        [EUtility brwView:self.EUExImage.meBrwView evaluateScript:jsStr];
//
////        NSLog(@"++长按回调++++++%@+++++回调内容:%@",leton.slectImage.meBrwView,jsStr);
//        //[leton.slectImage.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
//
//    }
    //MWPhotoBrowser *photoBrowser = (MWPhotoBrowser*)[Utils getSuperControllerWith:ges.view];
//    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",_imageUrl]]]];
    NSData *imageData=[[NSData alloc] initWithContentsOfFile:_imageUrl];
    //将二进制数据转成图片
    UIImage *image=[[UIImage alloc] initWithData:imageData];
    //只在begin执行一次
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long pressTap state :begin");
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"保存到相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertC addAction:action1];
        [alertC addAction:action2];
        [self.navBrowser presentViewController:alertC animated:YES completion:nil];
    }
    
}
    
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    
    id extraInfo =CFBridgingRelease(contextInfo);
    
    if([extraInfo isKindOfClass:[NSString class]]){
        [dict setValue:extraInfo forKey:@"extraInfo"];
    }
    
    if(error){
        [dict setValue:@(NO) forKey:cUexImageCallbackIsSuccessKey];
        [dict setValue:[error localizedDescription] forKey:@"errorStr"];
        UIAlertView *alerV = [[UIAlertView alloc]initWithTitle:@"提示" message:@"保存失败，请重试" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alerV show];
    }else{
        [dict setValue:@(YES) forKey:cUexImageCallbackIsSuccessKey];
        UIAlertView *alerV = [[UIAlertView alloc]initWithTitle:@"提示" message:@"保存成功" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alerV show];
    }
    [self.EUExImage.webViewEngine callbackWithFunctionKeyPath:@"uexImage.cbSaveToPhotoAlbum" arguments:ACArgsPack(dict.ac_JSONFragment)];
}




-(BOOL)setupBrowser{
    MWPhotoBrowser * browser =[[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton =NO;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.alwaysShowControls = NO;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid =YES;
    browser.startOnGrid = NO;
    browser.enableSwipeToDismiss = NO;
    //browser.autoPlayOnAppear = NO;
//    [browser setCurrentPhotoIndex:0];
    
    if([self.dataDict objectForKey:@"data"] && [[self.dataDict objectForKey:@"data"] isKindOfClass:[NSArray class]]){
        [self parsePhoto:[self.dataDict objectForKey:@"data"]];
    }
    if([self.dataDict objectForKey:@"displayActionButton"]){
        browser.displayActionButton = [[self.dataDict objectForKey:@"displayActionButton"] boolValue];
    }
    if([self.dataDict objectForKey:@"displayNavArrows"]){
        browser.displayNavArrows = [[self.dataDict objectForKey:@"displayNavArrows"] boolValue];
    }
    if([self.dataDict objectForKey:@"enableGrid"]){
        browser.enableGrid = [[self.dataDict objectForKey:@"enableGrid"] boolValue];
    }
    if([self.dataDict objectForKey:@"startOnGrid"]){
        browser.startOnGrid = [[self.dataDict objectForKey:@"startOnGrid"] boolValue];
    }

    self.photoBrowser = browser;
    self.navBrowser = [[UINavigationController alloc]initWithRootViewController:self.photoBrowser];
    
    return YES;
}



-(void)parsePhoto:(NSArray *)photoArray{
    self.photosUrl = photoArray;
    for(id photoInfo in photoArray){
        if([photoInfo isKindOfClass:[NSString class]]){
            MWPhoto *photo = [self photoFromString:photoInfo];
            if(photo){
                [self.photos addObject:photo];
            }
        }else if([photoInfo isKindOfClass:[NSDictionary class]]){
            MWPhoto *photo = [self photoFromString:photoInfo[@"src"]];
            if(photo){

                if([photoInfo objectForKey:@"thumb"]){
                    MWPhoto *thumb = [self photoFromString:[photoInfo objectForKey:@"thumb"]];
                    [self.thumbs setValue:thumb forKey:[@(self.photos.count) stringValue]];
                    
                }
                if([photoInfo objectForKey:@"desc"]&&[[photoInfo objectForKey:@"desc"] isKindOfClass:[NSString class]]){
                    photo.caption = [photoInfo objectForKey:@"desc"];
                }
                [self.photos addObject:photo];
                
            }
        }
    }
    
    
}

-(MWPhoto *)photoFromString:(NSString *)photoStr{
    if(!photoStr||[photoStr length] == 0){
        return nil;
    }
    NSString *clearPath = [photoStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    MWPhoto *photo = nil;
    if([[clearPath lowercaseString] hasPrefix:@"http"]){
        photo = [[MWPhoto alloc]initWithURL:[NSURL URLWithString:clearPath]];
        if(!photo){
            return nil;
        }

    }else{
        UIImage *image = [UIImage imageWithContentsOfFile:[self.EUExImage absPath:clearPath]];
        if(image){
           photo = [[MWPhoto alloc]initWithImage:image];
        }
        
    }
    return photo;
}


#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    return self.photos.count;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index{
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGesture:)];
    
    [photoBrowser.view addGestureRecognizer:longPressGesture];
    return (MWPhoto *)self.photos[index];

}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index{
    
    if([self.thumbs objectForKey:[@(index) stringValue]]){
        return (MWPhoto *)self.thumbs[[@(index) stringValue]];
    }
    return (MWPhoto *)self.photos[index];
}


//获取当前点击的图片
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index
{
    if (self.photosUrl.count > index){
        _imageUrl = self.photosUrl[index];
    }
//    _imageUrl = self.photosUrl[index];
}


- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser{
    [self.EUExImage dismissViewController:self.navBrowser animated:YES completion:^{
        [self.EUExImage.webViewEngine callbackWithFunctionKeyPath:@"uexImage.onBrowserClosed" arguments:nil];
        [self.cb executeWithArguments:nil];
        [self clean];
    }];



}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index{
    NSLog(@"点击");
}


@end
