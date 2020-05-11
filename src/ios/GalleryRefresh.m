#import "GalleryRefresh.h"
#import <Cordova/CDV.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@implementation GalleryRefresh
@synthesize callbackId;

- (void)refresh:(CDVInvokedUrlCommand*)command
{
    [self performSelectorInBackground:@selector(saveImage2Gallery:) withObject:command];
}

- (void)createAlbum:(CDVInvokedUrlCommand*)command
{
    [self performSelectorInBackground:@selector(createAlbumWith:) withObject:command];
}

- (void)createAlbumWith:(CDVInvokedUrlCommand*)command
{
    NSString* albumName = [command.arguments objectAtIndex:0];
    if ([self findAlbumAssetCollection:albumName] == nil) {
        // create the album if it doesn't exist
        __block PHObjectPlaceholder *myAlbum;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *albumRequest;
            albumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            myAlbum = albumRequest.placeholderForCreatedAssetCollection;
        } completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                [self callbackToAppResultWithStatus:CDVCommandStatus_OK :@"Created album." :command];
            } else {
                NSLog(@"Error: %@", error);
                [self callbackToAppResultWithStatus:CDVCommandStatus_ERROR :error.description :command];
            }
        }];
        
    } else {
        // otherwise request to change the existing album
        [self callbackToAppResultWithStatus:CDVCommandStatus_OK :@"Created album." :command];
    }
}

- (void)saveImage2Gallery:(CDVInvokedUrlCommand*)command
{
    NSString* albumName = [command.arguments objectAtIndex:1];
    NSString* imgPath = [command.arguments objectAtIndex:0];
    
    dispatch_queue_t queue = dispatch_queue_create("com.hmx.saveToCameraRoll", NULL);
    dispatch_async(queue, ^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        UIImage *image = [UIImage imageWithData:UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:imgPath ], 1)];
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *albumRequest;
            PHObjectPlaceholder *placeholder = [[PHAssetChangeRequest creationRequestForAssetFromImage:image] placeholderForCreatedAsset];
            
            if ([self findAlbumAssetCollection:albumName] == nil) {
                // create the album if it doesn't exist
                albumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            } else {
                // otherwise request to change the existing album
                albumRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[self findAlbumAssetCollection:albumName]];
            }
            
            [albumRequest addAssets:@[placeholder]];
        } completionHandler:^(BOOL success, NSError *error) {
            
            if (success){
                NSLog(@"Finish: %@", success ? @"YES" : @"NO");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self callbackToAppResultWithStatus:CDVCommandStatus_OK :@"Image saved" :command];
                });
            }
            else{
                NSLog(@"Error: %@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self callbackToAppResultWithStatus:CDVCommandStatus_ERROR :error.description :command];
                });
            }
            
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    });
    
}

-(void)callbackToAppResultWithStatus:(CDVCommandStatus)status :(NSString*)message :(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:status messageAsString:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(PHAssetCollection*)findAlbumAssetCollection:(NSString*)albumName{
    PHAssetCollection *collection;
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title = %@", albumName];
    collection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                          subtype:PHAssetCollectionSubtypeAny
                                                          options:fetchOptions].firstObject;
    return collection;
}


@end
