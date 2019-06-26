var MongoClient = require('mongodb').MongoClient;
var url = "mongodb://localhost:27017/Project_BERARDI";
var dbName = "Project_BERARDI";

//Inserimento
MongoClient.connect(url, { useNewUrlParser: true }, function (err, db) {
    if (err) throw err;
    var dbo = db.db(dbName);

    var myobj = { name: "Company Inc", address: "Highway 37" };

    dbo.collection("Repository").insertOne(myobj, function (err, res) {
        if (err) throw err;
        console.log("1 document inserted");
        db.close();
    });
});

//Query
MongoClient.connect(url, { useNewUrlParser: true }, function (err, db) {
    if (err) throw err;
    var dbo = db.db(dbName);

    //var query = { address: "Park Lane 38" };

    //dbo.collection("customers").find(query).toArray(function (err, result) {
    //    if (err) throw err;
    //    console.log(result);
    //    db.close();
    //});

    dbo.collection("Repository").findOne({}, function (err, result) {
        if (err) throw err;
        console.log(result.name);
        db.close();
    });
});

