package com.example.agileprojecttracker;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import android.graphics.Bitmap;
import android.graphics.Color;

import android.os.Bundle;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import org.json.*;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.snackbar.Snackbar;

import com.google.firebase.functions.FirebaseFunctions;
import com.google.firebase.functions.FirebaseFunctionsException;
import com.google.firebase.functions.HttpsCallableResult;

import java.util.Iterator;


public class HomepageActivity extends AppCompatActivity {

    private FirebaseFunctions mFunctions;
    private static final String TAG = "HomepageActivity";

    private LinearLayout contenitore;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_homepage);

        contenitore = (LinearLayout) findViewById(R.id.layout_progetto);
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
        String nome = "";
        String id = "";
        String descrizione = "";
        String proprietario = "";
        boolean completato = false;

        try {
            Log.w("data:",data);
            JSONObject json = new JSONObject(data);
            JSONObject arr = json.getJSONObject("project");
            Iterator<String> keys = arr.keys();
            while(keys.hasNext()){
                id = keys.next();
                if(arr.get(id) instanceof JSONObject){
                    nome = ((JSONObject) arr.get(id)).getString("nome");
                    descrizione = ((JSONObject) arr.get(id)).getString("descrizione");
                    proprietario = ((JSONObject) arr.get(id)).getString("proprietario");
                    completato = ((JSONObject) arr.get(id)).getBoolean("completato");
                }

                CardView card = new CardView(contenitore.getContext());
                LinearLayout ll = new LinearLayout(card.getContext());

                ImageView im = new ImageView(ll.getContext());
                Bitmap bp = Bitmap.createBitmap(1,1, Bitmap.Config.ARGB_8888);
                if(completato) bp.setPixel(0,0, Color.argb(100,76,175,80));
                else bp.setPixel(0,0, Color.argb(100,170,170,170));
                im.setImageBitmap(bp);
                im.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,90));

                TextView titolo = new TextView(ll.getContext());
                titolo.setText(nome);
                titolo.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

                TextView descr = new TextView(ll.getContext());
                descr.setText(descrizione);
                descr.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

                TextView prop = new TextView(ll.getContext());
                prop.setText(proprietario);
                prop.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

    }

    private Task<String> getProjects(){

        return mFunctions.getHttpsCallable("GetProjectsForUser").call().continueWith(new Continuation<HttpsCallableResult, String>() {

            @Override
            public String then(@NonNull Task<HttpsCallableResult> task) throws Exception {
                //ricezione dati json (in caso di fallimento 'getResult' dà eccezione
                String result = task.getResult().getData().toString();
                return result;
            }
        });
    }
}
