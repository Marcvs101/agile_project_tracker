//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');
admin.initializeApp(functions.config().firebase);

const projectLib = require('./project');
const userLib = require('./user');

Object.keys(projectLib).forEach(key => {exports[key] = projectLib[key];});
Object.keys(userLib).forEach(key => {exports[key] = userLib[key];});

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
