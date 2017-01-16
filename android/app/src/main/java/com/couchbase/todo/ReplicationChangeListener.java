package com.couchbase.todo;

import android.content.Context;
import android.util.Log;

import com.couchbase.lite.replicator.RemoteRequestResponseException;
import com.couchbase.lite.replicator.Replication;

class ReplicationChangeListener implements Replication.ChangeListener {

    private Application application;

    ReplicationChangeListener(Application application) {
        this.application = application;
    }

    @Override
    public void changed(Replication.ChangeEvent event) {
        if (event.getError() != null) {
            Throwable lastError = event.getError();
            Log.d(Application.TAG, String.format("Replication Error: %s", lastError.getMessage()));
            if (lastError instanceof RemoteRequestResponseException) {
                RemoteRequestResponseException exception = (RemoteRequestResponseException) lastError;
                if (exception.getCode() == 401) {
                    application.showErrorMessage("Your username or password is not correct.", null);
                    application.logout();
                }
            }
        }
    }
}
