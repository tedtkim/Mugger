//
//  MuggerAppDelegate.m
//  Mugger
//
//  Created by Ted Kim on 11/26/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "MuggerAppDelegate.h"
#import "MuggerAppDelegate+MOC.h"
#import "MuggerDatabaseNames.h"

@interface MuggerAppDelegate()
@property (strong, nonatomic) NSManagedObjectContext *muggerDatabaseContext;
@property (strong, nonatomic) UIManagedDocument *document;
@end

@implementation MuggerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self prepareContext];
    return YES;
}

#pragma mark - NSManagedDocument & database context

// the getter for the UIManagedDocument *document @property - single instance throughout app
- (UIManagedDocument *)document
{
    if (!_document) {
        static dispatch_once_t onceToken; // only gets executed once per application launch
        dispatch_once(&onceToken, ^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask] firstObject];
            NSURL *url = [documentsDirectory URLByAppendingPathComponent:MuggerDatabaseNamesDocument];
            _document = [[UIManagedDocument alloc] initWithFileURL:url];
        });
    }
    return _document;
}

- (void)prepareContext
{
    if (self.document) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self.document.fileURL path]]) {
            [self.document openWithCompletionHandler:^(BOOL success) {
                if (success && self.document.documentState == UIDocumentStateNormal) {
                    self.muggerDatabaseContext = self.document.managedObjectContext;
                } else {
                    NSLog(@"couldn't open document at %@", self.document.fileURL);
                }
            }];
        } else {
            [self.document saveToURL:self.document.fileURL
                    forSaveOperation:UIDocumentSaveForCreating
                   completionHandler:^(BOOL success) {
                       if (success && self.document.documentState == UIDocumentStateNormal) {
                           self.muggerDatabaseContext = self.document.managedObjectContext;
                       } else {
                           NSLog(@"couldn't create document at %@", self.document.fileURL);
                       }
                   }];
        }
    }
}

// When database context becomes available, we post a notification to let
// others know the context is available
- (void)setMuggerDatabaseContext:(NSManagedObjectContext *)muggerDatabaseContext
{
    _muggerDatabaseContext = muggerDatabaseContext;
    
    // let everyone who might be interested know this context is available
    NSDictionary *userInfo = self.muggerDatabaseContext ? @{ MuggerDatabaseNamesContext : self.muggerDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:MuggerDatabaseNamesNotification
                                                        object:self
                                                      userInfo:userInfo];
}


// Below are default app delegates to be used as needed

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
