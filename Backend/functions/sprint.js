//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

//Crea Sprint
exports.AddSprint = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const projectId = data["project"];
    const nome = data["name"];
    let descrizione = data["description"];
    if (descrizione == null) { descrizione = ""; }
    const schedule = data["schedule"];
    const userStories = data["userstories"];

    //Cerca il progetto
    const projectRef = db.collection('projects').doc(projectId);
    try {
        const doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError("not-found", "Progetto inesistente");
        } else {

            //Manca un check sull'esistenza

            const sprint = await db.collection("sprints").add({
                "name": nome,
                "description": descrizione,
                "status": false,
                "project": projectId,
                "schedule": schedule,
                "userStories": userStories
            });

            let docData = doc.data();

            let sprintlist = docData["sprints"];
            sprintlist.push(sprint.id);

            docData["sprints"] = sprintlist;

            //Associa userstory a sprint
            for (const element of userStories){
                const userStoryRef = db.collection("userStories").doc(element);
                const userStoryDoc = await userStoryRef.get();
                if (!userStoryDoc.exists) {
                    console.log('User story inesistente');
                    throw new functions.https.HttpsError("not-found", "User story inesistente");
                } else {
                    let userStoryDocData = userStoryDoc.data();

                    if (userStoryDocData["sprint"] == "") {
                        userStoryDocData["sprint"] = sprint.id;
                    } else {
                        //Recovery
                        for (const recovery of userStories){
                            const RecoveryRef = db.collection("userStories").doc(recovery);
                            const RecoveryDoc = await RecoveryRef.get();
                            if (!RecoveryDoc.exists) {
                                console.log('User story inesistente');
                                throw new functions.https.HttpsError("not-found", "User story inesistente");
                            } else {
                                let RecoveryDocData = RecoveryDoc.data();

                                if (RecoveryDocData["sprint"] == sprint.id) {
                                    RecoveryDocData["sprint"] = "";
                                    let setuserStoryDoc = RecoveryRef.set(RecoveryDocData, { merge: true });
                                }
                            }
                        };

                        console.log('La user story ', element, " appartiene già ad un altro sprint");
                        throw new functions.https.HttpsError("not-found", 'La user story ' + String(element) + " appartiene già ad un altro sprint");
                    }

                    let userStoryProject = userStoryDocData["project"];

                    if (userStoryProject == projectId) {
                        let setuserStoryDoc = userStoryRef.set(userStoryDocData, { merge: true });
                    } else {
                        //Recovery
                        for (const recovery of userStories){
                            const RecoveryRef = db.collection("userStories").doc(recovery);
                            const RecoveryDoc = await RecoveryRef.get();
                            if (!RecoveryDoc.exists) {
                                console.log('User story inesistente');
                                throw new functions.https.HttpsError("not-found", "User story inesistente");
                            } else {
                                let RecoveryDocData = RecoveryDoc.data();

                                if (RecoveryDocData["sprint"] == sprint.id) {
                                    RecoveryDocData["sprint"] = "";
                                    let setuserStoryDoc = RecoveryRef.set(RecoveryDocData, { merge: true });
                                }
                            }
                        };

                        console.log('La user story ', element, " non appartiene al progetto ", projectId);
                        throw new functions.https.HttpsError("not-found", 'La user story ' + String(element) + " non appartiene al progetto " + String(projectId));
                    }
                }
            };

            let setDoc = projectRef.set(docData, { merge: true });

            console.log("L'utente: ", uid, " ha creato lo sprint: ", sprint.id, " nel progetto: ", projectId);
            return { "sprintId": sprint.id };
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError("internal", "Errore database");
    }
});

//Rimuovi Sprint
exports.RemoveSprint = functions.https.onCall(async (data, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
    }

    const uid = context.auth.uid;
    const sprintId = data["sprint"];
    let projectId = null;
    let userStorylist = null;

    //Cerca lo sprint
    const sprintRef = db.collection("sprints").doc(sprintId);
    try {
        const doc = await sprintRef.get();
        if (!doc.exists) {
            console.log('Sprint inesistente');
            throw new functions.https.HttpsError("not-found", "Sprint inesistente");
        } else {
            let docData = doc.data();

            projectId = docData["project"];
            userStorylist = docData["userStories"];

            let deleteSprint = sprintRef.delete();
        }
    } catch (err) {
        console.log('Errore database');
        throw new functions.https.HttpsError("internal", "Errore database");
    }

    //Se ci sono le user story, aggiorna i campi
    if (userStorylist) {
        try {
            for (const element of userStorylist){
                const userStoryRef = db.collection("userStories").doc(element);
                const userStoryDoc = await userStoryRef.get();
                if (!userStoryDoc.exists) {
                    console.log('User story inesistente');
                    throw new functions.https.HttpsError("not-found", "User story inesistente");
                } else {
                    let userStoryDocData = userStoryDoc.data();

                    userStoryDocData["sprint"] = "";
                    userStoryDocData["completed"] = "";

                    let setUserStoryDoc = await userStoryRef.set(userStoryDocData, { merge: true });
                }
            };
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError("internal", "Errore database");
        }
    }

    //Se associato al progetto, aggiorna i campi
    if (projectId) {
        const projectRef = db.collection('projects').doc(projectId);
        try {
            const doc = await projectRef.get();
            if (!doc.exists) {
                console.log('Progetto inesistente');
                throw new functions.https.HttpsError("not-found", "Progetto inesistente");
            } else {
                let docData = doc.data();

                let sprintlist = docData["sprints"];
                sprintlist = sprintlist.filter(item => item !== sprintId);

                docData["sprints"] = sprintlist;

                let setDoc = await projectRef.set(docData, { merge: true });

                console.log("L'utente: ", uid, " ha eliminato lo sprint: ", sprintId, " nel progetto: ", projectId);
                return { "sprint": sprintId };
            }
        } catch (err) {
            console.log('Errore database');
            throw new functions.https.HttpsError("internal", "Errore database");
        }
    } else {
        console.log("L'utente: ", uid, " ha eliminato lo sprint: ", sprintId, " non associato ad alcun progetto");
        return { "sprint": sprintId };
    }
});

exports.checkCompleted = async function (data) {
    let userStorylist = data["userStories"];

    for (const element of userStorylist){
        const userStoryRef = db.collection("userStories").doc(element);
        const userStoryDoc = await userStoryRef.get();
        if (!userStoryDoc.exists) {
            console.log('User story inesistente');
            throw new functions.https.HttpsError("not-found", "User story inesistente");
        } else {
            let userStoryDocData = userStoryDoc.data();

            if (userStoryDocData["completed"] == "") {
                return false;
            }
        }
    };

    return true;
};