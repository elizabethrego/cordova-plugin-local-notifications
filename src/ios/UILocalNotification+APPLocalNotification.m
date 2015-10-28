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

#import "UILocalNotification+APPLocalNotification.h"
#import "APPLocalNotificationOptions.h"
#import <objc/runtime.h>

static char optionsKey;

NSInteger const APPLocalNotificationTypeScheduled = 1;
NSInteger const APPLocalNotificationTypeTriggered = 2;

@implementation UILocalNotification (APPLocalNotification)

#pragma mark -
#pragma mark Init

/**
 * Initialize a local notification with the given options when calling on JS side:
 * notification.local.add(options)
 */
- (id) initWithOptions:(NSDictionary*)dict
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - initWithOptions\rLINE 42\r");

    self = [super init];

    [self setUserInfo:dict];
    [self __init];

    return self;
}

/**
 * Applies the given options when calling on JS side:
 * notification.local.add(options)

 */
- (void) __init
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - __init\rLINE 57\r");

    APPLocalNotificationOptions* options = self.options;

    self.fireDate = options.fireDate;
    self.timeZone = [NSTimeZone defaultTimeZone];
    self.applicationIconBadgeNumber = options.badgeNumber;
    self.repeatInterval = options.repeatInterval;
    self.alertBody = options.alertBody;
    self.soundName = options.soundName;
    self.category = options.category;

    if ([self wasInThePast]) {
        self.fireDate = [NSDate date];
    }
}

#pragma mark -
#pragma mark Methods

/**
 * The options provided by the plug-in.
 */
- (APPLocalNotificationOptions*) options
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - options\rLINE 79\r");

    APPLocalNotificationOptions* options = [self getOptions];

    if (!options) {
        options = [[APPLocalNotificationOptions alloc]
                   initWithDict:[self userInfo]];

        [self setOptions:options];
    } 

    return options;
}

/**
 * Get associated option object
 */
- (APPLocalNotificationOptions*) getOptions
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - getOptions\rLINE 96\r");

    return objc_getAssociatedObject(self, &optionsKey);
}

/**
 * Set associated option object
 */
- (void) setOptions:(APPLocalNotificationOptions*)options
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - setOptions\rLINE 104\r");

    objc_setAssociatedObject(self, &optionsKey,
                             options, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 * The repeating interval in seconds.
 */
- (int) repeatIntervalInSeconds
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - repeatIntervalInSeconds\rLINE 113\r");

    switch (self.repeatInterval) {
        case NSCalendarUnitMinute:
            return 60;

        case NSCalendarUnitHour:
            return 60000;

        case NSCalendarUnitDay:
        case NSCalendarUnitWeekOfYear:
        case NSCalendarUnitMonth:
        case NSCalendarUnitYear:
            return 86400;

        default:
            return 1;
    }
}

/**
 * Timeinterval since fire date.
 */
- (double) timeIntervalSinceFireDate
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - timeIntervalSinceFireDate\rLINE 136\r");

    NSDate* now      = [NSDate date];
    NSDate* fireDate = self.fireDate;

    int timespan = [now timeIntervalSinceDate:fireDate];

    return timespan;
}

/**
 * Timeinterval since last trigger date.
 */
- (double) timeIntervalSinceLastTrigger
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - timeIntervalSinceLastTrigger\rLINE 149\r");

    int timespan = [self timeIntervalSinceFireDate];

    if ([self isRepeating]) {
        timespan = timespan % [self repeatIntervalInSeconds];
    }

    return timespan;
}

/**
 * Encode the user info dict to JSON.
 */
- (NSString*) encodeToJSON
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - encodeToJSON\rLINE 163\r");

    NSString* json;
    NSData* data;
    NSMutableDictionary* obj = [self.userInfo mutableCopy];

    [obj removeObjectForKey:@"updatedAt"];

    data = [NSJSONSerialization dataWithJSONObject:obj
                                           options:NSJSONWritingPrettyPrinted
                                             error:Nil];

    json = [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];

    return [json stringByReplacingOccurrencesOfString:@"\n"
                                           withString:@""];
}

#pragma mark -
#pragma mark State

/**
 * If the fire date was in the past.
 */
- (BOOL) wasInThePast
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - wasInThePast\rLINE 188\r");

    return [self timeIntervalSinceLastTrigger] > 0;
}

// If the notification was already scheduled
- (BOOL) isScheduled
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - isScheduled\rLINE 194\r");

    return [self isRepeating] || ![self wasInThePast];
}

/**
 * If the notification was already triggered.
 */
- (BOOL) isTriggered
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - isTriggered\rLINE 202\r");

    NSDate* now      = [NSDate date];
    NSDate* fireDate = self.fireDate;

    bool isLaterThanFireDate = !([now compare:fireDate] == NSOrderedAscending);

    return isLaterThanFireDate;
}

/**
 * If the notification was updated.
 */
- (BOOL) wasUpdated
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - wasUpdated\rLINE 215\r");

    NSDate* now       = [NSDate date];
    NSDate* updatedAt = [self.userInfo objectForKey:@"updatedAt"];

    if (updatedAt == NULL)
        return NO;

    int timespan = [now timeIntervalSinceDate:updatedAt];

    return timespan < 1;
}

/**
 * If it's a repeating notification.
 */
- (BOOL) isRepeating
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - isRepeating\rLINE 231\r");

    return [self.options isRepeating];
}

/**
 * Process state type of the local notification.
 */
- (APPLocalNotificationType) type
{
    NSLog(@"\r\rDEBUG-LOG UILocalNotification+APPLocalNotification - type\rLINE 239\r");

    return [self isTriggered] ? NotifcationTypeTriggered : NotifcationTypeScheduled;
}

@end
