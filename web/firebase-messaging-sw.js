importScripts("https://www.gstatic.com/firebasejs/7.5.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/7.5.0/firebase-messaging.js");
firebase.initializeApp({
    databaseURL: 'https://flutterproject-22248.firebaseio.com',
    apiKey: "AIzaSyAGQphhEYLJdKWEIMMpReE512er0MLBU_8",
    authDomain: "flutterproject-22248.firebaseapp.com",
    projectId: "flutterproject-22248",
    storageBucket: "flutterproject-22248.appspot.com",
    messagingSenderId: "404775449223",
    appId: "1:404775449223:web:e73ba3951713fe8e87be22",
    measurementId: "G-46872GSTY7"
});
const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            return registration.showNotification("New Message");
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});