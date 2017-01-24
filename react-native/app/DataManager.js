'use strict';

import {Actions} from "react-native-router-flux";
import Couchbase from "react-native-couchbase-lite";
import Session from './Session';

global.LOGIN_FLOW_ENABLED = false;
const SYNC_ENABLED = false;
global.SG_HOST = 'localhost:4984/todo';
const USE_PREBUILT_DB = false;

const VIEWS = {
  views: {
    listsByName: {
      map: function (doc) {
        if (doc.type == 'task-list') {
          emit(doc.name, null);
        }
      }.toString()
    },
    incompleteTasksCount: {
      map: function (doc) {
        if (doc.type == 'task' && !doc.complete) {
          emit(doc.taskList.id, null);
        }
      }.toString(),
      reduce: function (keys, values, rereduce) {
        return values.length;
      }.toString()
    },
    tasksByCreatedAt: {
      map: function (doc) {
        if (doc.type == 'task') {
          emit([doc.taskList.id, doc.createdAt, doc.task], null);
        }
      }.toString()
    },
    usersByUsername: {
      map: function (doc) {
        if (doc.type == 'task-list.user') {
          emit([doc.taskList.id, doc.username], null);
        }
      }.toString()
    }
  }
};

let username;
let password;

module.exports = {
  init(client) {
    global.manager = client;
  },

  login(user, pass) {
    username = user;
    password = pass;
    this.startSession(username, password, null);
  },

  startSession(username, password) {
    global.DB_NAME = username;
    this.installPrebuiltDb(() => {
      this.startDatabaseOperations()
        .then(() => this.setupReplications(username, password))
        .then(res => Actions.lists({owner: username}));
    });
  },

  setupDatabase() {
    manager.database.put_db({db: DB_NAME})
      .then(() => this.startDatabaseOperations())
      .catch(e => console.warn(e));
  },

  installPrebuiltDb(callback) {
    if (USE_PREBUILT_DB) {
      Couchbase.installPrebuiltDatabase(DB_NAME, callback);
    } else {
      callback();
    }
  },

  startDatabaseOperations() {
    return manager.database.get_db({db: DB_NAME})
      .then(() => {
        this.setupViews();
      })
      .catch(e => {
        if (e.status == 404) {
          this.setupDatabase();
        }
      });
  },

  setupViews() {
    manager.query.get_db_design_ddoc({db: DB_NAME, ddoc: 'main'})
      .catch(e => {
        if (e.status == 404) {
          manager.query.put_db_design_ddoc({ddoc: 'main', db: DB_NAME, body: VIEWS})
            .catch(e => console.warn(e));
        }
      });
  },

  setupReplications(username, password) {
    if(SYNC_ENABLED) {
      const sgUrl = `http://${username}:${password}@${SG_HOST}`;

      return manager.server.post_replicate({body: {source: sgUrl, target: DB_NAME, continuous: true}})
        .then(res => manager.server.post_replicate({body: {source: DB_NAME, target: sgUrl, continuous: true}}))
        .catch(e => console.warn(e));
    }
  },

  stopReplications() {
    const sgUrl = `http://${username}:${password}@${SG_HOST}`;

    return manager.server.post_replicate({body: {source: sgUrl, target: DB_NAME, continuous: true, cancel: true}})
      .then(res => manager.server.post_replicate({body: {source: DB_NAME, target: sgUrl, continuous: true, cancel: true}}))
      .catch(e => console.warn(e));
  },

  logout() {
    this.stopReplications()
      .then(res => Session.deleteSyncGatewaySession(username))
    username = '';
    password = '';
    Actions.login();
  }
};
