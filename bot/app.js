var Swagger = require('swagger-client')
  , fs = require('fs')
  , spec = require('./spec');

// Use the SwaggerJS module to dynamically load the Swagger spec
new Swagger({
  spec: spec,
  usePromise: true
})
  .then(function (res) {
    client = res;
    
    // Start getting changes at seq: 0
    getChanges(0);
    
    function getChanges(seq) {
      // Use the Swagger client to connect to the changes feed
      client.database.get_db_changes({db: 'todo', include_docs: true, since: seq, feed: 'longpoll'})
        .then(function (res) {
          var results = res.obj.results;
          console.log(results.length + ' change(s) received');
          processChanges(results);
          // Get changes since the last sequence
          getChanges(res.obj.last_seq);
        })
        .catch(function (err) {
          console.log(err);
        });
    }
    
    function processChanges(results) {
      for (var i = 0; i < results.length; i++) {
        var doc = results[i].doc;
        var img;
        if (doc && !doc._deleted && doc.type == 'task' && !doc._attachments) {
          switch (doc.task.toLowerCase()) {
            case 'apple':
              img = fs.readFileSync('apple.png');
              break;
            case 'coffee':
              img = fs.readFileSync('coffee.png');
              break;
            case 'potatoes':
              img = fs.readFileSync('potatoes.png');
              break;
          }
          if (img) {
            var base64 = img.toString('base64');
            doc._attachments = {
              image: {
                content_type: 'image\/png',
                data: base64
              }
            };
            client.database.post_db_bulk_docs({db: 'todo', BulkDocsBody: {docs: [doc]}})
              .then(function (res) { 
                console.log('1 change posted');
              })
              .catch(function (err) {
                console.log(err);
              });
          }
        }
      }
    }

  });