//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');
const sprintLib = require('./sprint');

let db = admin.firestore();

//Crea User story
exports.AddUserStory = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
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
            throw new functions.https.HttpsError("not-found", "Progetto inesistente");
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
        throw new functions.https.HttpsError("internal", "Errore database");
    }
});

//Rimuovi User story
exports.RemoveUserStory = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
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
            throw new functions.https.HttpsError("not-found", "User Story inesistente");
        } else {
            projectId = doc.get("project");

            let deleteUserStory = await userStoryRef.delete();
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

                let userstorylist = docData["userStories"];
                userstorylist = userstorylist.filter(item => item !== userStoryId);

                docData["userStories"] = userstorylist;

                let setDoc = await projectRef.set(docData, { merge: true });

                console.log("L'utente: ", uid, " ha eliminato la user story: ", userStoryId, " nel progetto: ", projectId);
                return { "userStory": userStoryId };
            }
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError("internal", "Errore database");
        }
    } else {
        console.log("L'utente: ", uid, " ha eliminato la user story: ", userStoryId, " non associato ad alcun progetto");
        return { "userStory": userStoryId };
    }
});

//Revoca user story
exports.RevokeUserStory = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const userStoryId = data["userStory"];

    //Cerca la user story
    const userStoryRef = db.collection('userStories').doc(userStoryId);
    try {
        const userStoryDoc = await userStoryRef.get();
        if (!userStoryDoc.exists) {
            console.log('User Story inesistente');
            throw new functions.https.HttpsError("not-found", "User Story inesistente");
        } else {
            let userStoryDocData = userStoryDoc.data();

            let projectId = userStoryDocData["project"];
            let sprintId = userStoryDocData["sprint"];

            if (sprintId == ""){
                console.log("La user story ",userStoryId," non fa parte di nessuno sprint");
                throw new functions.https.HttpsError("not-found", "La user story "+String(userStoryId)+" non fa parte di nessuno sprint");
            }

            //Cerca il progetto
            const projectRef = db.collection('projects').doc(projectId);
            const projectDoc = await projectRef.get();
            if (!projectDoc.exists) {
                console.log('Progetto inesistente');
                throw new functions.https.HttpsError("not-found", "Progetto inesistente");
            } else {
                let projectDocData = projectDoc.data();

                let adminlist = projectDocData["admins"];

                if (adminlist.includes(uid)) {

                    //Cerca sprint
                    const sprintRef = db.collection("sprints").doc(sprintId);
                    const sprintDoc = await sprintRef.get();
                    if (!sprintDoc.exists) {
                        console.log('Sprint inesistente');
                        throw new functions.https.HttpsError("not-found", "Sprint inesistente");
                    } else {
                        let sprintDocData = sprintDoc.data();

                        let userStorylist = sprintDocData["userStories"];

                        if (userStorylist.includes(userStoryId)) {
                            //gestisci user story
                            userStoryDocData["completed"] = "";
                            userStoryDocData["sprint"] = "";
                            let setUserStoryDoc = await userStoryRef.set(userStoryDocData, { merge: true });

                            //Togli user story
                            userStorylist = userStorylist.filter(item => item !== userStoryId);
                            sprintDocData["userStories"] = userStorylist;

                            //Se nessuna user story, crepa sprint, altrimenti aggiorna
                            if (userStorylist.length == 0) {
                                let delSprint = await sprintRef.delete();

                                console.log("La user story ", userStoryId, " è stata revocata, secondo l'utente ", uid, " causando l'eliminazione dello sprint ", sprintId);
                                return true;
                            } else {
                                //Controlla se sprint è completato
                                if (await sprintLib.checkCompleted(sprintDocData)) {
                                    sprintDocData["status"] = true;
                                }

                                let setSprintDoc = await sprintRef.set(sprintDocData, { merge: true });
                            }

                            console.log("La user story ", userStoryId, " è stata revocata, secondo l'utente ", uid);
                            return true;

                        } else {
                            console.log("La user story ", userStoryId, " non fa parte dello sprint ", sprintId);
                            throw new functions.https.HttpsError("not-found", "La user story " + String(userStoryId) + " non fa parte dello sprint " + String(sprintId));
                        }
                    }

                } else {
                    console.log("L'utente ", uid, " non fa parte del progetto ", projectId);
                    throw new functions.https.HttpsError("not-found", "L'utente " + String(uid) + " non fa parte del progetto " + String(projectId));
                }

            }

        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError("internal", "Errore database");
    }
});

//Completa user story
exports.CompleteUserStory = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const userStoryId = data["userStory"];
    const completed = data["completed"];

    //Cerca la user story
    const userStoryRef = db.collection('userStories').doc(userStoryId);
    try {
        const userStoryDoc = await userStoryRef.get();
        if (!userStoryDoc.exists) {
            console.log('User Story inesistente');
            throw new functions.https.HttpsError("not-found", "User Story inesistente");
        } else {
            let userStoryDocData = userStoryDoc.data();

            let projectId = userStoryDocData["project"];
            let sprintId = userStoryDocData["sprint"];

            if (sprintId == ""){
                console.log("La user story ",userStoryId," non fa parte di nessuno sprint");
                throw new functions.https.HttpsError("not-found", "La user story "+String(userStoryId)+" non fa parte di nessuno sprint");
            }

            //Cerca il progetto
            const projectRef = db.collection('projects').doc(projectId);
            const projectDoc = await projectRef.get();
            if (!projectDoc.exists) {
                console.log('Progetto inesistente');
                throw new functions.https.HttpsError("not-found", "Progetto inesistente");
            } else {
                let projectDocData = projectDoc.data();

                let adminlist = projectDocData["admins"];

                if (adminlist.includes(uid)) {

                    //Cerca sprint
                    const sprintRef = db.collection("sprints").doc(sprintId);
                    const sprintDoc = await sprintRef.get();
                    if (!sprintDoc.exists) {
                        console.log('Sprint inesistente');
                        throw new functions.https.HttpsError("not-found", "Sprint inesistente");
                    } else {
                        let sprintDocData = sprintDoc.data();

                        let userStorylist = sprintDocData["userStories"];

                        if (userStorylist.includes(userStoryId)) {
                            //gestisci user story
                            userStoryDocData["completed"] = completed;
                            let setUserStoryDoc = await userStoryRef.set(userStoryDocData, { merge: true });

                            //Controlla se sprint è completato
                            if (await sprintLib.checkCompleted(sprintDocData)) {
                                sprintDocData["status"] = true;
                            }

                            let setSprintDoc = await sprintRef.set(sprintDocData, { merge: true });

                            console.log("La user story ", userStoryId, " è stata completata, secondo l'utente ", uid);
                            return true;

                        } else {
                            console.log("La user story ", userStoryId, " non fa parte dello sprint ", sprintId);
                            throw new functions.https.HttpsError("not-found", "La user story " + String(userStoryId) + " non fa parte dello sprint " + String(sprintId));
                        }
                    }

                } else {
                    console.log("L'utente ", uid, " non fa parte del progetto ", projectId);
                    throw new functions.https.HttpsError("not-found", "L'utente " + String(uid) + " non fa parte del progetto " + String(projectId));
                }

            }

        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError("internal", "Errore database");
    }
});