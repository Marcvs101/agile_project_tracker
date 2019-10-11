//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');
const EmailLib = require('./email');
const CrepatoreLib = require('./crepatore');

let db = admin.firestore();

//Creazione utente
exports.RegisterNewUser = functions.auth.user().onCreate(async (user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Add data
    let docRef = db.collection('developers').doc(uid);
    let setUser = await docRef.set({
        'displayName': displayName,
        'email': email
    }, { merge: true });

    //EMAIL
    //if (email){EmailLib.sendEmail(email,"BN","BENVENUTO");}

    console.log("L'utente " + String(uid) + " aka " + String(displayName) + " si è unito al mondo");
    return null;
});

//Distruzione utente
exports.UnregisterUser = functions.auth.user().onDelete(async (user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    CrepatoreLib.crepaUser(uid);

    //EMAIL
    //if (email){EmailLib.sendEmail(email,"CI","CIAO")};

    console.log("L'utente " + String(uid) + " aka " + String(displayName) + " ha abbandonato il mondo");
    return null;
});

//Get utente
exports.GetUser = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const targetId = data["user"];

    let result = {};

    let userRef = db.collection("developers").doc(targetId);
    try {
        const doc = await userRef.get();
        if (!doc.exists) {
            console.log('Utente inesistente');
            throw new functions.https.HttpsError(404, "Utente inesistente");
        }
        else {
            console.log('Utente trovato', doc.data());
            result["name"] = doc.get("name");
            result["email"] = doc.get("email"); //Qui saranno necessari controlli di sicurezza
            console.log("Sono state richieste informazioni su uid: ", String(targetId));
            return JSON.stringify(result);
        }
    }
    catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Update utente
exports.UpdateUser = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {

        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const username = data["name"];

    //Add data
    let docRef = db.collection('developers').doc(uid);
    let setUser = await docRef.set({
        'name': username,
    }, { merge: true });

    console.log("L'utente " + String(uid) + " aka " + String(username) + " ha modificato il suo username");
    return null;
});