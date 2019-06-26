//Connect to DB
const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp(functions.config().firebase);

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
exports.RegisterNewUser = functions.auth.user().onCreate((user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Add data
    let docRef = db.collection('utenti').doc(uid);
    let seUser = docRef.set({
        'nome': displayName,
        'email': email
    });

    console.log("User " + string(uid) + " aka " + string(displayName) + " joined the world");
});

exports.UnregisterUser = functions.auth.user().onDelete((user) => {
    const email = user.email; // The email of the user.
    const displayName = user.displayName; // The display name of the user.
    const uid = user.uid;

    //Remove entry from DB
    let docRef = db.collection('utenti').doc(uid).delete();

    console.log("User " + string(uid) + " aka " + string(displayName) + " left the world");
});

//crea-rimuovi progetto

exports.CreateNewProject = functions.https.onCall((data, context) => {
	const uid = context.auth.uid;
	const projectId = data.projectId;
	const nome = data.nome;

	let check = db.collection('progetti').doc(projectId);
	let getCheck = check.get()
		.then( doc => {
			if (doc.exists) {
				console.log("progetto già esistente");
				throw new functions.https.HttpsError("already-exists","progetto già esistente");
			}
		})
		.catch( err => {
			console.log('errore database')
			throw new functions.https.HttpsError("internal","errore database");
		});

	let docRef = db.collection("progetti").doc(projectId);
	let progetto = docRef.set({
		"nome": nome,
		"proprietario":uid,
		"sviluppatori": [uid],
		"user_story": [],
		"completato": false
	});
	console.log("L'utente " + uid + " ha creato il progetto " + projectId);

});

