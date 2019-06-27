//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');

let db = admin.firestore();

/*
//Read data
db.collection('utenti').get()
    .then((snapshot) => {
        snapshot.forEach((doc) => {
            console.log(doc.id, '=>', doc.data());
        });
    })
    .catch((err) => {
        console.log('Error getting documents', err);
    });
*/

//Crea progetto
exports.CreateNewProject = functions.https.onCall((data, context) => {
	const uid = context.auth.uid;
	const projectId = data.projectId;
	const nome = data.nome;

	let check = db.collection('progetti').doc(projectId);
	let getCheck = check.get()
		.then(doc => {
			if (doc.exists) {
				console.log("progetto già esistente");
				throw new functions.https.HttpsError("already-exists", "progetto già esistente");
			}
		})
		.catch(err => {
			console.log('errore database')
			throw new functions.https.HttpsError("internal", "errore database");
		});

	let docRef = db.collection("progetti").doc(projectId);
	let progetto = docRef.set({
		"nome": nome,
		"proprietario": uid,
		"sviluppatori": [uid],
		"user_story": [],
		"completato": false
	});

	console.log("L'utente " + String(uid) + " ha creato il progetto " + String(projectId));
});

//Rimuovi progetto
exports.DeleteProject = functions.https.onCall((data, context) => {

});

//Prendi tutti i progetti per un singolo utente
exports.GetProjectsForUser = functions.https.onCall((data, context) => {
	const uid = context.auth.uid;

	let result = { 'project': {} };

	let projectsRef = db.collection("progetti");
	let projectsQuery = projectsRef.where('sviluppatori', 'array-contains', String(uid));
	projectsQuery.get().then((projectQueryResult) => {
		if (!projectQueryResult.empty) {
			projectQueryResult.forEach((element) => {
				if (element.exists) {
					console.log("Result exists - good");
					result[element.id] = {};
					result[element.id]['nome'] = element.get('nome');
					result[element.id]['descrizione'] = element.get('descrizione');
					result[element.id]['proprietario'] = element.get('proprietario');
					result[element.id]['completato'] = element.get('completato');
				}
			});
		}

		return result;

	}).catch((err) => {
		console.log("Errore Database");
		throw new functions.https.HttpsError("internal", "Errore nel database (GetProjectsForUser)\n",err.toString());
	});

	console.log("uid: ",String(uid)," ha richiesto di visionare tutti i suoi progetti");
});

//Prendi un singolo progetto
exports.GetProject = functions.https.onCall((data, context) => {

});