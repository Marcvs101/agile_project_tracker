//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//Abbandona il progetto
exports.LeaveProject = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["ProjectID"];

    let projectRef = db.collection("projects").doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        } else {
            console.log('Progetto trovato', doc.data());
            //Qui saranno necessari controlli di sicurezza

            if (doc.get("owner") == uid) {
                //Se sei il proprietario, crepi il progetto

                let deleteDoc = await db.collection('projects').doc(projectId).delete();

                console.log("L'utente: ", uid, " ha abbandonato il progetto: ", projectId, " che è stato chiuso");
                return "L'utente: " + String(uid) + " ha abbandonato il progetto: " + String(projectId) + " che è stato chiuso";

            } else {
                //Se non sei il proprietario devo sovrascrivere i campi interessati

                let devlist = doc.get("developers");
                devlist = devlist.filter(item => item !== uid);

                let adminlist = doc.get("admins");
                adminlist = adminlist.filter(item => item !== uid);

                let docData = doc.data();
                docData["developers"] = devlist;
                docData["admins"] = adminlist;

                let setDoc = await db.collection('projects').doc(projectId).set(docData);

                console.log("L'utente: ", uid, " ha abbandonato il progetto: ", projectId);
                return "L'utente: " + String(uid) + " ha abbandonato il progetto: " + String(projectId);
            }
        }
    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Caccia qualcuno dal progetto
exports.RemoveDeveloper = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["ProjectID"];
    const targetId = data["devID"];

    let projectRef = db.collection("projects").doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        } else {
            console.log('Progetto trovato', doc.data());
            //Qui saranno necessari controlli di sicurezza

            if ((doc.get("admins").includes(uid) || doc.get("owner") == uid) && doc.get("developers").includes(targetId) && !doc.get("admins").includes(targetId)) {

                let devlist = doc.get("developers");
                devlist = devlist.filter(item => item !== targetId);

                let docData = doc.data();
                docData["developers"] = devlist;

                let setDoc = await db.collection('projects').doc(projectId).set(docData);

                console.log("L'utente: ", targetId, " è stato brutalmente cacciato dal progetto: ", projectId, " dall'utente: ", uid);
                return "L'utente: " + String(targetId) + " è stato brutalmente cacciato dal progetto: " + String(projectId) + " dall'utente: " + String(uid);
            } else if (!doc.get("developers").includes(targetId)) {
                console.log("L'utente: ", targetId, " non fa parte del progetto: ", projectId);
                return new functions.https.HttpsError(404, "L'utente: " + String(targetId) + " non fa parte del progetto: " + String(projectId));
            } else if (doc.get("admins").includes(targetId)) {
                console.log("L'utente: ", targetId, " è amministratore del progetto: ", projectId);
                return new functions.https.HttpsError(403, "L'utente: " + String(targetId) + " è amministratore del progetto: " + String(projectId));
            } else {
                console.log("L'utente: ", uid, " non dispone dei permessi necessari per cacciare: ", targetId, " dal progetto: ", projectId);
                return new functions.https.HttpsError(403, "L'utente: " + String(uid) + " non dispone dei permessi necessari per cacciare: " + String(targetId) + " dal progetto: " + String(projectId));
            }
        }
    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Aggiungi qualcuno al progetto
exports.AddDeveloper = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["project"];
    const targetDev = data["deveveloper"];
    const isAdmin = data["admin"];

    //Pesca l'utente
    let utente = null;
    let utenteRef = db.collection("developers");
    try {
        let emailQuery = utenteRef.where('email', '==', String(targetDev));
        const emailQueryResult = await emailQuery.get();
        if (!emailQueryResult.empty) {
            emailQueryResult.forEach((element) => {
                if (element.exists) {
                    utente = element.data();
                }
            });
        }

        let usernameQuery = utenteRef.where('name', '==', String(targetDev));
        const usernameQueryResult = await usernameQuery.get();
        if (!usernameQueryResult.empty) {
            usernameQueryResult.forEach((element) => {
                if (element.exists) {
                    utente = element.data();
                }
            });
        }

    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }

    if (utente == null) {
        console.log("L'utente: " + targetDev + " non è registrato");
        throw new functions.https.HttpsError(404, "L'utente: " + String(targetDev) + " non è registrato");
    }

    //Pesca il progetto
    let projectRef = db.collection("projects").doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        } else {
            console.log('Progetto trovato', doc.data());
            //Qui saranno necessari controlli di sicurezza

            if ((doc.get("admins").includes(uid) || doc.get("owner") == uid) && !doc.get("developers").includes(targetId)) {

                let devlist = doc.get("developers");
                devlist.push(utente);

                let adminlist = doc.get("admins");
                if (isAdmin) { adminlist.push(utente); }

                let docData = doc.data();
                docData["developers"] = devlist;
                docData["admins"] = adminlist

                let setDoc = await db.collection('projects').doc(projectId).set(docData);

                console.log("L'utente: ", targetId, " è stato aggiunto al progetto: ", projectId, " dall'utente: ", uid);
                return "L'utente: " + String(targetId) + " è stato aggiunto al progetto: " + String(projectId) + " dall'utente: " + String(uid);
            } else if (!doc.get("sviluppatori").includes(targetId)) {
                console.log("L'utente: ", targetId, " fa già parte del progetto: ", projectId);
                return new functions.https.HttpsError(422, "L'utente: " + String(targetId) + " fa già parte del progetto: " + String(projectId));
            } else {
                console.log("L'utente: ", uid, " non dispone dei permessi necessari per cacciare: ", targetId, " dal progetto: ", projectId);
                return "L'utente: " + String(uid) + " non dispone dei permessi necessari per cacciare: " + String(targetId) + " dal progetto: " + String(projectId);
            }
        }
    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});