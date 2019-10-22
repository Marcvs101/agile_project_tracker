//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');
const CrepatoreLib = require('./crepatore');

let db = admin.firestore();

//Crea Progetto
exports.CreateNewProject = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
	}

	const uid = context.auth.uid;

	const nome = data["name"];
	let descrizione = data["description"];
	if (descrizione == null) { descrizione = ""; }
	const isGithub = data["github"];

	//Manca un check sull'esistenza

	//Occhio ai parametri passati
	const progetti = db.collection('projects');
	try {
		const ref = await progetti.add({
			"name": nome,
			"description": descrizione,
			"owner": uid,
			"developers": [uid],
			"admins": [uid],
			"userStories": [],
			"events": [],
			"sprints": [],
			"github": isGithub,
			"completed": false
		});

		console.log("L'utente ", uid, " ha creato il progetto ", ref.id);
		return { "project": ref.id };
	} catch (err) {
		console.log('Errore database');
		throw new functions.https.HttpsError("internal", "Errore database");
	}
});

//Rimuovi progetto
exports.DeleteProject = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
	}

	const uid = context.auth.uid;
	const projectId = data["project"];

	let risultato = await CrepatoreLib.crepaProject(projectId, uid);

	console.log("L'utente: ", uid, " ha eliminato il progetto: ", projectId);
	return risultato;
});

//Prendi tutti i progetti per un singolo utente
exports.GetProjectsForUser = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
	}

	const uid = context.auth.uid;

	let result = {};

	let projectsRef = db.collection("projects");
	let projectsQuery = projectsRef.where('developers', 'array-contains', String(uid));
	try {
		const projectQueryResult = await projectsQuery.get();
		if (!projectQueryResult.empty) {
			const projectQueryResultDocs = projectQueryResult.docs;
			for (const element of projectQueryResultDocs){
				if (element.exists) {
					console.log("Result exists - good");
					let datiElemento = element.data();

					result[element.id] = {};
					result[element.id]['name'] = datiElemento['name'];
					result[element.id]['description'] = datiElemento['description'];
					result[element.id]['owner'] = datiElemento['owner'];
					result[element.id]['developers'] = datiElemento['developers'];
					result[element.id]['admins'] = datiElemento['admins'];
					result[element.id]['userStories'] = datiElemento['userStories'];
					result[element.id]['events'] = datiElemento['events'];
					result[element.id]['sprints'] = datiElemento['sprints'];
					result[element.id]['github'] = datiElemento['github'];
					result[element.id]['completed'] = datiElemento['completed'];
				}
			};
		}

		console.log("uid: ", String(uid), " ha richiesto di visionare tutti i suoi progetti");
		return JSON.stringify(result);
	} catch (err) {
		console.log("Errore Database");
		throw new functions.https.HttpsError("internal", "Errore database");
	}

});

//Prendi un singolo progetto
exports.GetProject = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError("unauthenticated", "Necessaria autenticazione");
	}

	const uid = context.auth.uid;
	const projectId = data["ProjectID"];

	let result = {};

	let projectRef = db.collection("projects").doc(projectId);
	try {
		const doc = await projectRef.get();
		if (!doc.exists) {
			console.log('Progetto inesistente');
			throw new functions.https.HttpsError("not-found", "Progetto inesistente");
		} else {
			console.log('Progetto trovato', doc.data());

			if (element.get('developers').includes(uid)) {
				let datiElemento = element.data();

				result['name'] = datiElemento['name'];
				result['description'] = datiElemento['description'];
				result['owner'] = datiElemento['owner'];
				result['developers'] = datiElemento['developers'];
				result['admins'] = datiElemento['admins'];
				result['userStories'] = datiElemento['userStories'];
				result['events'] = datiElemento['events'];
				result['sprints'] = datiElemento['sprints'];
				result['github'] = datiElemento['github'];
				result['completed'] = datiElemento['completed'];

				console.log("Sono state richieste informazioni sul progetto: ", projectId, " dall'utente uid: ", uid);
				return JSON.stringify(result);
			} else {
				console.log("L'utente: ", uid, " non appartiene al progetto ", projectId);
				throw new functions.https.HttpsError("permission-denied", "L'utente: " + String(uid) + " non appartiene al progetto " + String(projectId));
			}
		}
	} catch (err) {
		console.log("Errore Database");
		throw new functions.https.HttpsError("internal", "Errore database");
	}
});