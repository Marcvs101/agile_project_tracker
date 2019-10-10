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
/*
exports.CreateNewProject = functions.https.onRequest((req, res) => {
  	
	const JSONreq = JSON.parse(req.url.replace('/',''));
	const uid = JSONreq['uid'];
	let token = req.get("token");
	//let utente = admin.database().ref("Utenti").child(uid).once("value");
	
	const projectId = JSONreq['projectId'];
	const nome = JSONreq['nome'];
	const descrizione = JSONreq['descrizione'];

	let check = db.collection('progetti').doc(projectId);
	let getCheck = check.get()
		.then(doc => {
			if (doc.exists) {
				console.log("progetto già esistente");
				return res.status(409).send("Progetto gia esistente");
			}
		})
		.catch(err => {
			console.log('errore database')
			return res.status(500).send("Errore database");
		});

	let docRef = db.collection("progetti").doc(projectId);
	let progetto = docRef.set({
		"nome": nome,
		"descrizione": descrizione,
		"proprietario": uid,
		"sviluppatori": [uid],
		"amministratori": [uid],
		"user_story": [],
		"completato": false
	});

	console.log("L'utente " + String(uid) + " ha creato il progetto " + String(projectId));
	return res.status(201).send('Progetto creato');
});
*/

//Crea Progetto
exports.CreateNewProject = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError(511, "Necessaria autenticazione");
	}

	const uid = context.auth.uid;

	const nome = data["name"];
	let descrizione = data["description"];
	if (descrizione == null) { descrizione = ""; }

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
			"completed": false
		});

		console.log("L'utente ", uid, " ha creato il progetto ", ref.id);
		return { "project": ref.id };
	} catch (err) {
		console.log('Errore database');
		throw new functions.https.HttpsError(500, "Errore database");
	}
});

//Rimuovi progetto
exports.DeleteProject = functions.https.onCall((data, context) => {

	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError(511, "Necessaria autenticazione");
	}

	const uid = context.auth.uid;

	throw new functions.https.HttpsError(404, 'Non implementato');
});

//Prendi tutti i progetti per un singolo utente
exports.GetProjectsForUser = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError(511, "Necessaria autenticazione");
	}

	const uid = context.auth.uid;

	let result = {};

	let projectsRef = db.collection("projects");
	let projectsQuery = projectsRef.where('developers', 'array-contains', String(uid));
	try {
		const projectQueryResult = await projectsQuery.get();
		if (!projectQueryResult.empty) {
			projectQueryResult.forEach((element) => {
				if (element.exists) {
					console.log("Result exists - good");
					result[element.id] = {};
					result[element.id]['name'] = element.get('name');
					result[element.id]['description'] = element.get('description');
					result[element.id]['owner'] = element.get('owner');
					result[element.id]['developers'] = element.get('developers');
					result[element.id]['admins'] = element.get('admins');
					result[element.id]['userStories'] = element.get('userStories');
					result[element.id]['events'] = element.get('events');
					result[element.id]['sprints'] = element.get('sprints');
					result[element.id]['completed'] = element.get('completed');
				}
			});
		}

		console.log("uid: ", String(uid), " ha richiesto di visionare tutti i suoi progetti");
		return JSON.stringify(result);
	} catch (err) {
		console.log("Errore Database");
		throw new functions.https.HttpsError(500, "Errore database");
	}

});

//Prendi un singolo progetto
exports.GetProject = functions.https.onCall(async (data, context) => {
	// Checking that the user is authenticated.
	if (!context.auth) {
		throw new functions.https.HttpsError(511, "Necessaria autenticazione");
	}

	const uid = context.auth.uid;
	const projectId = data["ProjectID"];

	let result = {};

	let projectRef = db.collection("projects").doc(projectId);
	try {
		const doc = await projectRef.get();
		if (!doc.exists) {
			console.log('Progetto inesistente');
			throw new functions.https.HttpsError(404, "Progetto inesistente");
		} else {
			console.log('Progetto trovato', doc.data());

			if (element.get('developers').includes(uid)) {
				result['name'] = element.get('name');
				result['description'] = element.get('description');
				result['owner'] = element.get('owner');
				result['developers'] = element.get('developers');
				result['admins'] = element.get('admins');
				result['userStories'] = element.get('userStories');
				result['events'] = element.get('events');
				result['sprints'] = element.get('sprints');
				result['completed'] = element.get('completed');

				console.log("Sono state richieste informazioni sul progetto: ", projectId, " dall'utente uid: ", uid);
				return JSON.stringify(result);
			} else {
				console.log("L'utente: ", uid, " non appartiene al progetto ", projectId);
				throw new functions.https.HttpsError(403, "L'utente: " + String(uid) + " non appartiene al progetto " + String(projectId));
			}
		}
	} catch (err) {
		console.log("Errore Database");
		throw new functions.https.HttpsError(500, "Errore database");
	}
});