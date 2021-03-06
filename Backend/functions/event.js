//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//Crea Evento
exports.AddEvent = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["project"];
    const nome = data["name"];
    let descrizione = data["description"];
    if (descrizione == null) { descrizione = ""; }
    const tipo = data["type"];
    const date = data["date"];

    //Cerca il progetto
    const projectRef = db.collection('projects').doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError("not-found", "Progetto inesistente");
        } else {

            //Manca un check sull'esistenza

            const evento = await db.collection("events").add({
                "name": nome,
                "description": descrizione,
                "project": projectId,
                "type": tipo,
                "date": date
            });

            let docData = doc.data();

            let eventlist = docData["events"];
            eventlist.push(evento.id);

            docData["events"] = eventlist;

            let setDoc = await projectRef.set(docData, { merge: true });

            console.log("L'utente: ", uid, " ha creato l'evento: ", evento.id, " nel progetto: ", projectId);
            return { "event": evento.id };
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError("internal", "Errore database");
    }
});

//Rimuovi Evento
exports.RemoveEvent = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const eventId = data["event"];
    let projectId = null;

    //Cerca la user story
    const eventRef = db.collection("events").doc(eventId);
    try {
        const doc = await eventRef.get();
        if (!doc.exists) {
            console.log('Evento inesistente');
            throw new functions.https.HttpsError("not-found", "Evento inesistente");
        } else {
            let docData = doc.data();

            projectId = docData["project"];

            let deleteEvent = await eventRef.delete();
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError("internal", "Errore database");
    }

    if (projectId) {
        const projectRef = db.collection('projects').doc(projectId);
        try {
            const doc = await projectRef.get();
            if (!doc.exists) {
                console.log('Progetto inesistente');
                throw new functions.https.HttpsError("not-found", "Progetto inesistente");
            } else {
                let docData = doc.data();

                let eventlist = docData["events"];
                eventlist = eventlist.filter(item => item !== eventId);

                docData["events"] = eventlist;

                let setDoc = await projectRef.set(docData, { merge: true });

                console.log("L'utente: ", uid, " ha eliminato l'evento': ", eventId, " nel progetto: ", projectId);
                return { "event": eventId };
            }
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError("internal", "Errore database");
        }
    } else {
        console.log("L'utente: ", uid, " ha eliminato l'evento': ", eventId, " non associato ad alcun progetto");
        return { "event": eventId };
    }
});