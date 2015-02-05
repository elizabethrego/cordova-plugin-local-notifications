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

    document.addEventListener('deviceready', function () {
        console.log("test");
        //fireEvents 
        var idsToTrigger = getIdsForOntrigger();
        for (var i = 0, len = idsToTrigger.length; i < len; i++) {
            plugin.notification.local.ontrigger();
            saveId(idsToTrigger[i]);
        }
    });

    // Cordova exec functions--------------------------------------------------------------------------
    module.exports = {

    add: function (success, error, args) {
        for (var i = 0, len = args.length; i < len; i++) {
            var arguments = args[i];

            //get Notification-Content
            var title = "Notification";
            if (arguments.title) {
                title = arguments.title;
            }
            var message = "";
            if (arguments.message) {
                message = arguments.message;
            }
            var dueTime = new Date();
            if (arguments.date) {
                dueTime = new Date((arguments.date) * 1000 + 500);
            }
            var idNumber;
            if (arguments.id) {
                idNumber = arguments.id;
            } else {
                idNumber = "0";
            }
            arguments.id = idNumber;
            var repeat;
            var interval = 0;
            if (arguments.repeat) {
                repeat = arguments.repeat;
                if (repeat === 'minutely') {
                    interval = 60000;
                } else if (repeat === 'hourly') {
                    interval = 360000;
                } else {
                    interval = parseInt(repeat) * 60000;
                }
            }
            //Cancel old notification if it's already existing
            localCancel([idNumber], false);
            //schedule notification
            localSchedule(title, message, dueTime, idNumber,interval,arguments);
        }
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

    clear: function(success, error, args){
        localClear(args);
        success();
    },

    clearAll: function (success, error, args) {
        localClearAll();
        success();
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

    isPersisted: function (success, error, args) {
        var id = args[0];
        var isPersisted = localIsPersisted(id);
        success(isPersisted);
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
    }

};
    require("cordova/exec/proxy").add("LocalNotification", module.exports);

    // local functions----------------------------------------------------------------------

    localSchedule = function (title, message, dueTime, idNumber, repeatInterval,jsonObject) {
        var now = new Date();
        var interval = dueTime - now; 
        // Scheduled toasts use the same toast templates as all other kinds of toasts.
        var toastXmlString = "<toast>"
            + "<visual version='2'>"
            + "<binding template='ToastText02'>"
            + "<text id='2'>" + message + "</text>"
            + "<text id='1'>" + title + "</text>"
            + "</binding>"
            + "</visual>"
            + "<json>" + JSON.stringify(jsonObject)  +"</json>"
            + "</toast>";

//        toastXmlString = toastXmlString.replace("updateString", title);

        var toastDOM = new Windows.Data.Xml.Dom.XmlDocument();
        try {
            toastDOM.loadXml(toastXmlString);

            //original Notification
            var toast;
            if (repeatInterval != 0 && repeatInterval < 360001 && repeatInterval > 59999 ) {
                toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime, repeatInterval, 5);
            } else {
                toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime);
            }
            toast.id = "" + idNumber;
            toast.tag = "Toast" + idNumber;

            Notifications.ToastNotificationManager.createToastNotifier().addToSchedule(toast);

            //backup Notification
            var backup;
            var ten_years_later = new Date(dueTime.getTime() + 315360000000);
            if (repeatInterval != 0 && repeatInterval < 360001 && repeatInterval > 59999) {
                backup = new Notifications.ScheduledToastNotification(toastDOM, ten_years_later, repeatInterval, 5);
            } else {
                backup = new Notifications.ScheduledToastNotification(toastDOM, ten_years_later);
            }
            backup.id = "" + idNumber+ "-2";
            backup.tag = "Toast" + idNumber;

            Notifications.ToastNotificationManager.createToastNotifier().addToSchedule(backup);

            //Add-Event
            plugin.notification.local.onadd();
            console.log("Scheduled a toast with ID: " + toast.id);

            //Trigger-Event
            WinJS.Promise.timeout(interval).then(
                function (complete) {
                    if (localIsPersisted(idNumber)) {
                        //save ID to know, that onTrigger event is already fired
                        saveId(idNumber);
                        //fire ontrigger-Event
                        plugin.notification.local.ontrigger();
                    }
                },
                function (error) {
                    console.log("Error");
                });
        } catch (e) {
            console.log("Error loading the xml, check for invalid characters in the input", "sample", "error");
        }

    };

    localCancel = function (args,fireEvent) {
        for (var i = 0, len = args.length; i < len; i++) {
            var id = args[i];
            removeId(id);
            var itemId = "" + id;
            var scheduled;
            var notifier;
            var history = Windows.UI.Notifications.ToastNotificationManager.history;
            notifier = Notifications.ToastNotificationManager.createToastNotifier();
            scheduled = notifier.getScheduledToastNotifications();


            for (var i = 0, len = scheduled.length; i < len; i++) {
                if (scheduled[i].id === itemId) {
                    notifier.removeFromSchedule(scheduled[i]);
                    if (fireEvent) {
                        plugin.notification.local.oncancel();
                    }
                }
                if (scheduled[i].id === itemId+"-2") {
                    notifier.removeFromSchedule(scheduled[i]);
                }
            }
            if (fireEvent) {
                history.remove("Toast" + itemId);
            }
        }
    };

    localCancelAll = function () {
        var history = Windows.UI.Notifications.ToastNotificationManager.history;
        var allIds = localGetAllIds();
        localCancel(allIds,true);
        history.clear();
    };

    localClear = function (args) {
        for (var i = 0, len = args.length; i < len; i++) {
            var id = args[i];
            plugin.notification.local.onclear();
            Windows.UI.Notifications.ToastNotificationManager.history.remove("Toast" + id);
            if (localIsTriggered(id)) {
                localCancel([id],false);
            }
        }
    };

    localClearAll = function () {
        var triggeredIds = localGetTriggeredIds();
        localClear(triggeredIds);
        Windows.UI.Notifications.ToastNotificationManager.history.clear();
    };

    //get-functions
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

            for (var i = 0, len = scheduled.length; i < len; i++) {
                if (scheduled[i].id === itemId + "-2") {
                    result.push(JSON.parse(scheduled[i].content.lastChild.lastChild.innerText));
                }
            }

        }
        return result;
    };

    localGetScheduled = function () {
        var ids = localGetScheduledIds();
        var result = localGetAll(ids);
        return result;
    };

    localGetTriggered = function () {
        var ids = localGetTriggeredIds();
        var result = localGetAll(ids);
        return result;
    };

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

    localGetTriggeredIds = function () {
        var all = localGetAllIds();
        var scheduled = localGetScheduledIds();
        var result = new Array();
        for (var i = 0, lenA = all.length; i < lenA; i++) {
            var isScheduled = false;
            for (var j = 0, lenS = scheduled.length; j < lenS; j++) {
                if (all[i] === scheduled[j]) {
                    isScheduled = true;
                }
            }
            if (!isScheduled){
                result.push(all[i]);
            }
        }
        return result;
    };

    localIsPersisted = function (id) {
        var all = localGetAllIds();
        for (var i = 0, len = all.length; i < len; i++) {
            if (all[i] === id) {
                return true;
            }
        }
        return false;
    };

    localIsScheduled = function (id) {
        var scheduled = localGetScheduledIds();
        for (var i = 0, len = scheduled.length; i < len; i++) {
            if (scheduled[i] === id) {
                return true;
            }
        }
        return false;
    };

    localIsTriggered = function (id){
        var triggered = localGetTriggeredIds();
        for (var i = 0, len = triggered.length; i < len; i++) {
            if (triggered[i] === id) {
                return true;
            }
        }
        return false;
    };


    // Methods to save Ids of allready triggered notifications
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

    // Method to get all triggered Ids, that didn´t allready fired their ontrigger Event
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