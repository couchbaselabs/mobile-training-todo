var spec = require('./spec')
  , SwaggerClient = require('swagger-client')
  , request = require('request-promise');

var options = {
  url: 'http://localhost:4985/',
  db: 'todo',
  concurrency: 20,
  users: ['user1', 'user2', 'mod', 'admin'],
};

var client = new SwaggerClient({
  spec: spec,
  usePromise: true,
})
  .then(function (client) {
    client.setHost(options.url.split('/')[2]);

    var operation = new Operation(client);
    operation.start();
  })
  .catch(function (error) {
    console.log(error);
  });

/**
 * Used to keep track of individual load test Operation runs.
 */
var operationInstanceIndex = 0;

var results = {
  totalRequests: 0,
  meanLatencyMs: 0,
  percentiles: {},
  histogramMs: {},
  maxLatencyMs: 0,
  totalTime: 0
};

/**
 * A load test operation.
 */
var Operation = function (client, callback) {
  // self-reference
  var self = this;

  self.instanceIndex = operationInstanceIndex++;

  /**
   * Start the operation.
   */
  self.start = function() {

    // time interval to print the result
    var timer = setInterval(function () {
      console.log('Requests: %s', results.totalRequests)
    }, 2000);

    /**
     * Create a list for each user, then start the clients.
     */
    var docs = options.users.map(function(user) {
      return {'_id': user + '.123', 'name': user, 'owner': user, 'type': 'task-list'};
    });
    client.database.post_db_bulk_docs({db: options.db, body: {docs: docs}})
      .then(function(res) {
        startClients();
      })
      .catch(function(err) {
        startClients();
      });

    // time out to stop the test
    setTimeout(function () {
      clearInterval(timer);
      self.stop();
      process.exit();
    }, 6000);

  };

  /**
   * Stop clients
   */
  self.stop = function() {
    console.log('');
    console.log('Target URL:          %s', options.url);
    console.log('');
    console.log('Completed requests:  %s', results.totalRequests);
    console.log('Mean latency:        %s ms', Math.round((results.totalTime / results.totalRequests) * 10) / 10);
    console.log('');
    console.log('Percentage of the requests served within a certain time');
    results.percentiles = computePercentiles();
    Object.keys(results.percentiles).forEach(function (percentile) {
      console.log('  %s%      %s ms', percentile, results.percentiles[percentile]);
    });
  };

  /**
   * Start a number of measuring clients.
   */
  function startClients() {
    for (var i = 0; i < options.concurrency; i++) {

      makeRequest();

    }
  }

  /**
   * Send HTTP request
   */
  function makeRequest() {
    var start_time = process.hrtime();

    WriteAndReadDocument()
      .then(function () {
        results.totalRequests++;
        var hr_time = process.hrtime(start_time);
        var elapsed_time = hr_time[0] * 1000 + hr_time[1] / 1000000;
        results.totalTime += elapsed_time;
        var rounded = Math.floor(elapsed_time);
        if (rounded > results.maxLatencyMs) {
          results.maxLatencyMs = rounded;
        }
        if (!results.histogramMs[rounded]) {
          results.histogramMs[rounded] = 0;
        }
        results.histogramMs[rounded] += 1;
      })
      .then(function() {
        makeRequest();
      })
      .catch(function (err) {console.log(err)});

  }

  function GetDatabaseEndpoint () {
    return client.database.get_db({db: options.db});
  }

  function WriteAndReadDocument() {
    var user = randomUser();
    var task = {task: 'some text', complete: false, createdAt: new Date(), type: 'task', taskList: {id: user + '.123', owner: user}};
    return client.document.post({db: options.db, body: task});

    function randomUser() {
      return options.users[Math.floor(Math.random() * options.users.length)];
    }
  }

};

/**
 * Calculate percentiles
 */
function computePercentiles() {
  var percentiles = {
    50: false,
    90: false,
    95: false,
    99: false
  };
  var counted = 0;

  for (var ms = 0; ms <= results.maxLatencyMs; ms++) {
    if (!results.histogramMs[ms]) {
      continue;
    }

    counted += results.histogramMs[ms];
    var percent = counted / results.totalRequests * 100;

    Object.keys(percentiles).forEach(function(percentile) {
      if (!percentiles[percentile] && percent > percentile) {
        percentiles[percentile] = ms;
      }
    });
  }
  return percentiles;
}

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
}
