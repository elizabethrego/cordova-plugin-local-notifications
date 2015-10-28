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

#import "UIApplication+APPLocalNotification.h"
#import "UILocalNotification+APPLocalNotification.h"

@implementation UIApplication (APPLocalNotification)

NSMutableDictionary *allNotificationActions = nil;
NSMutableDictionary *allNotificationCategories = nil;  //these def need to be mutable

#pragma mark -
#pragma mark Permissions

/**
 * If the app has the permission to schedule local notifications.
 */
- (BOOL) hasPermissionToScheduleLocalNotifications
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - hasPermissionToScheduleLocalNotifications\rLINE 35\r");

    if ([[UIApplication sharedApplication]
         respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType types;
        UIUserNotificationSettings *settings;

        settings = [[UIApplication sharedApplication]
                    currentUserNotificationSettings];

        types = UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound;

        return (settings.types & types);
    } else {
        return YES;
    }
}

/**
 * Ask for permission to schedule local notifications.
 */
- (void) registerPermissionToScheduleLocalNotifications:(NSArray*)interactions
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - registerPermissionToScheduleLocalNotifications\rLINE 57\r");

    if ([[UIApplication sharedApplication]
         respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType types;
        UIUserNotificationSettings *settings;

        settings = [[UIApplication sharedApplication]
                    currentUserNotificationSettings];

        types = settings.types|UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound;
        
        NSSet* categories = [self processNotificationInteractions:interactions];
        
        settings = [UIUserNotificationSettings settingsForTypes:types
                                                     categories:categories];

        [[UIApplication sharedApplication]
         registerUserNotificationSettings:settings];
    }
}

/**
 * Persist all actions and categories for notifications, adding new ones if necessary.
 */
- (NSSet*) processNotificationInteractions:(NSArray*)interactions
{
            if (!allNotificationActions) {
            allNotificationActions = [[NSMutableDictionary alloc] init];
        }
        
        if (!allNotificationCategories) {
            allNotificationCategories = [[NSMutableDictionary alloc] init];
        }

        if (interactions && [interactions count])
        {
            for (NSString* interaction in interactions)
            {
                NSData* interactionsData = [interaction dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary* interactionsArray = [NSJSONSerialization JSONObjectWithData:interactionsData options:NSJSONReadingMutableContainers error:nil];

                NSLog(@"VALUE OF INTERACTIONSARRAY: %@", interactionsArray);

                NSArray* actions = [interactionsArray objectForKey:@"actions"];
                NSString* category = [interactionsArray objectForKey:@"category"];
                
                // Redundant: already checking in local-notification-core.js
                if ([actions count] && category.length) {
                    NSLog(@"\r\rVALUE OF ACTIONS: %@", actions);
                    NSLog(@"\r\rVALUE OF CATEGORY: %@", category);
                    
                    if (![allNotificationCategories objectForKey:category]) // category doesn't already exist
                    {
                        UIMutableUserNotificationCategory* newCategory;
                        newCategory = [[UIMutableUserNotificationCategory alloc] init];
                        [newCategory setIdentifier:category];
                        
                        NSMutableArray* actionsArray; // should be array
                        actionsArray = [[NSMutableArray alloc] init];
                        
                        for (NSDictionary* action in actions)
                        {
                            // don't break the app if the action is invalid, just don't add the action
                            if ([action isKindOfClass:[NSDictionary class]])
                            {
                                NSString* actionIdent = [action objectForKey:@"identifier"];
                                UIMutableUserNotificationAction* existingAction = [allNotificationActions objectForKey:actionIdent];
                                if (!existingAction) // action doesn't already exist
                                {
                                    UIMutableUserNotificationAction* newAction = [[UIMutableUserNotificationAction alloc] init];
                                    [newAction setActivationMode:[[action objectForKey:@"activationMode"]  isEqual: @"background"]
                                        ? UIUserNotificationActivationModeBackground : UIUserNotificationActivationModeForeground];
                                    [newAction setTitle:[action objectForKey:@"title"]];
                                    [newAction setIdentifier:actionIdent];
                                    [newAction setDestructive:[[action objectForKey:@"destructive"] boolValue]];
                                    [newAction setAuthenticationRequired:[[action objectForKey:@"authenticationRequired"] boolValue]];
                                
                                    // Add action to persisted dictionary
                                    [allNotificationActions setObject:newAction forKey:actionIdent];
                                
                                
                                    NSLog(@"\r\rNEW ACTION: %@\r\r", newAction);
                                } else {
                                    NSLog(@"\r\rEXISTING ACTION: %@\r\r", existingAction);
                                }
                            
                                // Add action from persisted dictionary to array
                                [actionsArray addObject:[allNotificationActions objectForKey:actionIdent]];
                            }
                        }
                        NSLog(@"VALUE OF ACTIONSARRAY: %@", actionsArray);
                        
                        if ([actionsArray count] > 2)
                        {
                            [newCategory setActions:@[[actionsArray objectAtIndex:1], [actionsArray objectAtIndex:0]] forContext:UIUserNotificationActionContextMinimal];
                        } else {
                            [newCategory setActions:[[actionsArray reverseObjectEnumerator] allObjects] forContext:UIUserNotificationActionContextMinimal];
                        }
                        [newCategory setActions:actionsArray forContext:UIUserNotificationActionContextDefault];
                        [allNotificationCategories setObject:newCategory forKey: category];
                    }
                }
            }
        }
        
        NSSet* categories = [NSSet setWithArray:[allNotificationCategories allValues]];

        NSLog(@"VALUE OF CATEGORIES: %@", categories);

        return categories;
}

#pragma mark -
#pragma mark LocalNotifications

/**
 * List of all local notifications which have been added
 * but not yet removed from the notification center.
 */
- (NSArray*) localNotifications
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotifications\rLINE 85\r");

    NSArray* scheduledNotifications = self.scheduledLocalNotifications;
    NSMutableArray* notifications = [[NSMutableArray alloc] init];

    for (UILocalNotification* notification in scheduledNotifications)
    {
        if (notification) {
            [notifications addObject:notification];
        }
    }

    return notifications;
}

/**
 * List of all triggered local notifications which have been scheduled
 * and not yet removed the notification center.
 */
- (NSArray*) triggeredLocalNotifications
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - triggeredLocalNotifications\rLINE 104\r");

    NSArray* notifications = self.localNotifications;
    NSMutableArray* triggeredNotifications = [[NSMutableArray alloc] init];

    for (UILocalNotification* notification in notifications)
    {
        if ([notification isTriggered]) {
            [triggeredNotifications addObject:notification];
        }
    }

    return triggeredNotifications;
}

/**
 * List of all local notifications IDs.
 */
- (NSArray*) localNotificationIds
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationIds\rLINE 122\r");

    NSArray* notifications = self.localNotifications;
    NSMutableArray* ids = [[NSMutableArray alloc] init];

    for (UILocalNotification* notification in notifications)
    {
        [ids addObject:notification.options.id];
    }

    return ids;
}

/**
 * List of all local notifications IDs from given type.
 *
 * @param type
 *      Notification life cycle type
 */
- (NSArray*) localNotificationIdsByType:(APPLocalNotificationType)type
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationIdsByType\rLINE 141\r");

    NSArray* notifications = self.localNotifications;
    NSMutableArray* ids = [[NSMutableArray alloc] init];

    for (UILocalNotification* notification in notifications)
    {
        if (notification.type == type) {
            [ids addObject:notification.options.id];
        }
    }

    return ids;
}

/*
 * If local notification with ID exists.
 *
 * @param id
 *      Notification ID
 */
- (BOOL) localNotificationExist:(NSNumber*)id
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationExist\rLINE 162\r");

    return [self localNotificationWithId:id] != NULL;
}

/* If local notification with ID and type exists
 *
 * @param id
 *      Notification ID
 * @param type
 *      Notification life cycle type
 */
- (BOOL) localNotificationExist:(NSNumber*)id type:(APPLocalNotificationType)type
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationExist:type\rLINE 174\r");

    return [self localNotificationWithId:id andType:type] != NULL;
}

/**
 * Get local notification with ID.
 *
 * @param id
 *      Notification ID
 */
- (UILocalNotification*) localNotificationWithId:(NSNumber*)id
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationWithId\rLINE 185\r");

    NSArray* notifications = self.localNotifications;

    for (UILocalNotification* notification in notifications)
    {
        if ([notification.options.id isEqualToNumber:id]) {
            return notification;
        }
    }

    return NULL;
}

/*
 * Get local notification with ID and type.
 *
 * @param id
 *      Notification ID
 * @param type
 *      Notification life cycle type
 */
- (UILocalNotification*) localNotificationWithId:(NSNumber*)id andType:(APPLocalNotificationType)type
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationWithId:andType\rLINE 207\r");

    UILocalNotification* notification = [self localNotificationWithId:id];

    if (notification && notification.type == type)
        return notification;

    return NULL;
}

/**
 * List of properties from all notifications.
 */
- (NSArray*) localNotificationOptions
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationOptions\rLINE 220\r");

    NSArray* notifications = self.localNotifications;
    NSMutableArray* options = [[NSMutableArray alloc] init];

    for (UILocalNotification* notification in notifications)
    {
        [options addObject:notification.options.userInfo];
    }

    return options;
}

/**
 * List of properties from all local notifications from given type.
 *
 * @param type
 *      Notification life cycle type
 */
- (NSArray*) localNotificationOptionsByType:(APPLocalNotificationType)type
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification -  localNotificationOptionsByType\rLINE 239\r");

    NSArray* notifications = self.localNotifications;
    NSMutableArray* options = [[NSMutableArray alloc] init];

    for (UILocalNotification* notification in notifications)
    {
        if (notification.type == type) {
            [options addObject:notification.options.userInfo];
        }
    }

    return options;
}

/**
 * List of properties from given local notifications.
 *
 * @param ids
 *      Notification IDs
 */
- (NSArray*) localNotificationOptionsById:(NSArray*)ids
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationOptionsById\rLINE 260\r");

    UILocalNotification* notification;
    NSMutableArray* options = [[NSMutableArray alloc] init];

    for (NSNumber* id in ids)
    {
        notification = [self localNotificationWithId:id];

        if (notification) {
            [options addObject:notification.options.userInfo];
        }
    }

    return options;
}

/**
 * List of properties from given local notifications.
 *
 * @param type
 *      Notification life cycle type
 * @param ids
 *      Notification IDs
 */
- (NSArray*) localNotificationOptionsByType:(APPLocalNotificationType)type andId:(NSArray*)ids
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - localNotificationOptionsByType:andId\rLINE 285\r");

    UILocalNotification* notification;
    NSMutableArray* options = [[NSMutableArray alloc] init];

    for (NSNumber* id in ids)
    {
        notification = [self localNotificationWithId:id];

        if (notification && notification.type == type) {
            [options addObject:notification.options.userInfo];
        }
    }

    return options;
}

/*
 * Clear all local notfications.
 */
- (void) clearAllLocalNotifications
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - clearAllLocalNotifications\rLINE 305\r");

    NSArray* notifications = self.triggeredLocalNotifications;

    for (UILocalNotification* notification in notifications) {
        [self clearLocalNotification:notification];
    }
}

/*
 * Clear single local notfication.
 *
 * @param notification
 *      The local notification object
 */
- (void) clearLocalNotification:(UILocalNotification*)notification
{
    NSLog(@"\r\rDEBUG-LOG UIApplication+APPLocalNotification - clearLocalNotification\rLINE 320\r");

    [self cancelLocalNotification:notification];

    if ([notification isRepeating]) {
        notification.fireDate = notification.options.fireDate;

        [self scheduleLocalNotification:notification];
    };
}

@end
