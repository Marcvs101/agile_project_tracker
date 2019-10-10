//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//Crea User story
exports.AddUserStory = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["project"];
    const sprintId = data["sprint"];//not set
    const nome = data["name"];
    let descrizione = data["description"];
    if (descrizione == null) { descrizione = ""; }
    const score = data["score"];
    const completed = data["completed"]

    //Cerca il progetto
    const projectRef = db.collection('projects').doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        } else {

            //Manca un check sull'esistenza

            const userStory = await db.collection("userStories").add({
                "name": nome,
                "description": descrizione,
                "project": projectId,
                "sprint": sprintId,
                "score": score,
                "completed": completed
            });

            let userstorylist = doc.get("userStories")
            userstorylist.push(userStory.id);

            let docData = doc.data();
            docData["userStories"] = userstorylist;

            console.log("L'utente: ", uid, " ha creato la user story: ", userstorylist.id, " nel progetto: ", projectId);
            return { "userStory": userStory.id };
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError(500, "Errore database");
    }
});

//Rimuovi User story
exports.RemoveUserStory = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError(511, "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const userStoryId = data["userStory"];
    let projectId = null;

    //Cerca la user story
    const userStoryRef = db.collection("sprints").doc(userStoryId);
    try {
        const doc = await userStoryRef.get();
        if (!doc.exists) {
            console.log('User Story inesistente');
            throw new functions.https.HttpsError(404, "User Story inesistente");
        } else {
            projectId = doc.get("project");

            let deleteUserStory = await db.collection('userStories').doc(userStoryId).delete();
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
                let userstorylist = doc.get("userStories")
                userstorylist = userstorylist.filter(item => item !== userStoryId);

                let docData = doc.data();
                docData["userStories"] = userstorylist;

                console.log("L'utente: ", uid, " ha eliminato la user story: ", userStoryId, " nel progetto: ", projectId);
                return { "userStory": userStoryId };
            }
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError(500, "Errore database");
        }
    } else {
        console.log("L'utente: ", uid, " ha eliminato la user story: ", sprintId, " non associato ad alcun progetto");
        return { "userStory": userStoryId };
    }
});