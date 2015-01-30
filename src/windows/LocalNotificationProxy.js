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

    // Cordova exec functions--------------------------------------------------------------------------
 module.exports = {

    add: function (success, error, args) {
        for (var i = 0, len = args.length; i < len; i++) {
            var arguments = args[i];

            //get Notification-Content
            var title;
            if (arguments.title) {
                title = arguments.title;
            }
            var message;
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
            //persist notification
            persist(arguments);
            //schedule notification
            localSchedule(title, message, dueTime, idNumber,interval);
        }
        success();
    },

    cancel: function (success, error, args) {
        localCancel(args);
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
    }

};
    require("cordova/exec/proxy").add("LocalNotification", module.exports);

    // local functions----------------------------------------------------------------------

    localSchedule = function (title, message, dueTime, idNumber, repeatInterval) {
        var now = new Date();
        var interval = dueTime - now;
        // Scheduled toasts use the same toast templates as all other kinds of toasts.
        var toastXmlString = "<toast>"
            + "<visual version='2'>"
            + "<binding template='ToastText02'>"
            + "<text id='2'>" + title + "</text>"
            + "<text id='1'>" + message + "</text>"
            + "</binding>"
            + "</visual>"
            + "</toast>";

        toastXmlString = toastXmlString.replace("updateString", title);

        var toastDOM = new Windows.Data.Xml.Dom.XmlDocument();
        try {
            toastDOM.loadXml(toastXmlString);
            var toast;
            if (repeatInterval != 0 && repeatInterval < 360001 && repeatInterval > 59999 ) {
                toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime, repeatInterval, 5);
            } else {
                toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime);
            }
            toast.id = "" + idNumber;
            toast.tag = "Toast" + idNumber;


            Notifications.ToastNotificationManager.createToastNotifier().addToSchedule(toast);
            plugin.notification.local.onadd();
            console.log("Scheduled a toast with ID: " + toast.id, "sample", "status");
            WinJS.Promise.timeout(interval).then(
                function (complete) {
                    // code that executes after the timeout has completed.
                    plugin.notification.local.ontrigger();
                },
                function (error) {
                    // code that takes care of the canceled promise. 
                    // Note that .then rather than .done should be used in this case.
                    console.log("Error");
                });
        } catch (e) {
            console.log("Error loading the xml, check for invalid characters in the input", "sample", "error");
        }

    };

    localCancel = function (args) {
        for (var id in args) {
            var itemId = "" + id;
            var scheduled;
            var notifier;
            var history = Windows.UI.Notifications.ToastNotificationManager.history;
            notifier = Notifications.ToastNotificationManager.createToastNotifier();
            scheduled = notifier.getScheduledToastNotifications();


            for (var i = 0, len = scheduled.length; i < len; i++) {
                if (scheduled[i].id === itemId) {
                    notifier.removeFromSchedule(scheduled[i]);
                    console.log("canceled " + itemId);
                }
            }
            history.remove("Toast" + itemId);
            unpersist(id);
        }
    };

    localCancelAll = function () {
        var notifier = Notifications.ToastNotificationManager.createToastNotifier();
        var history = Windows.UI.Notifications.ToastNotificationManager.history;
        try{
            var scheduled = notifier.getScheduledToastNotifications();


            for (var i = 0, len = scheduled.length; i < len; i++) {
                notifier.removeFromSchedule(scheduled[i]);
                console.log("canceled " + scheduled[i].id);
            }
        } catch (e) {
            console.log("No Notification scheduled");
        }
        var persistedIds = getSavedIds();
        for (var id in persistedIds) {
            unpersist(id);
        }
        history.clear();

    };

    localClear = function (args) {
        for (var id in args) {
            Windows.UI.Notifications.ToastNotificationManager.history.remove("Toast" + id);
            unpersist(id);
        }
    };

    localClearAll = function () {
        Windows.UI.Notifications.ToastNotificationManager.history.clear();
        var persistedIds = getSavedIds();
    };



    //persist-methods---------------------------------------------------------------------------
    getFromSettings = function (id) {
        var value = localSettings.values["Toast" + id];
        if (!value) {
            return null;
        } else {
            return JSON.parse(value);
        }
    }

    persist = function (arguments) {
        localSettings.values["Toast" + arguments.id] = JSON.stringify(arguments);
        saveId(arguments.id);
    };

    unpersist = function (id) {
        localSettings.values.remove("Toast" + id);
        removeId(id);
    };

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
