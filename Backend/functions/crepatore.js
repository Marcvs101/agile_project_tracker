//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

exports.crepaUser = async function (uid) {
    //Remove entry from DB
    let docRef = await db.collection('developers').doc(uid).delete();

    //Tocca sbaraccà tutto il db
    let projectRef = db.collection("projects");
    try {
        let ownerQuery = projectRef.where('owner', '==', String(uid));
        const ownerQueryResult = await ownerQuery.get();
        if (!ownerQueryResult.empty) {
            ownerQueryResult.forEach(async (element) => {
                if (element.exists) {
                    CrepatoreLib.deleteProject(element.id);
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
                        CrepatoreLib.deleteProject(element.id);
                    }
                    else {
                        adminlist = adminlist.filter(item => item !== uid);
                        docData["admins"] = adminlist;
                        let setDoc = await db.collection('projects').doc(element.id).set(docData, { merge: true });
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

                    let setDoc = await db.collection('projects').doc(element.id).set(docData, { merge: true });
                }
            });
        }

    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }
}

exports.crepaProject = async function (projectID, uid) {
    let projectRef = db.collection("projects").doc(projectId);
    try {
        let doc = await projectRef.get();
        if (!doc.exists) {
            console.log('Progetto inesistente');
            throw new functions.https.HttpsError(404, "Progetto inesistente");
        } else {
            let docData = doc.data();
            console.log('Progetto trovato', docData);

            //Solo l'owner può eliminare progetti
            if (docData["owner"] == uid) {

                //Brucia il progetto
                let DeleteProj = await db.collection('projects').doc(projectId).delete();

                //Brucia gli eventi
                let eventRef = db.collection("events");
                try {
                    let eventQuery = eventRef.where('project', '==', String(projectID));
                    const eventQueryResult = await eventQuery.get();
                    if (!eventQueryResult.empty) {
                        eventQueryResult.forEach((element) => {
                            if (element.exists) {

                                element.delete();
                                //let DeleteEvent = db.collection('events').doc(element.id).delete();

                            }
                        });
                    }

                } catch (err) {
                    console.log("Errore Database");
                    throw new functions.https.HttpsError(500, "Errore database");
                }

                //Brucia gli sprint
                let sprintRef = db.collection("sprints");
                try {
                    let sprintQuery = sprintRef.where('project', '==', String(projectID));
                    const sprintQueryResult = await sprintQuery.get();
                    if (!sprintQueryResult.empty) {
                        sprintQueryResult.forEach((element) => {
                            if (element.exists) {

                                element.delete();
                                //let DeleteEvent = db.collection('sprints').doc(element.id).delete();

                            }
                        });
                    }

                } catch (err) {
                    console.log("Errore Database");
                    throw new functions.https.HttpsError(500, "Errore database");
                }

                //Brucia le userStory
                let userStoryRef = db.collection("userStories");
                try {
                    let userStoryQuery = userStoryRef.where('project', '==', String(projectID));
                    const userStoryQueryResult = await userStoryQuery.get();
                    if (!userStoryQueryResult.empty) {
                        userStoryQueryResult.forEach((element) => {
                            if (element.exists) {

                                element.delete();
                                //let DeleteEvent = db.collection('userStories').doc(element.id).delete();

                            }
                        });
                    }

                } catch (err) {
                    console.log("Errore Database");
                    throw new functions.https.HttpsError(500, "Errore database");
                }

            } else {
                console.log("L'utente: ", uid, " non dispone dei permessi necessari per eliminare il progetto: ", projectId);
                return new functions.https.HttpsError(403, "L'utente: " + String(uid) + " non dispone dei permessi necessari per eliminare il progetto: " + String(projectId));
            }

        }

    } catch (err) {
        console.log("Errore Database");
        throw new functions.https.HttpsError(500, "Errore database");
    }

    return true;
};

exports.crepaSprint = async function (projectID) {

};
