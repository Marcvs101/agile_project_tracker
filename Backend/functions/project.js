//Crea progetto
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

//Rimuovi progetto
exports.DeleteProject = functions.https.onCall((data, context) => {

});

//Prendi tutti i progetti per un singolo utente
exports.GetProjectForUser = functions.https.onCall((data, context) => {

});

//Prendi un singolo progetto
exports.GetProject = functions.https.onCall((data, context) => {

});