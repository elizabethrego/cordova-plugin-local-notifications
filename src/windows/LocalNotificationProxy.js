/*
    Copyright 2013-2014 appPlant UG

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
*/


    var Notifications = Windows.UI.Notifications;
    var applicationData = Windows.Storage.ApplicationData.current;
    var localSettings = applicationData.localSettings;

    //Fire remaining and initialize pending Trigger Events
    document.addEventListener('deviceready', function () {
        //fireEvents on appstart
        var idsToTrigger = getIdsForOntrigger();
        //allready triggered notifications
        for (var i = 0, len = idsToTrigger.length; i < len; i++) {
            setOnTrigger(idsToTrigger[i]);
        }
        //scheduled notifications
        var scheduled = localGetScheduledIds();
        for (var i = 0, len = scheduled.length; i < len; i++) {
            if (isInFuture(scheduled[i])) {
                setOnTrigger(scheduled[i]);
            }
        }
    });



    // Cordova exec functions--------------------------------------------------------------------------
module.exports = {

    deviceready: function (success, error, args) {
        WinJS.Application.addEventListener("activated", onActivatedHandler, false);
    },

    schedule: function (success, error, args) {
        localSchedule(args,'schedule');
        success();
    },

    update: function (success, error, args) {
        localUpdate(args);
        success();
    },

    clear: function (success, error, args) {
        localClear(args,true);
        success();
    },

    clearAll: function (success, error, args) {
        localClearAll();
        success();
    },

    cancel: function (success, error, args) {
        localCancel(args,true);
        success();
    },

    cancelAll: function (success, error, args) {
        localCancelAll(args);
        success();
    },

    isPresent: function (success, error, args) {
        var id = args[0];
        var isPresent = localIsPresent(id);
        success(isPresent);
    },

    isScheduled: function (success, error, args) {
        var id = args[0];
        var isScheduled = localIsScheduled(id);
        success(isScheduled);
    },

    isTriggered: function (success, error, args) {
        var id = args[0];
        var isTriggered = localIsTriggered(id);
        success(isTriggered);
    },

    getAllIds: function (success, error, args) {
        var allIds = localGetAllIds();
        success(allIds);
    },

    getScheduledIds: function (success, error, args) {
        var scheduledIds = localGetScheduledIds();
        success(scheduledIds);
    },

    getTriggeredIds: function (success, error, args) {
        var triggeredIds = localGetTriggeredIds();
        success(triggeredIds);
    },

    getAll: function (success, error, args) {
        var all = localGetAll(args);
        success(all);
    },

    getScheduled: function (success, error, args) {
        var scheduled = localGetScheduled();
        success(scheduled);
    },

    getTriggered: function (success, error, args) {
        var triggered = localGetTriggered();
        success(triggered);
    }

};
require("cordova/exec/proxy").add("LocalNotification", module.exports);

// local functions--------------------------------------------------------------------------

    /** Method to schedule new notification
     *
     * @param {Array} args JSON-Array with notifications-arguments
     * @param {String} event Fireevent-Name ('schedule' or 'update')
     */
    localSchedule = function (args,event) {
        for (var i = 0, len = args.length; i < len; i++) {
            var arguments = args[i];
        //get Notification-Content
            var title = "Notification";
            if (arguments.title) {
                title = arguments.title;
            }
            var message = "";
            if (arguments.text) {
                message = arguments.text;
            }
            var dueTime = new Date();
            if (arguments.at) {
                dueTime = new Date((arguments.at * 1000) + 1000);
            } else {
                arguments.at = dueTime;
            }
            var idNumber;
            if (arguments.id) {
                idNumber = arguments.id;
            } else {
                idNumber = "0";
            }
            arguments.id = idNumber;
            var repeat;
            var repeatInterval = 0;
            if (arguments.every) {
                repeat = arguments.every;
                if (repeat === 'minute') {
                    repeatInterval = 60000;
                } else if (repeat === 'hour') {
                    repeatInterval = 360000;
                } else {
                    repeatInterval = parseInt(repeat) * 60000;
                }
            }
            var sound = "";
            if (arguments.sound) {
                sound = parseSound(arguments.sound);
            }
        //Cancel old notification if it's already existing
            localCancel([idNumber], false);
            var now = new Date();
            var interval = dueTime - now;
        // Scheduled toast
            var toastXmlString = "<toast> "
                + "<visual version='2'>"
                + "<binding template='ToastText02'>"
                + "<text id='2'>" + message + "</text>"
                + "<text id='1'>" + title + "</text>"
                + "</binding>"
                + "</visual>"
                + sound
                + "<json>" + JSON.stringify(arguments) + "</json>"
                + "</toast>";

            var toastDOM = new Windows.Data.Xml.Dom.XmlDocument();
            try {
                toastDOM.loadXml(toastXmlString);

            //Add launch Attribute to enable onClick event
                var launchAttribute = toastDOM.createAttribute("launch");
                launchAttribute.value = "" +idNumber;
                var toastNode = toastDOM.selectSingleNode("/toast");
                toastNode.attributes.setNamedItem(launchAttribute);

            //Initialization of original Notification
                var toast;
                if (repeatInterval != 0 && repeatInterval < 360001 && repeatInterval > 59999) {
                    toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime, repeatInterval, 5);
                } else {
                    toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime);
                }
                toast.id = "" + idNumber;
                toast.tag = "Toast" + idNumber;


                Notifications.ToastNotificationManager.createToastNotifier().addToSchedule(toast);

            //Initialization of backup Notification (10 years later)
                var backup;
                var ten_years_later = new Date(dueTime.getTime() + 315360000000);
                if (repeatInterval != 0 && repeatInterval < 360001 && repeatInterval > 59999) {
                    backup = new Notifications.ScheduledToastNotification(toastDOM, ten_years_later, repeatInterval, 5);
                } else {
                    backup = new Notifications.ScheduledToastNotification(toastDOM, ten_years_later);
                }
                backup.id = "" + idNumber + "-2";
                backup.tag = "Toast" + idNumber;

                Notifications.ToastNotificationManager.createToastNotifier().addToSchedule(backup);

            //Fire schedule/update Event
                cordova.plugins.notification.local.fireEvent(event, arguments);
                // Initialize Trigger-Event
                if (event === 'schedule') {
                    setOnTrigger(idNumber);
                } else {
                    //add id to allready triggered ids to prevent onTrigger
                    saveId(idNumber);
                }
            } catch (e) {
                console.log("Error loading the xml, check for invalid characters in the input", "sample", "error");
            }
        }
    };

    localUpdate = function (args) {
        for (var i = 0, len = args.length; i < len; i++) {
            var arguments = args[i];
            //get Notification-Content
            var idNumber;
            if (arguments.id) {
                idNumber = arguments.id;
            } else {
                idNumber = "0";
            }

            //get old notification
            var oldArguments = localGetAll([idNumber])[0];

            //modify args
            if (arguments.title) {
                oldArguments.title = arguments.title;
            }
            if (arguments.text) {
                oldArguments.text = arguments.text;
            }
            if (arguments.at) {
                oldArguments.at = arguments.at;
            } else {
                var now = new Date();
                oldArguments.at = (now / 1000);
            }
            if (arguments.every) {
                oldArguments.every = arguments.every;
            }
            if (arguments.sound) {
                oldArguments.sound = arguments.sound;
            }
            if (arguments.json) {
                oldArguments.json = arguments.json;
            }

            localSchedule([oldArguments], 'update');
        }

    }

    /** Method to cancel existing notification
     *
     * @param {Array} args JSON-Array with ids to cancel
     * @param {Boolean} fireEvent Boolen (fire cancel-Event(true) or not(false) 
     */
    localCancel = function (args, fireEvent) {
        for (var i = 0, len = args.length; i < len; i++) {
            var id = args[i];
            removeId(id);
            var itemId = "" + id;
            var scheduled;
            var notifier;
            var history = Windows.UI.Notifications.ToastNotificationManager.history;
            notifier = Notifications.ToastNotificationManager.createToastNotifier();
            scheduled = notifier.getScheduledToastNotifications();


            for (var j = 0, len = scheduled.length; j < len; j++) {
                if (scheduled[j].id === itemId) {
                    var notification = localGetAll([id])[0];
                    //cancel notification
                    notifier.removeFromSchedule(scheduled[j]);
                    //fire oncancel
                    if (fireEvent) {
                       cordova.plugins.notification.local.fireEvent('cancel', notification);
                    }
                }
                if (scheduled[j].id === itemId+"-2") {
                    notifier.removeFromSchedule(scheduled[j]);
                }
            }
            //remove from Notificationcenter
            if (fireEvent) {
                history.remove("Toast" + itemId);
            }
        }
    };

    /**
     * Cancel all notifications
     */
    localCancelAll = function () {
        var history = Windows.UI.Notifications.ToastNotificationManager.history;
        var allIds = localGetAllIds();
        localCancel(allIds, false);
        //Fire cancelall-Event
        cordova.plugins.notification.local.fireEvent('cancelall', null);
        //remove notifications from notificationcenter
        history.clear();
    };

    /** Method to clear existing notification
     *
     * @param {Array} args JSON-Array with ids to cancel
     * @param {Boolean} fireEvent Boolen (fire cancel-Event(true) or not(false)
     */
    localClear = function (args, fireEvent) {
        for (var i = 0, len = args.length; i < len; i++) {
            var id = args[i];
            var notification =  localGetAll([id])[0];
            Windows.UI.Notifications.ToastNotificationManager.history.remove("Toast" + id);
            if (localIsTriggered(id) && !localIsScheduled(id)) {
                localCancel([id], false);
            }
            //fire onclear
            if (fireEvent) {
                cordova.plugins.notification.local.fireEvent('clear',notification);
            }
        }
    };

    /**
     * Clear all triggered Notifications without canceling scheduled
     */
    localClearAll = function () {
        var triggeredIds = localGetTriggeredIds();
        localClear(triggeredIds, false);
        Windows.UI.Notifications.ToastNotificationManager.history.clear();
        cordova.plugins.notification.local.fireEvent('clearall', null);

    };

//get-functions -------------------------------------------------------------------------------

    /** Method to get all or specific notification-JSONObjects.
     *
     * @param {Array} args JSONArray with ids of requested Notifications (in case of specific ids)
     *
     * @return {Array} requested Notifications
     */
    localGetAll = function (args) {
        var notifier = Notifications.ToastNotificationManager.createToastNotifier();
        var scheduled = notifier.getScheduledToastNotifications();
        var itemId;
        var result = new Array();
        
        //get All
        if (args.length == 0) {
            for (var i = 0, len = scheduled.length; i < len; i++) {
                if (scheduled[i].id.lastIndexOf("-2") == (scheduled[i].id.length - 2)) {
                    result.push(JSON.parse(scheduled[i].content.lastChild.lastChild.innerText));
                }
            }
        }

        //get Specific
        for (var i = 0, len = args.length; i < len; i++) {
            var id = args[i];
            itemId = "" + id;

            for (var j = 0, len = scheduled.length; j < len; j++) {
                if (scheduled[j].id === itemId + "-2") {
                    result.push(JSON.parse(scheduled[j].content.lastChild.lastChild.innerText));
                }
            }

        }
        return result;
    };

    /** Method to get scheduled notification-JSONObjects.
     *
     * @return {Array} requested Notifications
     */
    localGetScheduled = function () {
        var ids = localGetScheduledIds();
        if (ids.length == 0) {
            return [];
        } else {
            return localGetAll(ids);
        }
    };

    /** Method to get triggered notification-JSONObjects.
     *
     * @return {Array} requested Notifications
     */
    localGetTriggered = function () {
        var ids = localGetTriggeredIds();
        if (ids.length ==0) {
            return ids;
        } else {
            return localGetAll(ids);
        }
    };

    /** Method to get all ids.
     *
     * @return {Array} requested ids
     */
    localGetAllIds = function () {
        var notifier = Notifications.ToastNotificationManager.createToastNotifier();
        var scheduled = notifier.getScheduledToastNotifications();
        var result = new Array();

        //get All
        for (var i = 0, len = scheduled.length; i < len; i++) {
            if (scheduled[i].id.lastIndexOf("-2") == (scheduled[i].id.length - 2)) {
                result.push(scheduled[i].id.slice(0, (scheduled[i].id.length - 2)));
            }
        }
        return result;
    };

    /** Method to get scheduled ids.
     *
     * @return {Array} requested ids
     */
    localGetScheduledIds = function () {
        var notifier = Notifications.ToastNotificationManager.createToastNotifier();
        var scheduled = notifier.getScheduledToastNotifications();
        var result = new Array();

        for (var i = 0, len = scheduled.length; i < len; i++) {
            if (!(scheduled[i].id.lastIndexOf("-2") == (scheduled[i].id.length - 2))) {
                result.push(scheduled[i].id);
            }
        }
        return result;
    };


    /** Method to get triggered ids.
     *
     * @return {Array} requested ids
     */
    localGetTriggeredIds = function () {
        var all = localGetAllIds();
        var scheduled = localGetScheduledIds();
        var result = new Array();
        for (var i = 0, lenA = all.length; i < lenA; i++) {
            var isScheduled = false;
            for (var j = 0, lenS = scheduled.length; j < lenS; j++) {
                if (all[i] === scheduled[j]) {
                    //Check dueTime to filter triggered repaeting notifications
                    if (isInFuture(all[i])) {
                        isScheduled = true;
                    } 
                }
            }
            if (!isScheduled){
                result.push(all[i]);
            }
        }
        return result;
    };

    /** Check whether a specific notification exist
     *
     * @param {String} id id of the requested notification
     *
     * @return {Boolean} true if it exist
     */
    localIsPresent = function (id) {
        var all = localGetAllIds();
        for (var i = 0, len = all.length; i < len; i++) {
            if (all[i] === id) {
                return true;
            }
        }
        return false;
    };

    /** Check whether a specific notification is scheduled
     *
     * @param {String} id id of the requested notification
     *
     * @return {Boolean} true if it is scheduled
     */
    localIsScheduled = function (id) {
        var scheduled = localGetScheduledIds();
        for (var i = 0, len = scheduled.length; i < len; i++) {
            if (scheduled[i] === id) {
                return true;
            }
        }
        return false;
    };

    /** Check whether a specific notification has triggered
     *
     * @param {String} id id of the requested notification
     *
     * @return {Boolean} true if it has triggered
     */
    localIsTriggered = function (id){
        var triggered = localGetTriggeredIds();
        for (var i = 0, len = triggered.length; i < len; i++) {
            if (triggered[i] === id) {
                return true;
            }
        }
        return false;
    };

    
    /** Method to parse sound file
     *
     * @param {String} path relative path to sound resource
     * @param {String} packageName App-Package-Name to access resource-Files
     *
     * @return {String} URI to Sound-File
     */
    parseSound = function (path) {
        var package = Windows.ApplicationModel.Package.current;
        var packageId = package.id;
        var packageName = packageId.name;
        if (path.charAt(0) == 'f' && path.charAt(1) == 'i' && path.charAt(2) == 'l' && path.charAt(3) == 'e') {
            var sound = "'ms-appx://" + packageName + "/www/" + path.slice(6, path.length) + "'";
            var result = "<audio src=" + sound + " loop='false'/>"
            return result; 
        }
    };

    /** Save Id of allready triggered (trigger-Event) notifications
     *
     * @param {String} id of triggered notification
     */
    saveId = function (id) {
        var temp = localSettings.values["persistedIds"];
        var ids;
        if (!temp) {
            ids = new Array();
        } else {
            ids = JSON.parse(temp);
        }
        ids.push(id);
        localSettings.values["persistedIds"] = JSON.stringify(ids);
    };

    /** Remove Ids of allready triggered (trigger-Event) notifications
     *
     * @param {String} id of triggered notification
     */
    removeId = function (id) {
        var temp = localSettings.values["persistedIds"];
        var ids;
        if (!temp) {
            return;
        } else {
            ids = JSON.parse(temp);
        }
        for (var i = 0; i < ids.length ; i++) {
            if (ids[i] === id) {
                ids.splice(i, 1);
                break;
            }
        }
        localSettings.values["persistedIds"] = JSON.stringify(ids);
    };

    /** Get allready triggered (trigger-Event) ids
     *
     * @return {Array} allready triggered ids
     */
    getSavedIds = function () {
        var temp = localSettings.values["persistedIds"];
        var ids;
        if (!temp) {
            ids = new Array();
        } else {
            ids = JSON.parse(temp);
        }
        return ids;
    };

    /** Method to get all triggered Ids, that didn´t allready fired their ontrigger Event
     *
     * @return {Array} ids to fire on(trigger)
     */
    getIdsForOntrigger = function () {
        var triggered = localGetTriggeredIds();
        var withEvent = getSavedIds();
        var result = new Array();
        for (var i = 0, lenT = triggered.length; i < lenT; i++) {
            var hadEvent = false;
            for (var j = 0, lenE = withEvent.length; j < lenE; j++) {
                if (triggered[i] === withEvent[j]) {
                    hadEvent = true;
                }
            }
            if (!hadEvent) {
                result.push(triggered[i]);
            }
        }
        return result;
    };

    /** set ontrigger Event
     *
     * @param {String} id Id to fire on(trigger)
     */
    setOnTrigger = function(id) {
        var arguments = localGetAll([id])[0];
        var dueTime = new Date();
        if (arguments.at) {
            dueTime = new Date((arguments.at) * 1000 + 1000);
        }
        var now = new Date();
        var interval = dueTime - now;

        if (interval > 0) {
            WinJS.Promise.timeout(interval).then(
                function (complete) {
                    if (localIsPresent(id)) {
                        //save ID to know, that onTrigger event is already fired
                        saveId(id);
                        //fire ontrigger-Event
                        cordova.plugins.notification.local.fireEvent('trigger', arguments);
                    }
                },
                function (error) {
                    console.log("Error");
                });
        } else {
            //save ID to know, that onTrigger event is already fired
            saveId(id);
            //fire ontrigger-Event
            cordova.plugins.notification.local.fireEvent('trigger',arguments);
        }
    };

    /** Check whether a notifications schedule-date is in Future
     *
     * @param {String} id id of notification
     *
     * @return {Boolean} True if date is in Future
     */
    isInFuture = function (id) {
        var arguments = localGetAll([id])[0];
        var dueTime = new Date((arguments.at) * 1000 + 1000);
        var now = new Date();
        if (now < dueTime) {
            return true;
        } else {
            return false;
        };
    };

    /** Handle Toast Activation
     * @param args Information about activated Toast
     */
    function onActivatedHandler(args) {
        if (localIsPresent(args.detail.arguments)) {
            var id = args.detail.arguments;
            var JSON = localGetAll([id]);
            localClear([id], true);

            cordova.plugins.notification.local.fireEvent('click', JSON[0]);
        }

    };