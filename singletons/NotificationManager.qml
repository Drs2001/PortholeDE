pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    
    property var notifications: [] // Master notifications list
    property var visibleNotifications: [] // Currently shown notification (Should only be length 1)
    property var notificationQueue: [] // The queue of notifications to show
    
    // Function to add a notification
    function addNotification(notification) {
        var tempList = notifications.slice() // create a temp list to trigger quickshell update when reassigning
        var noti = {
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            icon: notification.appIcon,
            desktopEntry: notification.desktopEntry, // used to find the app icon when appIcon is empty
            image: notification.image,
            timestamp: Date.now()
        }
        tempList.push(noti)
        notifications = tempList
        if(visibleNotifications.length == 0){
            visibleNotifications = [noti]
        }
        else{
            notificationQueue.push(noti)
        }
    }
    
    // Function to remove a notification from master list
    function removeNotification(notifId) {
        notifications = notifications.filter(n => n.id !== notifId)
    }

    // Updates the notification that is visible on screen
    function updateVisibleNotification(){
        visibleNotifications = []

        // Check if we have more notifications in the queue
        if(notificationQueue.length > 0){
            var tempQueue = notificationQueue.slice()
            var noti = tempQueue.shift()
            notificationQueue = tempQueue
            Qt.callLater(function() {
                visibleNotifications = [noti]
            })
        }
    }
}