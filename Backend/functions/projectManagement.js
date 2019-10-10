//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//Abbandona il progetto
exports.LeaveProject = functions.https.onCall(async (data, context) => {
    const uid = context.auth.uid;
    const projectId = data["ProjectID"];

    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    let projectRef = db.collection("progetti").doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        }
        else {
            console.log('Progetto trovato', doc.data());
            //Qui saranno necessari controlli di sicurezza

            if (doc.get("proprietario") == uid) {
                //Se sei il proprietario, crepi il progetto

                let deleteDoc = await db.collection('progetti').doc(projectId).delete();

                console.log("L'utente: ", uid, " ha abbandonato il progetto: ", projectId, " che è stato chiuso");
                return "L'utente: " + String(uid) + " ha abbandonato il progetto: " + String(projectId) + " che è stato chiuso";

            } else {
                //Se non sei il proprietario devo sovrascrivere i campi interessati

                let devlist = [];
                doc.get("sviluppatori").forEach(element => {
                    if (element == uid) {
                        //skip
                    } else {
                        devlist.push(element);
                    }
                });

                let adminlist = [];
                doc.get("amministratori").forEach(element => {
                    if (element == uid) {
                        //skip
                    } else {
                        adminlist.push(element);
                    }
                });

                let docData = doc.data();
                docData["sviluppatori"] = devlist;
                docData["amministratori"] = adminlist;

                let setDoc = await db.collection('progetti').doc(projectId).set(docData);

                console.log("L'utente: ", uid, " ha abbandonato il progetto: ", projectId);
                return "L'utente: " + String(uid) + " ha abbandonato il progetto: " + String(projectId);
            }
        }
    }
    catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Caccia qualcuno dal progetto
exports.RemoveDeveloper = functions.https.onCall(async (data, context) => {
    const uid = context.auth.uid;
    const projectId = data["ProjectID"];
    const targetId = data["devID"];

    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    let projectRef = db.collection("progetti").doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        }
        else {
            console.log('Progetto trovato', doc.data());
            //Qui saranno necessari controlli di sicurezza

            if ((doc.get("amministratori").includes(uid) || doc.get("proprietario") == uid) && doc.get("sviluppatori").includes(targetId) && !doc.get("amministratori").includes(targetId)) {

                let devlist = [];
                doc.get("sviluppatori").forEach(element => {
                    if (element == targetId) {
                        //skip
                    } else {
                        devlist.push(element);
                    }
                });

                let docData = doc.data();
                docData["sviluppatori"] = devlist;

                let setDoc = await db.collection('progetti').doc(projectId).set(docData);

                console.log("L'utente: ", targetId, " è stato brutalmente cacciato dal progetto: ", projectId, " dall'utente: ", uid);
                return "L'utente: " + String(targetId) + " è stato brutalmente cacciato dal progetto: " + String(projectId) + " dall'utente: " + String(uid);
            } else if (!doc.get("sviluppatori").includes(targetId)) {
                console.log("L'utente: ", targetId, " non fa parte del progetto: ", projectId);
                return new functions.https.HttpsError(404, "L'utente: " + String(targetId) + " non fa parte del progetto: " + String(projectId));
            } else if (doc.get("amministratori").includes(targetId)) {
                console.log("L'utente: ", targetId, " è amministratore del progetto: ", projectId);
                return new functions.https.HttpsError(403, "L'utente: " + String(targetId) + " è amministratore del progetto: " + String(projectId));
            } else {
                console.log("L'utente: ", uid, " non dispone dei permessi necessari per cacciare: ", targetId, " dal progetto: ", projectId);
                return new functions.https.HttpsError(403,"L'utente: " + String(uid) + " non dispone dei permessi necessari per cacciare: " + String(targetId) + " dal progetto: " + String(projectId));
            }
        }
    }
    catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Aggiungi qualcuno al progetto
exports.AddDeveloper = functions.https.onCall(async (data, context) => {
    const uid = context.auth.uid;
    const projectId = data["ProjectID"];
    const targetMail = data["devMail"];
    const admin = data["isAdmin"];

    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    //Pesca l'utente
    let utente = null;
    let utenteRef = db.collection("utenti");
    let utenteQuery = projectsRef.where('email', '==', String(targetMail));
	try {
    let utenteQuery = projectsRef.where('email', '==', String(targetMail));
    const utenteQueryResult = await utenteQuery.get();
		if (!utenteQueryResult.empty) {
			utenteQueryResult.forEach((element) => {
				if (element.exists) {
                    utente = element.data();
                }
            });
        }
    }
    catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }

    if (utente == null){
        console.log("L'utente: " + targetMail + " non è registrato");
        throw new functions.https.HttpsError(404, "L'utente: " + String(targetMail) + " non è registrato"));
    }

    //Pesca il progetto
    let projectRef = db.collection("progetti").doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        }
        else {
            console.log('Progetto trovato', doc.data());
            //Qui saranno necessari controlli di sicurezza

            if ((doc.get("amministratori").includes(uid) || doc.get("proprietario") == uid) && !doc.get("sviluppatori").includes(targetId)) {

                let devlist = [];
                doc.get("sviluppatori").forEach(element => {
                    if (element == targetId) {
                        //skip
                    } else {
                        devlist.push(element);
                    }
                });

                let docData = doc.data();
                docData["sviluppatori"] = devlist;

                let setDoc = await db.collection('progetti').doc(projectId).set(docData);

                console.log("L'utente: ", targetId, " è stato brutalmente cacciato dal progetto: ", projectId, " dall'utente: ", uid);
                return "L'utente: " + String(targetId) + " è stato brutalmente cacciato dal progetto: " + String(projectId) + " dall'utente: " + String(uid);
            } else if (!doc.get("sviluppatori").includes(targetId)) {
                console.log("L'utente: ", targetId, " non fa parte del progetto: ", projectId);
                return new functions.https.HttpsError(404, "L'utente: " + String(targetId) + " non fa parte del progetto: " + String(projectId));
            } else {
                console.log("L'utente: ", uid, " non dispone dei permessi necessari per cacciare: ", targetId, " dal progetto: ", projectId);
                return "L'utente: " + String(uid) + " non dispone dei permessi necessari per cacciare: " + String(targetId) + " dal progetto: " + String(projectId);
            }
        }
    }
    catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
});