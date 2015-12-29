**NOTE: This is totally outdated, but it'll work fine until Katzer releases 0.9 (where my updated changes have been merged). **

Cordova Local-Notification Plugin (NOW WITH NOTIFICATION ACTIONS!)
=================================
** Disclaimer: This was forked from <a href="https://github.com/willyboy/cordova-plugin-local-notifications">willyboy's repo</a>, which was forked from <a href="https://github.com/NorthMcCormick/cordova-plugin-local-notifications">NorthMcCormick's</a>, which of course was forked from <a href="https://github.com/katzer/cordova-plugin-local-notifications">Katzer's</a>. **

You can scroll below or visit any of the repos linked above to see general usage docs, but here I'll show you how to add interactive notifications to your iOS or Android app.

##How to make your notifications interactive

First, some background. <b>Actions</b> are little buttons the user can slide to see on a notification, and tap to have something done in the background or foreground, depending on how it's configured. On iOS you can add up to four notification actions. When notifications are shown in banner form, only two will be shown, and all four can be shown in the alert form. Of course, you can have less than four or two, or none. My implementation is such that the actions will be shown in the order you've supplied them, so that only the first two will show in banner form (by default, the behavior is a little bit different, but this was the best way I could make the order of the actions predictable). On Android, you can have up to three actions, and the banner vs. alert differences don't apply.

In iOS, notification actions are associated with a <b>category</b>. This category has those actions attached to it, and is part of the notification payload. Both actions and categories are identified by an identifier string (shocking, I know). Android does not associate actions with a category, or even with their own identifier. But to make the action behavior consistent across both platforms, <b>you will still need to use both action identifiers and a category</b> for Android notifications. This also uses less memory on Android. 

To add actions to a notification, you add them and a category when you schedule it. The actions will be an array (containing action objects) passed to the 'actions' property, and the category will be a string passed to the 'category' property. You can reuse actions, perhaps if you've defined them outside of your call to schedule a notification, and pick up particular ones from that definition in your call. However, after you've passed an action with a particular identifier, you can't modify it in later notifications. If two action objects have the same identifier, the first one passed will be used, and the next will turn into the first one in the native code. The same applies to categories. That will probably be the biggest 'gotcha' with my implementation, but I think it is perfectly reasonable behavior. So please be aware.

You can allow a user to send a text response through a notification (iOS only, would love to implement this for Android as well when it is available). All you need to do to allow for this is to add a 'behavior' property to your action object with the value 'textInput'. If it's not a reply-inline action, don't include this property, or provide any other value. Additionally, you can modify the text of the 'Send' button, by adding a 'textInputSendTitle' property, which the value of what you'd like the button to say. On Android, for these actions, I recommend handling them the way Gmail handles their 'Reply' notification action (

Each action must include six properties to work properly on both iOS and Android. There are also two, totally optional, properties to set up iOS inline reply actions. All of these properties are listed below.

<ul>
<li><b>identifier</b>: (iOS & Android) A string containing the identifier of your action (read above to learn more about how this will be used)</li>
<li><b>title</b>: (iOS & Android) A string that will be shown on the action button itself.</li>
<li><b>icon</b>: (Android) A string used to locate a resource asset to be shown on the action button itself. Don't include the file extension (but it should be .png). Whatever works for you for the smallIcon property on the notification itself will be what works here, so look into that for reference.
<li><b>activationMode</b>: (iOS) A string equal to either 'background' or 'foreground'. This property determines whether your app will be brought to the foreground (and opened, if it isn't already) when the action is tapped (for 'foreground', obviously).</li>
<li><b>destructive</b>: (iOS) A boolean. If true, the action button will be shown with a red background, to signifiy that destructive changes will be made if clicked. It doesn't actually change how anything functions.</li>
<li><b>authenticationRequired</b>: (iOS) A boolean. If true, the user will be required to enter their passcode before the action is actually performed.</li>
<li><b>behavior</b>: (iOS, optional) A string that should equal 'textInput' if you would like the reply-inline functionality described above.</li>
<li><b>textInputSendTitle</b>: (iOS, optional) A string that will appear on the 'Send' button for reply-inline actions (instead of 'Send'). This is optional if your reply specifies the 'textInput' behavior, and totally unnecessary if not. Note: You won't find this property under this name in Apple's documentation; it's set a different way internally.</li>
</ul>

###Sample

```javascript
var actions = [ {
        identifier: 'SIGN_IN',
        title: 'Yes',
        icon: 'res://ic_signin',
        activationMode: 'background',
        destructive: false,
        authenticationRequired: true
    },
    {
       identifier: 'MORE_SIGNIN_OPTIONS',
       title: 'More Options',
       icon: 'res://ic_moreoptions',
       activationMode: 'foreground',
       destructive: false,
       authenticationRequired: false
    },
    {
       identifier: 'PROVIDE_INPUT',
       title: 'Provide Input',
       icon: 'ic_input',
       activationMode: 'background',
       destructive: false,
       authenticationRequired: false,
       behavior: 'textInput',
       textInputSendTitle: 'Reply'
}];

cordova.plugins.notification.local.schedule({
        id: 1,
        title: "Production Jour fixe",
        text: "Duration 1h",
        at: monday_9_am,
        actions: [actions[0], actions[1]],
        category: 'SIGN_IN_TO_CLASS'
});
```

Of course, above, you can include all of the normal properties passed when scheduling a notification. Just add actions and category to get interactivity.

##Handling actions

When a user taps a notification action, you obviously want to do something. So, to know which action they've tapped, you just need to capture the 'action' event. This will give you the notification, state, and data. The action identifier (and optional reply-inline response info text) are in the data variable, an object with 'identifier' and (optional) 'responseInfoText' propertie(s). You should know all of the action identifiers (after all, you passed them), and use conditions to determine what you'll for for each actions.

###Sample

```javascript
cordova.plugins.notification.local.on('action', function (notification, state, data) {
    var replyMessage;

    if (data.identifier === 'PROVIDE_INPUT') {
        replyMessage = data.responseInfoText;
        alert(replyMessage);
    } else if (data.identifier === 'SIGN_IN') {
        alert('You have been signed in!');
    } else if (data.identifier === 'MORE_SIGNIN_OPTIONS') {
        alert('(Pretend there are more signin options here, please.)');
    } 
});
```

Obviously, you can do something more interesting than adding alerts.

In the case that you've shared actions amongst different notifications, but want to perform something else depending on what actual notification it was tapped from, just use the notification variable to access the payload you passed in and determine which it is. You'll need to parse this too.

##For Ionic users

If you use ngCordova, you can add this snippet to the ngCordova.plugins.localNotification module under the event listener:

```javascript
$window.cordova.plugins.notification.local.on('action', function (notification, state, data) {
  $timeout(function () {
    $rootScope.$broadcast('$cordovaLocalNotification:action', notification, state, data);
  });
});
```

Then in your app, you can capture the event like this:

```javascript
$rootScope.$on('$cordovaLocalNotification:action', function(event, notification, state, data) {
    // use conditionals to choose actions to take like above, blah blah
});
```

## GENERAL USAGE DOCS (I didn't write)

The essential purpose of local notifications is to enable an application to inform its users that it has something for them — for example, a message or an upcoming appointment — when the application isn’t running in the foreground.<br>
They are scheduled by an application and delivered on the same device.

<img width="35%" align="right" hspace="19" vspace="12" src="https://github.com/northmccormick/cordova-plugin-local-notifications/blob/example/images/android.png"></img>

### How they appear to the user
Users see notifications in the following ways:
- Displaying an alert or banner
- Badging the app’s icon
- Playing a sound


### Examples of Notification Usage
Local notifications are ideally suited for applications with time-based behaviors, such as calendar and to-do list applications. Applications that run in the background for the limited period allowed by iOS might also find local notifications useful.<br>
For example, applications that depend on servers for messages or data can poll their servers for incoming items while running in the background; if a message is ready to view or an update is ready to download, they can then present a local notification immediately to inform their users.

## 0.9 Beta (The release/release-0.9 branch)
- Includes iOS 9 Support, moving away from depricated and buggy Objective-C Code

## 8.whatever Beta (The master branch)
- Includes iOS 9 Support, moving away from depricated and buggy Objective-C Code. This is the only fix that will go into the current master branch.

## Supported Platforms
The current 0.8 branch supports the following platforms:
- __iOS__ _(including iOS8)_<br>
- __Android__ _(SDK >=7)_
- __Windows 8.1__ _(added with v0.8.2)_
- __Windows Phone 8.1__ _(added with v0.8.2)_

Find out more informations [here][wiki_platforms] in our wiki.


## Installation
The plugin is installable from source and available on Cordova Plugin Registry and PhoneGap Build.

Find out more informations [here][wiki_installation] in our wiki.


## I want to get a quick overview
All wiki pages contain samples, but for a quick overview the sample section may be the fastest way.

Find out more informations [here][wiki_samples] in our wiki.


## I want to get a deep overview
The plugin supports scheduling local notifications in various ways with a single interface. It also allows you to update, clear or cancel them. There are different interfaces to query for local notifications and a complete set of events to hook into the life cycle of local notifications.

Find out more about how to schedule single, multiple, delayed or repeating local notifications [here][wiki_schedule].<br>
Informations about events like _click_ or _trigger_ can be found [here][wiki_events].

To get a deep overview we recommend to read about all the topics in our [wiki][wiki] and try out the [Kitchen Sink App][wiki_kitchensink]


## I want to see the plugin in action
The plugin offers a kitchen sink sample app. Check out the cordova project and run the app directly from your command line or preferred IDE.

Find out more informations [here][wiki_kitchensink] in our wiki.


## What's new
We are proud to announce our newest release version 0.8.x. Beside the hard work at the office and at the weekends it contains a lot of goodies, new features and easy to use APIs.

Find out more informations [here][wiki_changelog] in our wiki.


## Sample
The sample demonstrates how to schedule a local notification which repeats every week. The listener will be called when the user has clicked on the local notification.

```javascript
cordova.plugins.notification.local.schedule({
    id: 1,
    title: "Production Jour fixe",
    text: "Duration 1h",
    firstAt: monday_9_am,
    every: "week",
    sound: "file://sounds/reminder.mp3",
    icon: "http://icons.com/?cal_id=1",
    data: { meetingId:"123#fg8" }
});

cordova.plugins.notification.local.on("click", function (notification) {
    joinMeeting(notification.data.meetingId);
});
```

Find out more informations [here][wiki_samples] in our wiki.


## I would like to propose new features
We appricate any feature proposal and support for their development. Please describe them [here][feature_proposal_issue].

Find out more informations [here][wiki_next] in our wiki.

## License

This software is released under the [Apache 2.0 License][apache2_license].

© 2013-2015 appPlant UG, Inc. All rights reserved


[cordova]: https://cordova.apache.org
[wiki]: https://github.com/katzer/cordova-plugin-local-notifications/wiki
[wiki_platforms]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/02.-Platforms
[wiki_installation]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/03.-Installation
[wiki_kitchensink]: https://github.com/katzer/cordova-plugin-local-notifications/tree/example
[wiki_schedule]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/04.-Scheduling
[wiki_events]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/09.-Events
[wiki_samples]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/11.-Samples
[wiki_changelog]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/Upgrade-Guide
[wiki_next]: https://github.com/katzer/cordova-plugin-local-notifications/wiki/Feature-Requests
[feature_proposal_issue]: https://github.com/katzer/cordova-plugin-local-notifications/issues/451
[apache2_license]: http://opensource.org/licenses/Apache-2.0
