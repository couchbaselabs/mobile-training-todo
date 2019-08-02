package com.couchbase.todo;

import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;


public class LoginActivity extends AppCompatActivity {
    EditText nameInput;
    EditText passwordInput;
    Button btnLogin;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        nameInput = findViewById(R.id.nameInput);
        passwordInput = findViewById(R.id.passwordInput);
        btnLogin = findViewById(R.id.btnLogin);
        btnLogin.setOnClickListener(view -> login());
    }

    private void login() {
        Application application = (Application) getApplication();
        String name = nameInput.getText().toString();
        String pass = passwordInput.getText().toString();
        application.login(name, pass);
    }
}
