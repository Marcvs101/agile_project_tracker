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

exports.GetUser = functions.https.onRequest((req, res) => {
	const JSONreq = JSON.parse(req.url.replace('/',''));
	const my_uid = JSONreq['uid'];
	const target_uid = JSONreq['uid_target'];
    //let utente = admin.database().ref("Utenti").child(uid).once("value");

	let result = {};

	let userRef = db.collection("utenti").doc(String(target_uid));
    let getUser = userRef.get().then(doc => {

        if (!doc.exists) {
            console.log('Utente inesistente');
            return res.status(404).send(JSON.stringify(result));
        } else {
            console.log('Utente trovato', doc.data());
            result["nome"] = doc.get("nome");
            result["email"] = doc.get("email");//Qui saranno necessari controlli di sicurezza
            return res.status(200).send(JSON.stringify(result));
        }
    
    }).catch(err => {
        console.log("Errore Database");
        return res.status(500).send("Errore database");
    });

	console.log("Sono state richieste informazioni su uid: ",String(uid));
});