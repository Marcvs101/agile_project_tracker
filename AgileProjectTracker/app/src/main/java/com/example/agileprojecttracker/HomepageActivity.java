package com.example.agileprojecttracker;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;

import org.json.*;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.snackbar.Snackbar;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.functions.FirebaseFunctions;
import com.google.firebase.functions.FirebaseFunctionsException;
import com.google.firebase.functions.HttpsCallableResult;



public class HomepageActivity extends AppCompatActivity {

    private FirebaseFunctions mFunctions;
    private static final String TAG = "HomepageActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_homepage);

        mFunctions = FirebaseFunctions.getInstance();

        getProjects().addOnCompleteListener(new OnCompleteListener<String>() {
            @Override
            public void onComplete(@NonNull Task<String> task) {
                if( !task.isSuccessful()){
                    Exception e = task.getException();
                    if(e instanceof FirebaseFunctionsException){
                        FirebaseFunctionsException ffe = (FirebaseFunctionsException) e;
                        FirebaseFunctionsException.Code code = ffe.getCode();
                        Object details = ffe.getDetails();
                    }
                    Log.w(TAG,"getProject:onFailure",e);
                    showSnackbar("An error occurred");
                    return;
                }

                String result = task.getResult();
                displayProjects(result);
            }
        });

    }

    private void showSnackbar(String messaggio){
        Snackbar.make(findViewById(android.R.id.content),messaggio,Snackbar.LENGTH_SHORT).show();
    }

    private void displayProjects(String data){

    }

    private Task<String> getProjects(){

        return mFunctions.getHttpsCallable("getProjectsForUser").call().continueWith(new Continuation<HttpsCallableResult, String>() {

            @Override
            public String then(@NonNull Task<HttpsCallableResult> task) throws Exception {
                //ricezione dati json (in caso di fallimento 'getResult' dà eccezione
                String result = (String) task.getResult().getData();
                return result;
            }
        });
    }
}
