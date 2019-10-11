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
    const nome = data["name"];
    let descrizione = data["description"];
    if (descrizione == null) { descrizione = ""; }
    const score = data["score"];

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
                "sprint": "",
                "score": score,
                "completed": ""
            });

            let docData = doc.data();

            let userstorylist = docData["userStories"];
            userstorylist.push(userStory.id);

            docData["userStories"] = userstorylist;

            let setDoc = projectRef.set(docData, { merge: true });

            console.log("L'utente: ", uid, " ha creato la user story: ", userStory.id, " nel progetto: ", projectId);
            return { "userstory": userStory.id };
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
    const userStoryRef = db.collection("userStories").doc(userStoryId);
    try {
        const doc = await userStoryRef.get();
        if (!doc.exists) {
            console.log('User Story inesistente');
            throw new functions.https.HttpsError(404, "User Story inesistente");
        } else {
            projectId = doc.get("project");

            let deleteUserStory = await userStoryRef.delete();
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
                let docData = doc.data();

                let userstorylist = docData["userStories"];
                userstorylist = userstorylist.filter(item => item !== userStoryId);

                docData["userStories"] = userstorylist;

                let setDoc = await projectRef.set(docData, { merge: true });

                console.log("L'utente: ", uid, " ha eliminato la user story: ", userStoryId, " nel progetto: ", projectId);
                return { "userStory": userStoryId };
            }
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError(500, "Errore database");
        }
    } else {
        console.log("L'utente: ", uid, " ha eliminato la user story: ", userStoryId, " non associato ad alcun progetto");
        return { "userStory": userStoryId };
    }
});