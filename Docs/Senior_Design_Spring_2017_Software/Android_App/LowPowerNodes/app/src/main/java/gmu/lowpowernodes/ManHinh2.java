package gmu.lowpowernodes;

import android.content.Intent;
import android.os.Bundle;
import android.support.constraint.ConstraintLayout;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

public class ManHinh2 extends AppCompatActivity {

    ConstraintLayout background; // set background for screen2
    Button btnBackTo1; //set button back to first screen


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_man_hinh2);

        Toast.makeText(
                ManHinh2.this,
                "WELCOME TO OUR SECOND SCREEN",
                Toast.LENGTH_SHORT
        ).show();
        background = (ConstraintLayout)findViewById(R.id.manhinh2); // background screen 2
        background.setBackgroundResource(R.drawable.iot); // background screen 2
        btnBackTo1 = (Button)findViewById(R.id.button4); // back to first screen.
        btnBackTo1.setOnClickListener(new View.OnClickListener() {  // back to first screen.
            @Override
            public void onClick(View v) { // back to first screen.
                Intent mh1 = new Intent(ManHinh2.this, MainActivity.class); // from screen2 should be .this to screen 1 should be .class.
                startActivity(mh1);
            }
        });
    }

    String shareBody = "1"; // create a content inside a request user
    public void sharingIntent(View view) { // associate with button
        Intent sharingIntent = new Intent(Intent.ACTION_SEND); // click to button and it auto send
        sharingIntent.setType("text/html");
        sharingIntent.putExtra(android.content.Intent.EXTRA_SUBJECT, "user");
        sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT, shareBody);
        startActivity(Intent.createChooser(sharingIntent,"Share using"));
    }

/*
    Intent sharingIntent = new Intent(android.content.Intent.ACTION_SEND);
        sharingIntent.setType("text/plain");
        sharingIntent.putExtra(android.content.Intent.EXTRA_SUBJECT, "Subject Here");
        sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT, shareBody);
    startActivity(Intent.createChooser(sharingIntent, getResources().getString(R.string.share_using)));

*/



}
