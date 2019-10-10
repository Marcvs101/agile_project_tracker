//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//Crea Sprint
exports.AddSprint = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["project"];
    const nome = data["name"];
    let descrizione = data["description"];
    if (descrizione == null) { descrizione = ""; }
    const schedule = data["schedule"];

    //Cerca il progetto
    const projectRef = db.collection('projects').doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        } else {

            //Manca un check sull'esistenza

            const sprint = await db.collection("sprints").add({
                "name": nome,
                "description": descrizione,
                "status": false,
                "project": projectId,
                "schedule": schedule,
                "userStories": []
            });

            let sprintlist = doc.get("sprints")
            sprintlist.push(sprint.id);

            let docData = doc.data();
            docData["sprints"] = sprintlist;

            console.log("L'utente: ", uid, " ha creato lo sprint: ", sprint.id, " nel progetto: ", projectId);
            return { "sprintId": sprint.id };
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Rimuovi Sprint
exports.RemoveSprint = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const sprintId = data["sprint"];
    let projectId = null;

    //Cerca lo sprint
    const sprintRef = db.collection("sprints").doc(sprintId);
    try {
        const doc = await sprintRef.get();
        if (!doc.exists) {
            console.log('Sprint inesistente');
            throw new functions.https.HttpsError(404, "Sprint inesistente");
        } else {
            projectId = doc.get("project");

            let deleteSprint = await db.collection('sprints').doc(sprintId).delete();
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError(500, "Errore database");
    }

    if (projectId) {
        const projectRef = db.collection('projects').doc(projectId);
        try {
            const doc = await projectRef.get();
            if (!doc.exists) {
                console.log('Progetto inesistente');
                throw new functions.https.HttpsError(404, "Progetto inesistente");
            } else {
                let sprintlist = doc.get("sprints")
                sprintlist = sprintlist.filter(item => item !== sprintId);

                let docData = doc.data();
                docData["sprints"] = sprintlist;

                console.log("L'utente: ", uid, " ha eliminato lo sprint: ", sprintId, " nel progetto: ", projectId);
                return { "sprint": sprintId };
            }
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError(500, "Errore database");
        }
    } else {
        console.log("L'utente: ", uid, " ha eliminato lo sprint: ", sprintId, " non associato ad alcun progetto");
        return { "sprint": sprintId };
    }
});