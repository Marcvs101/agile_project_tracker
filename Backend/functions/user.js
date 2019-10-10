//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//
exports.RegisterNewUser = functions.auth.user().onCreate((user) => {
    const provider = user.providerData;
    console.log(provider);

    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Add data
    let docRef = db.collection('utenti').doc(uid);
    let seUser = docRef.set({
        'nome': displayName,
        'email': email
    });

    console.log("L'utente " + String(uid) + " aka " + String(displayName) + " si è unito al mondo");
});

//
exports.UnregisterUser = functions.auth.user().onDelete((user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Remove entry from DB
    let docRef = db.collection('utenti').doc(uid).delete();

    console.log("L'utente " + String(uid) + " aka " + String(displayName) + " ha abbandonato il mondo");
});

exports.GetUser = functions.https.onCall(async (data, context) => {
    const uid = context.auth.uid;
    const targetId = data["user"]

    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    let result = {};

    let userRef = db.collection("utenti").doc(targetId);
    return userRef.get().then(doc => {

        if (!doc.exists) {
            console.log('Utente inesistente');
            throw new functions.https.HttpsError(404, "Utente inesistente");
        } else {
            console.log('Utente trovato', doc.data());
            result["name"] = doc.get("nome");
            result["email"] = doc.get("email");//Qui saranno necessari controlli di sicurezza

            console.log("Sono state richieste informazioni su uid: ", String(targetId));
            return JSON.stringify(result);
        }

    }).catch(err => {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    });
});