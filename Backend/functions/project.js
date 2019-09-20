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

//Rimuovi progetto
exports.DeleteProject = functions.https.onRequest((req, res) => {
	return res.status(501).send('Non implementato');
});

//Prendi tutti i progetti per un singolo utente
exports.GetProjectsForUser = functions.https.onRequest((req, res) => {
	let uid = req.url.replace('/','');
	let token = req.get("token");
    //let utente = admin.database().ref("Utenti").child(uid).once("value");

	let result = {};

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
					result[element.id]['sviluppatori'] = element.get('sviluppatori');
					result[element.id]['amministratori'] = element.get('amministratori');
					result[element.id]['completato'] = element.get('completato');
				}
			});
		}

		//Add json to answer
		return res.status(200).send(JSON.stringify(result));

	}).catch((err) => {
		console.log("Errore Database");
		return res.status(500).send("Errore database");
	});

	console.log("uid: ",String(uid)," ha richiesto di visionare tutti i suoi progetti");
});

//Prendi un singolo progetto
exports.GetProject = functions.https.onRequest((req, res) => {
	let uid = req.url.replace('/','');
	let token = req.get("token");
    //let utente = admin.database().ref("Utenti").child(uid).once("value");

	let result = {};

	let projectRef = db.collection("progetti").doc(String(uid));
    let getProject = projectRef.get().then(doc => {

        if (!doc.exists) {
            console.log('Progetto inesistente');
            return res.status(404).send(JSON.stringify(result));
        } else {
			console.log('Progetto trovato', doc.data());
			//Qui saranno necessari controlli di sicurezza
			result["repository"] = doc.get("repository");
			result["nome"] = doc.get("nome");
			result["descrizione"] = doc.get("descrizione");
            return res.status(200).send(JSON.stringify(result));
        }
    
    }).catch(err => {
        console.log("Errore Database");
        return res.status(500).send("Errore database");
    });

	console.log("Sono state richieste informazioni sul progetto: ",String(pid)," dall'utente uid: not impl");
});