package com.couchbase.todo;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.support.annotation.NonNull;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.app.LoaderManager.LoaderCallbacks;

import android.content.CursorLoader;
import android.content.Loader;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;

import android.os.Build;
import android.os.Bundle;
import android.provider.ContactsContract;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.EditorInfo;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.couchbase.lite.Manager;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import static android.Manifest.permission.READ_CONTACTS;

public class LoginActivity extends AppCompatActivity {

    EditText nameInput;
    EditText passwordInput;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        nameInput = (EditText) findViewById(R.id.nameInput);
        passwordInput = (EditText) findViewById(R.id.passwordInput);
    }

    public void login(View view) {
        Application application = (Application) getApplication();

        String name = nameInput.getText().toString();
        String pass = passwordInput.getText().toString();

        // Since we are naming the database as the user name, make sure it is a valid db name
        if(!Manager.isValidDatabaseName(name)) {
            showToast("Make sure user name is not empty and is a valid database name");
            return;
        }

        if(pass.length() == 0) {
            showToast("Make sure the password is not empty");
            return;
        }

        application.login(name, pass);
    }

    private void showToast(String text) {
        Context context = getApplicationContext();
        int duration = Toast.LENGTH_SHORT;
        Toast toast = Toast.makeText(context, text, duration);
        toast.show();
    }
}

