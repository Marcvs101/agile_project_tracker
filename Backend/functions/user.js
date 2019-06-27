//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//
exports.RegisterNewUser = functions.auth.user().onCreate((user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Add data
    let docRef = db.collection('utenti').doc(uid);
    let seUser = docRef.set({
        'nome': displayName,
        'email': email
    });

    console.log("User " + String(uid) + " aka " + String(displayName) + " joined the world");
});

//
exports.UnregisterUser = functions.auth.user().onDelete((user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Remove entry from DB
    let docRef = db.collection('utenti').doc(uid).delete();

    console.log("User " + String(uid) + " aka " + String(displayName) + " left the world");
});