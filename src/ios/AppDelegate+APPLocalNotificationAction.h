/*
 * AppDelegate+APPLocalNotificationAction.h
 *
 * Created by Elli Rego on 10/28/15.
 *
 */

 #import "AppDelegate.h"

 @interface AppDelegate (APPLocalNotificationAction)

// Handle notification actions
 - (void) application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotificiation:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler;

// Handle notification actions with response info
 - (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler;   

 @end