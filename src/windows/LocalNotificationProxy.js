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

    test = function(){
        console.log("test");
    };

    schedule = function (title, message, dueTime, idNumber) {
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
            toast = new Notifications.ScheduledToastNotification(toastDOM, dueTime);
            toast.id = "Toast" + idNumber;

            Notifications.ToastNotificationManager.createToastNotifier().addToSchedule(toast);
            console.log("Scheduled a toast with ID: " + toast.id, "sample", "status");
        } catch (e) {
            console.log("Error loading the xml, check for invalid characters in the input", "sample", "error");
        }

    };

    module.exports = {

    add: function (success, error, args) {
        console.log("test" + args);

        test();
        var arguments = args[0];

        var title;
        if (arguments.title) {
            title = arguments.title;
        }
        var message;
        if (arguments.message) {
            message = arguments.message;
        }
        var date;
        if (arguments.date) {
            date = arguments.date;
        }
        var id;
        if (arguments.date) {
            id = arguments.id;
        } else {
            id = "0";
        }

        var dueTimeInSeconds = 8;

        // Use a Javascript Date object to specify the time the toast should be delivered.
        var currentTime = new Date();
        var dueTime = new Date(currentTime.getTime() + dueTimeInSeconds * 1000);
        var idNumber = id;

        schedule(title, message, dueTime, idNumber);

        success();
    },

    cancel: function (success, error, args) {
        var id = args[0];
        console.log("test");
        var itemId ="Toast12345";
        var scheduled;
        var notifier;
        notifier = Notifications.ToastNotificationManager.createToastNotifier();
        scheduled = notifier.getScheduledToastNotifications();
        

        for (var i = 0, len = scheduled.length; i < len; i++) {
            if (scheduled[i].id === itemId) {
                notifier.removeFromSchedule(scheduled[i]);
                notifier.hide(scheduled[i]);
            }
        }
        console.log("canceled" + itemId);
        success();
    }

};


require("cordova/exec/proxy").add("LocalNotification", module.exports);