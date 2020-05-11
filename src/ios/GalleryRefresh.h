#import <Cordova/CDVPlugin.h>

@interface GalleryRefresh : CDVPlugin {
  NSString* callbackId;
}

@property (nonatomic, copy) NSString* callbackId;

- (void)refresh:(CDVInvokedUrlCommand*)command;
- (void)createAlbum:(CDVInvokedUrlCommand*)command;

@end
