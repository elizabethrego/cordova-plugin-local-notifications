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

 @end