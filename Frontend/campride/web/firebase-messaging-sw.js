importScripts('https://www.gstatic.com/firebasejs/10.5.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.5.0/firebase-messaging-compat.js');

try {
  firebase.initializeApp({
    apiKey: 'AIzaSyC-n_9Y19744UVQgzgDeL8tsiodAmnWuK8',
    authDomain: 'my-django-login-482820.firebaseapp.com',
    projectId: 'my-django-login-482820',
    storageBucket: 'my-django-login-482820.appspot.com',
    messagingSenderId: '71992765504',
    appId: '1:71992765504:web:2309614791cde3680a83a5',
  });

  const messaging = firebase.messaging();
  messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);
  });
} catch (e) {
  console.error('Firebase initialization in service worker failed:', e);
}
