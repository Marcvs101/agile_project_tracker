//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

exports.deleteProject = async function (projectID, uid) {
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

exports.deleteSprint = async function (projectID) {

};
