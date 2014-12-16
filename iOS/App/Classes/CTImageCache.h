
@class CTImageCacheObject;

@interface CTImageCache : NSObject {
    NSUInteger totalSize;  // total number of bytes
    NSUInteger maxSize;    // maximum capacity
    NSMutableDictionary *myDictionary;
}

@property (nonatomic, readonly) NSUInteger totalSize;

- (id) initWithMaxSize:(NSUInteger) max;
- (void) insertImage:(UIImage*)image withSize:(NSUInteger)sz forKey:(NSString*)key;
- (UIImage*) imageForKey:(NSString*)key;

@end