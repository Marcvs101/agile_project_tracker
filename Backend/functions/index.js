//Librerie
const admin = require('firebase-admin');
const functions = require('firebase-functions');
admin.initializeApp(functions.config().firebase);

const projectLib = require('./project');
const projectManagementLib = require('./projectManagement');
const userLib = require('./user');
const sprintLib = require('./sprint');
const userStoryLib = require('./userStory');
const eventLib = require('./event');

Object.keys(projectLib).forEach(key => { exports[key] = projectLib[key]; });
Object.keys(projectManagementLib).forEach(key => { exports[key] = projectManagementLib[key]; });
Object.keys(userLib).forEach(key => { exports[key] = userLib[key]; });
Object.keys(sprintLib).forEach(key => { exports[key] = sprintLib[key]; });
Object.keys(userStoryLib).forEach(key => { exports[key] = userStoryLib[key]; });
Object.keys(eventLib).forEach(key => { exports[key] = eventLib[key]; });
