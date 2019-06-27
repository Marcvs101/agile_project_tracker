package com.example.agileprojecttracker;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.functions.FirebaseFunctions;

public class HomepageActivity extends AppCompatActivity {

    private FirebaseFunctions mFunctions;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_homepage);

        mFunctions = FirebaseFunctions.getInstance();

    }
}
