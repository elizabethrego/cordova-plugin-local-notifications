/*
 * Copyright (c) 2013-2015 by appPlant UG. All rights reserved.
 *
 * @APPPLANT_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apache License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://opensource.org/licenses/Apache-2.0/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPPLANT_LICENSE_HEADER_END@
 */

#import "APPLocalNotification.h"
#import "APPLocalNotificationOptions.h"
#import "UIApplication+APPLocalNotification.h"
#import "UILocalNotification+APPLocalNotification.h"
#import "AppDelegate+APPRegisterUserNotificationSettings.h"

@interface APPLocalNotification ()

// Retrieves the application state
@property (readonly, getter=applicationState) NSString* applicationState;
// All events will be queued until deviceready has been fired
@property (readwrite, assign) BOOL deviceready;
// Event queue
@property (readonly, nonatomic, retain) NSMutableArray* eventQueue;
// Needed when calling `registerPermission`
@property (nonatomic, retain) CDVInvokedUrlCommand* command;

@end

@implementation APPLocalNotification

@synthesize deviceready, eventQueue;

#pragma mark -
#pragma mark Interface

/**
 * Execute all queued events.
 */
- (void) deviceready:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - deviceready\rLINE 53\r");
    deviceready = YES;

    for (NSString* js in eventQueue) {
        NSLog(@"\r\rValue of js = %@\r\r", js);
        [self.commandDelegate evalJs:js];
    }

    [eventQueue removeAllObjects];
}

/**
 * Schedule a set of notifications.
 *
 * @param properties
 *      A dict of properties for each notification
 */
- (void) schedule:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - schedule\rLINE 70\r");

    NSArray* notifications = command.arguments;

    [self.commandDelegate runInBackground:^{
        for (NSDictionary* options in notifications) {
            UILocalNotification* notification;

            notification = [[UILocalNotification alloc]
                            initWithOptions:options];

            [self scheduleLocalNotification:[notification copy]];
            [self fireEvent:@"schedule" notification:notification];

            if (notifications.count > 1) {
                [NSThread sleepForTimeInterval:0.01];
            }
        }

        [self execCallback:command];
    }];
}

/**
 * Update a set of notifications.
 *
 * @param properties
 *      A dict of properties for each notification
 */
- (void) update:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - update\rLINE 99\r");

    NSArray* notifications = command.arguments;

    [self.commandDelegate runInBackground:^{
        for (NSDictionary* options in notifications) {
            NSNumber* id = [options objectForKey:@"id"];
            UILocalNotification* notification;

            notification = [self.app localNotificationWithId:id];

            if (!notification)
                continue;

            [self updateLocalNotification:[notification copy]
                              withOptions:options];

            [self fireEvent:@"update" notification:notification];

            if (notifications.count > 1) {
                [NSThread sleepForTimeInterval:0.01];
            }
        }

        [self execCallback:command];
    }];
}

/**
 * Cancel a set of notifications.
 *
 * @param ids
 *      The IDs of the notifications
 */
- (void) cancel:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - cancel\rLINE 133\r");

    [self.commandDelegate runInBackground:^{
        for (NSNumber* id in command.arguments) {
            UILocalNotification* notification;

            notification = [self.app localNotificationWithId:id];

            if (!notification)
                continue;

            [self.app cancelLocalNotification:notification];
            [self fireEvent:@"cancel" notification:notification];
        }

        [self execCallback:command];
    }];
}

/**
 * Cancel all local notifications.
 */
- (void) cancelAll:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - cancelAll\rLINE 155\r");

    [self.commandDelegate runInBackground:^{
        [self cancelAllLocalNotifications];
        [self fireEvent:@"cancelall"];
        [self execCallback:command];
    }];
}

/**
 * Clear a set of notifications.
 *
 * @param ids
 *      The IDs of the notifications
 */
- (void) clear:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - clear\rLINE 170\r");

    [self.commandDelegate runInBackground:^{
        for (NSNumber* id in command.arguments) {
            UILocalNotification* notification;

            notification = [self.app localNotificationWithId:id];

            if (!notification)
                continue;

            [self.app clearLocalNotification:notification];
            [self fireEvent:@"clear" notification:notification];
        }

        [self execCallback:command];
    }];
}

/**
 * Clear all local notifications.
 */
- (void) clearAll:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - clearAll\rLINE 192\r");

    [self.commandDelegate runInBackground:^{
        [self clearAllLocalNotifications];
        [self fireEvent:@"clearall"];
        [self execCallback:command];
    }];
}

/**
 * If a notification by ID is present.
 *
 * @param id
 *      The ID of the notification
 */
- (void) isPresent:(CDVInvokedUrlCommand *)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - isPresent\rLINE 207\r");

    [self isPresent:command type:NotifcationTypeAll];
}

/**
 * If a notification by ID is scheduled.
 *
 * @param id
 *      The ID of the notification
 */
- (void) isScheduled:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - isScheduled\rLINE 218\r");

    [self isPresent:command type:NotifcationTypeScheduled];
}

/**
 * Check if a notification with an ID is triggered.
 *
 * @param id
 *      The ID of the notification
 */
- (void) isTriggered:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - isTriggered\rLINE 229\r");

    [self isPresent:command type:NotifcationTypeTriggered];
}

/**
 * Check if a notification with an ID exists.
 *
 * @param type
 *      The notification life cycle type
 */
- (void) isPresent:(CDVInvokedUrlCommand*)command
              type:(APPLocalNotificationType)type;
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - isPresent\rLINE 240\r");

    [self.commandDelegate runInBackground:^{
        NSNumber* id = [command argumentAtIndex:0];
        BOOL exist;

        CDVPluginResult* result;

        if (type == NotifcationTypeAll) {
            exist = [self.app localNotificationExist:id];
        } else {
            exist = [self.app localNotificationExist:id type:type];
        }

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                     messageAsBool:exist];

        [self.commandDelegate sendPluginResult:result
                                    callbackId:command.callbackId];
    }];
}

/**
 * List all ids from all local notifications.
 */
- (void) getAllIds:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getAllIds\rLINE 266\r");

    [self getIds:command byType:NotifcationTypeAll];
}

/**
 * List all ids from all pending notifications.
 */
- (void) getScheduledIds:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getScheduledIds\rLINE 274\r");

    [self getIds:command byType:NotifcationTypeScheduled];
}

/**
 * List all ids from all triggered notifications.
 */
- (void) getTriggeredIds:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getTriggeredIds\rLINE 282\r");

    [self getIds:command byType:NotifcationTypeTriggered];
}

/**
 * List of ids for given local notifications.
 *
 * @param type
 *      Notification life cycle type
 * @param ids
 *      The IDs of the notifications
 */
- (void) getIds:(CDVInvokedUrlCommand*)command
         byType:(APPLocalNotificationType)type;
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getIds:byType\rLINE 295\r");

    [self.commandDelegate runInBackground:^{
        CDVPluginResult* result;
        NSArray* ids;

        if (type == NotifcationTypeAll) {
            ids = [self.app localNotificationIds];
        } else {
            ids = [self.app localNotificationIdsByType:type];
        }

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                    messageAsArray:ids];

        [self.commandDelegate sendPluginResult:result
                                    callbackId:command.callbackId];
    }];
}

/**
 * Propertys for given local notification.
 */
- (void) getSingle:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getSingle\rLINE 319\r");

    [self getOption:command byType:NotifcationTypeAll];
}

/**
 * Propertya for given scheduled notification.
 */
- (void) getSingleScheduled:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getSingleScheduled\rLINE 327\r");

    [self getOption:command byType:NotifcationTypeScheduled];
}

// Propertys for given triggered notification
- (void) getSingleTriggered:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getSingleTriggered\rLINE 333\r");

    [self getOption:command byType:NotifcationTypeTriggered];
}

/**
 * Property list for given local notifications.
 *
 * @param ids
 *      The IDs of the notifications
 */
- (void) getAll:(CDVInvokedUrlCommand*)command
{

    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getAll\rLINE 344\r");
    [self getOptions:command byType:NotifcationTypeAll];
}

/**
 * Property list for given scheduled notifications.
 *
 * @param ids
 *      The IDs of the notifications
 */
- (void) getScheduled:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getScheduled\rLINE 355\r");

    [self getOptions:command byType:NotifcationTypeScheduled];
}

/**
 * Property list for given triggered notifications.
 *
 * @param ids
 *      The IDs of the notifications
 */
- (void) getTriggered:(CDVInvokedUrlCommand *)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getTriggered\rLINE 366\r");

    [self getOptions:command byType:NotifcationTypeTriggered];
}

/**
 * Propertys for given triggered notification.
 *
 * @param type
 *      Notification life cycle type
 * @param ids
 *      The ID of the notification
 */
- (void) getOption:(CDVInvokedUrlCommand*)command
            byType:(APPLocalNotificationType)type;
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getOption:byType:\rLINE 379\r");

    [self.commandDelegate runInBackground:^{
        NSArray* ids = command.arguments;
        NSArray* notifications;
        CDVPluginResult* result;

        if (type == NotifcationTypeAll) {
            notifications = [self.app localNotificationOptionsById:ids];
        }
        else {
            notifications = [self.app localNotificationOptionsByType:type
                                                               andId:ids];
        }

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                    messageAsDictionary:notifications[0]];

        [self.commandDelegate sendPluginResult:result
                                    callbackId:command.callbackId];
    }];
}

/**
 * Property list for given triggered notifications.
 *
 * @param type
 *      Notification life cycle type
 * @param ids
 *      The IDs of the notifications
 */
- (void) getOptions:(CDVInvokedUrlCommand*)command
             byType:(APPLocalNotificationType)type;
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - getOptions:byType\rLINE 411\r");

    [self.commandDelegate runInBackground:^{
        NSArray* ids = command.arguments;
        NSArray* notifications;
        CDVPluginResult* result;

        if (type == NotifcationTypeAll && ids.count == 0) {
            notifications = [self.app localNotificationOptions];
        }
        else if (type == NotifcationTypeAll) {
            notifications = [self.app localNotificationOptionsById:ids];
        }
        else if (ids.count == 0) {
            notifications = [self.app localNotificationOptionsByType:type];
        }
        else {
            notifications = [self.app localNotificationOptionsByType:type
                                                               andId:ids];
        }

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                    messageAsArray:notifications];

        [self.commandDelegate sendPluginResult:result
                                    callbackId:command.callbackId];
    }];
}

/**
 * Inform if the app has the permission to show
 * badges and local notifications.
 */
- (void) hasPermission:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - hasPermission\rLINE 445\r");

    [self.commandDelegate runInBackground:^{
        CDVPluginResult* result;
        BOOL hasPermission;

        hasPermission = [self.app hasPermissionToScheduleLocalNotifications];

        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                     messageAsBool:hasPermission];

        [self.commandDelegate sendPluginResult:result
                                    callbackId:command.callbackId];
    }];
}

/**
 * Ask for permission to show badges.
 */
- (void) registerPermission:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - registerPermission\rLINE 464\r");

    if ([[UIApplication sharedApplication]
         respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        _command = command;

        NSArray* interactions = command.arguments;
        //NSLog(@"VALUE OF ACTIONSARRAY (1st): %@", actionsArray);
        //NSString* actions = [actionsArray objectAtIndex:0];
        //NSLog(@"VALUE OF ACTIONS (1st): %@", actions);

        [self.commandDelegate runInBackground:^{
            [self.app registerPermissionToScheduleLocalNotifications:interactions];
        }];
    } else {
        [self hasPermission:command];
    }
}

#pragma mark -
#pragma mark Core Logic

/**
 * Schedule the local notification.
 */
- (void) scheduleLocalNotification:(UILocalNotification*)notification
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - scheduleLocalNotification\rLINE 485\r");

    [self cancelForerunnerLocalNotification:notification];
    [self.app scheduleLocalNotification:notification];
}

/**
 * Update the local notification.
 */
- (void) updateLocalNotification:(UILocalNotification*)notification
                     withOptions:(NSDictionary*)newOptions
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - updateLocalNotification:withOptions\rLINE 494\r");

    NSMutableDictionary* options = [notification.userInfo mutableCopy];

    [options addEntriesFromDictionary:newOptions];
    [options setObject:[NSDate date] forKey:@"updatedAt"];

    notification = [[UILocalNotification alloc]
                    initWithOptions:options];

    [self scheduleLocalNotification:notification];
}

/**
 * Cancel all local notifications.
 */
- (void) cancelAllLocalNotifications
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - cancelAllLocalNotifications\rLINE 511\r");

    [self.app cancelAllLocalNotifications];
    [self.app setApplicationIconBadgeNumber:0];
}

/**
 * Clear all local notifications.
 */
- (void) clearAllLocalNotifications
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - clearAllLocalNotifications\rLINE 520\r");

    [self.app clearAllLocalNotifications];
    [self.app setApplicationIconBadgeNumber:0];
}

/**
 * Cancel a maybe given forerunner with the same ID.
 */
- (void) cancelForerunnerLocalNotification:(UILocalNotification*)notification
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - cancelForerunnerLocalNotification\rLINE 529\r");

    NSNumber* id = notification.options.id;
    UILocalNotification* forerunner;

    forerunner = [self.app localNotificationWithId:id];

    if (!forerunner)
        return;

    [self.app cancelLocalNotification:forerunner];
}

/**
 * Cancels all non-repeating local notification older then
 * a specific amount of seconds
 */
- (void) cancelAllNotificationsWhichAreOlderThen:(float)seconds
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - cancelAllNotificationsWhichAreOlderThen\rLINE 546\r");

    NSArray* notifications;

    notifications = [self.app localNotifications];

    for (UILocalNotification* notification in notifications)
    {
        if (![notification isRepeating]
            && notification.timeIntervalSinceFireDate > seconds)
        {
            [self.app cancelLocalNotification:notification];
            [self fireEvent:@"cancel" notification:notification];
        }
    }
}

#pragma mark -
#pragma mark Delegates

/**
 * Calls the cancel or trigger event after a local notification was received.
 * Cancels the local notification if autoCancel was set to true.
 */
- (void) didReceiveLocalNotification:(NSNotification*)localNotification
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - didReceiveLocalNotification\rLINE 570\r");

    UILocalNotification* notification = [localNotification object];

    if ([notification wasUpdated])
        return;

    NSTimeInterval timeInterval = [notification timeIntervalSinceLastTrigger];

    NSString* event = (timeInterval <= 1 && deviceready) ? @"trigger" : @"click";
    NSLog(@"\r\rValue of event = %@\r\r", event);

    [self fireEvent:event notification:notification];

    if (![event isEqualToString:@"click"]) 
        return;

    if ([notification isRepeating]) {
        [self fireEvent:@"clear" notification:notification];
    } else {
        [self.app cancelLocalNotification:notification];
        [self fireEvent:@"cancel" notification:notification];
    }
}

/**
 * Called when app has started
 * (by clicking on a local notification).
 */
- (void) didFinishLaunchingWithOptions:(NSNotification*)notification
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - didFinishLaunchingWithOptions\rLINE 598\r");

    NSDictionary* launchOptions = [notification userInfo];

    UILocalNotification* localNotification;

    localNotification = [launchOptions objectForKey:
                         UIApplicationLaunchOptionsLocalNotificationKey];

    if (localNotification) {
        [self didReceiveLocalNotification:
         [NSNotification notificationWithName:CDVLocalNotification
                                       object:localNotification]];
    }
}

/**
 * Called on otification settings registration is completed.
 */
- (void) didRegisterUserNotificationSettings:(UIUserNotificationSettings*)settings
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - didRegisterUserNotificationSettings\rLINE 617\r");

    if (_command)
    {
        [self hasPermission:_command];
        _command = NULL;
    }
}

#pragma mark -
#pragma mark Life Cycle

/**
 * Registers obervers after plugin was initialized.
 */
- (void) pluginInitialize
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - pluginInitialize\rLINE 632\r");

    NSNotificationCenter* center = [NSNotificationCenter
                                    defaultCenter];

    eventQueue = [[NSMutableArray alloc] init];

    [center addObserver:self
               selector:@selector(didReceiveLocalNotification:)
                   name:CDVLocalNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(didFinishLaunchingWithOptions:)
                   name:UIApplicationDidFinishLaunchingNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(didRegisterUserNotificationSettings:)
                   name:UIApplicationRegisterUserNotificationSettings
                 object:nil];

    [center addObserver:self
               selector:@selector(handleNotificationAction:)
                   name:@"SendActionIdentifier"
                 object:nil];
}

/**
 * Clears all single repeating notifications which are older then 5 days
 * before the app terminates.
 */
- (void) onAppTerminate
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - onAppTerminate\rLINE 659\r");

    [self cancelAllNotificationsWhichAreOlderThen:432000];
}

#pragma mark -
#pragma mark Helper

/**
 * Retrieves the application state
 *
 * @return
 *      Either "background" or "foreground"
 */
- (NSString*) applicationState
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - applicationState\rLINE 673\r");

    UIApplicationState state = [self.app applicationState];

    bool isActive = state == UIApplicationStateActive;

    return isActive ? @"foreground" : @"background";
}

/**
 * Simply invokes the callback without any parameter.
 */
- (void) execCallback:(CDVInvokedUrlCommand*)command
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - execCallback\rLINE 685\r");

    CDVPluginResult *result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:result
                                callbackId:command.callbackId];
}

/**
 * Short hand for shared application instance.
 */
- (UIApplication*) app
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - app\rLINE 697\r");

    return [UIApplication sharedApplication];
}

/**
 * Fire general event.
 */
- (void) fireEvent:(NSString*)event
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - fireEvent\rLINE 705\r");

    [self fireEvent:event notification:NULL];
}

/**
 * Fire event for local notification.
 */
- (void) fireEvent:(NSString*)event notification:(UILocalNotification*)notification
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - fireEvent:notification\rLINE 713\r");

    [self fireEvent:event notification:notification data:NULL];
}

/**
 * Fire event for local notification with data.
 */
- (void) fireEvent:(NSString*)event notification:(UILocalNotification*)notification data:(NSString*)data
{
    NSLog(@"\r\rDEBUG-LOG APPLocalNotification - fireEvent:notification:data\rLINE 713\r");

    NSString* js;
    NSString* params = [NSString stringWithFormat:
                        @"\"%@\"", self.applicationState];

    if (notification) {
        NSString* args = [notification encodeToJSON];

        if (data) {
            params = [NSString stringWithFormat:
                  @"%@,'%@','%@'",
                  args, self.applicationState, data];
        } else {
            params = [NSString stringWithFormat:
                      @"%@,'%@'",
                      args, self.applicationState];
        }
    }

    js = [NSString stringWithFormat:
          @"cordova.plugins.notification.local.core.fireEvent('%@', %@)",
          event, params];

    NSLog(@"\r\rVALUE OF JS: %@\r\r", js);

    if (deviceready) {
        NSLog(@"\r\rDevice is ready\r\r");
        [self.commandDelegate evalJs:js];
    } else {
        NSLog(@"\r\rDevice is NOT ready\r\r");
        [self.eventQueue addObject:js];
    }
}

 /**
 * Get notification identifier to send to JS.
 */
 - (void) handleNotificationAction:(NSNotification*)notification
 {
    NSString* identifier = [notification object];

    NSLog(@"\r\rVALUE OF identifier: %@\r\r", identifier);

    NSDictionary *userInfo = notification.userInfo;
    UILocalNotification *localNotification = [userInfo objectForKey:@"localNotification"];

    [self fireEvent:@"action" notification:localNotification data:identifier];
 }

@end
