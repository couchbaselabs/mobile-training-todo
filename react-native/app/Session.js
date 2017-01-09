'use strict';

import Swagger from 'swagger-client';
import spec from './sync-gateway-spec.json';

let manager;

module.exports = {
  createSyncGatewaySession(user, pass) {
    spec.host = SG_HOST.split('/')[0];
    return new Swagger({spec: spec, usePromise: true})
      .then(client => {
        manager = client;
        return manager;
      })
      .then(client => {
        return client.session.post_db_session({db: 'todo', SessionBody: {name: user, password: pass}});
      });
  },
  deleteSyncGatewaySession(user) {
    spec.host = SG_HOST.split('/')[0];
    return manager.session.delete_db_session({db: 'todo'})
      .then(res => console.log(res.obj))
      .catch(e => console.warn(e));
  }
};
