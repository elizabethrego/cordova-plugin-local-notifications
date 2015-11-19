/*
 * AppDelegate+APPLocalNotificationAction.m
 *
 * Created by Elli Rego on 10/28/15.
 *
 */

 #import "AppDelegate+APPLocalNotificationAction.h"

 @implementation AppDelegate (APPLocalNotificationAction)

/**
 * Handle notification actions.
 */
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler
 {
 	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:notification forKey:@"localNotification"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendActionIdentifier" object:identifier userInfo:userInfo];
    
    completionHandler();
 }

/**
 * Handle notification actions with response info.
 */
 - (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler   
{   
    // responseInfo contains the text that the user typed on the notification! Yay! Something actually works!   
    NSLog(@"iOS App id=%@, msg=%@", identifier, responseInfo);   

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:notification, @"localNotification", responseInfo, @"responseInfo", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendActionIdentifierWithResponseInfo" object:identifier userInfo:userInfo];
  
    completionHandler();   
}  

 @end