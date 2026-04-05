// Flutter.h - Compatibility header
#import <UIKit/UIKit.h>

// This is a simplified Flutter header for compatibility
// Do not modify manually

#ifndef Flutter_h
#define Flutter_h

@interface FlutterEngine : NSObject
@end

@interface FlutterViewController : UIViewController
@end

@interface FlutterPluginRegistrar : NSObject
@end

@interface FlutterMethodChannel : NSObject
@end

@interface FlutterBasicMessageChannel : NSObject
@end

@interface FlutterEventChannel : NSObject
@end

#endif /* Flutter_h */
