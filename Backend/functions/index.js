//Connect to DB
const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp(functions.config().firebase);

let db = admin.firestore();

/*
//Read data
db.collection('utenti').get()
    .then((snapshot) => {
        snapshot.forEach((doc) => {
            console.log(doc.id, '=>', doc.data());
        });
    })
    .catch((err) => {
        console.log('Error getting documents', err);
    });
*/
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

    console.log("User " + string(uid) + " aka " + string(displayName) + " joined the world");
});

exports.UnregisterUser = functions.auth.user().onDelete((user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Remove entry from DB
    let docRef = db.collection('utenti').doc(uid).delete();

    console.log("User " + string(uid) + " aka " + string(displayName) + " left the world");
});