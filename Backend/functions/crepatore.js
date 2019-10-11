//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

exports.crepaUser = async function (uid) {
    //Remove entry from DB
    let userDel = await db.collection('developers').doc(uid).delete();

    //Tocca sbaraccà tutto il db
    let projectRef = db.collection("projects");
    try {
        let ownerQuery = projectRef.where('owner', '==', String(uid));
        const ownerQueryResult = await ownerQuery.get();
        if (!ownerQueryResult.empty) {
            ownerQueryResult.forEach(async (element) => {
                if (element.exists) {
                    exports.deleteProject(element.id, uid);
                }
            });
        }

        let adminQuery = projectRef.where('admins', 'array-contains', String(uid));
        const adminQueryResult = await adminQuery.get();
        if (!adminQueryResult.empty) {
            adminQueryResult.forEach(async (element) => {
                if (element.exists) {
                    let datiElemento = element.data();
                    let adminlist = docData["admins"];
                    if (adminlist.length == 1) {
                        exports.deleteProject(element.id, uid);
                    }
                    else {
                        adminlist = adminlist.filter(item => item !== uid);
                        docData["admins"] = adminlist;
                        let setDoc = await projectRef.doc(element.id).set(docData, { merge: true });
                    }
                }
            });
        }

        let developerQuery = projectRef.where('developers', 'array-contains', String(uid));
        const developerQueryResult = await developerQuery.get();
        if (!developerQueryResult.empty) {
            developerQueryResult.forEach(async (element) => {
                if (element.exists) {
                    let datiElemento = element.data();

                    let devlist = docData["developers"];
                    devlist = devlist.filter(item => item !== uid);

                    docData["developers"] = devlist;

                    let setDoc = await projectRef.doc(element.id).set(docData, { merge: true });
                }
            });
        }

    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError("internal", "Errore database");
    }
}

exports.crepaProject = async function (projectId, uid) {
    let projectRef = db.collection("projects").doc(projectId);
    try {
        let doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError("not-found", "Progetto inesistente");
        } else {
            let docData = doc.data();
            console.log('Progetto trovato', docData);

            //Solo l'owner può eliminare progetti
            if (docData["owner"] == uid) {

                //Brucia il progetto
                let DeleteProj = await projectRef.delete();

                //Brucia gli eventi
                let eventRef = db.collection("events");
                try {
                    let eventQuery = eventRef.where('project', '==', String(projectId));
                    const eventQueryResult = await eventQuery.get();
                    if (!eventQueryResult.empty) {
                        eventQueryResult.forEach(async (element) => {
                            if (element.exists) {
                                let DeleteEvent = await eventRef.doc(element.id).delete();
                            }
                        });
                    }

                } catch (err) {
                    console.log("Errore Database");
                    throw new functions.https.HttpsError("internal", "Errore database");
                }

                //Brucia gli sprint
                let sprintRef = db.collection("sprints");
                try {
                    let sprintQuery = sprintRef.where('project', '==', String(projectId));
                    const sprintQueryResult = await sprintQuery.get();
                    if (!sprintQueryResult.empty) {
                        sprintQueryResult.forEach(async (element) => {
                            if (element.exists) {
                                let DeleteSprint = await sprintRef.doc(element.id).delete();
                            }
                        });
                    }

                } catch (err) {
                    console.log("Errore Database");
                    throw new functions.https.HttpsError("internal", "Errore database");
                }

                //Brucia le userStory
                let userStoryRef = db.collection("userStories");
                try {
                    let userStoryQuery = userStoryRef.where('project', '==', String(projectId));
                    const userStoryQueryResult = await userStoryQuery.get();
                    if (!userStoryQueryResult.empty) {
                        userStoryQueryResult.forEach(async (element) => {
                            if (element.exists) {
                                let DeleteUserStory = userStoryRef.doc(element.id).delete();
                            }
                        });
                    }

                } catch (err) {
                    console.log("Errore Database");
                    throw new functions.https.HttpsError("internal", "Errore database");
                }

            } else {
                console.log("L'utente: ", uid, " non dispone dei permessi necessari per eliminare il progetto: ", projectId);
                return new functions.https.HttpsError(403, "L'utente: " + String(uid) + " non dispone dei permessi necessari per eliminare il progetto: " + String(projectId));
            }

        }

    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError("internal", "Errore database");
    }

    return true;
};

exports.crepaSprint = async function (projectId) {

};
