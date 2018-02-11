package gmu.lowpowernodes;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.support.constraint.ConstraintLayout;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import java.io.File;
import java.util.List;

public class MainActivity extends AppCompatActivity {

    ConstraintLayout background; // variable for background screen.
    Button user; // variable for jump to second screen.
/*
// variable for dropbox button cloud
    static final String APP_KEY = "ozxd1463h544pcn";
    static final int DBX_CHOOSER_REQUEST = 0;  // You can change this if needed
    private Button mChooserButton;
    private DbxChooser mChooser;
*/


//    static final String APP_KEY = "ozxd1463h544pcn";


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
// pop up a welcome greeting
        Toast.makeText(
                MainActivity.this,
                "WELCOME TO OUR SENIOR DESIGN APP",
                Toast.LENGTH_SHORT
        ).show();

        background = (ConstraintLayout)findViewById(R.id.main);// set variable to id main
        background.setBackgroundResource(R.drawable.gmu); // set background pictures
        user = (Button) findViewById(R.id.button3);// set variable to id button3
        user.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent mh2 = new Intent(MainActivity.this, ManHinh2.class); // move to main screen to second screen.
                startActivity(mh2);
            }
        });
 /*
// click to choose dropbox app. If it doesnt install, It will send to play store to install it
        mChooser = new DbxChooser(APP_KEY);
        mChooserButton = (Button) findViewById(R.id.button2);
        mChooserButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mChooser.forResultType(DbxChooser.ResultType.PREVIEW_LINK)
                        .launch(MainActivity.this, DBX_CHOOSER_REQUEST);
            }
        });
*/

    }



    // Launch QR CODE after clicking the button
    public void SETUP(View view) {
        Intent SETUP = getPackageManager().getLaunchIntentForPackage("la.droid.qr");
        SETUP.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(SETUP);
    }


    // Launch QR CODE after clicking the button
    public void CLOUD(View view) {
        Intent CLOUD = getPackageManager().getLaunchIntentForPackage("com.dropbox.android");
        CLOUD.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(CLOUD);
    }

    public Intent findDropBox() {
        final String[] twitterApps = {
                "com.dropbox.android" };
        Intent tweetIntent = new Intent();
        tweetIntent.setType("text/plain");
        final PackageManager packageManager = getPackageManager();
        List<ResolveInfo> list = packageManager.queryIntentActivities(
                tweetIntent, PackageManager.MATCH_DEFAULT_ONLY);

        for (int i = 0; i < twitterApps.length; i++) {
            for (ResolveInfo resolveInfo : list) {
                String p = resolveInfo.activityInfo.packageName;
                if (p != null && p.startsWith(twitterApps[i])) {
                    tweetIntent.setPackage(p);
                    return tweetIntent;
                }
            }
        }

        return null;
    }


/*
    String shareBody = "1"; // create a content inside a request user
    public void sharingIntent(View view) { // associate with button
        Intent sharingIntent = findDropBox(); // click to button and it automatically send
        sharingIntent.setType("text/html"); // define
        sharingIntent.putExtra(android.content.Intent.EXTRA_SUBJECT, "user");
        sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT, shareBody); // send a any contain in file
        startActivity(Intent.createChooser(sharingIntent,"Share using"));
    }
*/


    public void sharingIntent(View view) {
        File file = new File(Environment.getExternalStorageDirectory().toString() + "/" + "user.txt"); //
        Intent sharingIntent = new Intent(Intent.ACTION_SEND);
        sharingIntent.setType("text/html");
        sharingIntent.putExtra(Intent.EXTRA_STREAM, Uri.parse("file://" + file.getAbsolutePath()));
        startActivity(Intent.createChooser(sharingIntent, "share file with Dropbox please"));
    }

    public void checkStatus(View view){

        File file = new File(Environment.getExternalStorageDirectory().toString() + "/VIP/" + "user.txt"); //
        Intent checkStatus = new Intent(Intent.ACTION_SEND);
        checkStatus.setType("text/html");
        checkStatus.putExtra(Intent.EXTRA_STREAM, Uri.parse("file://" + file.getAbsolutePath()));
        startActivity(Intent.createChooser(checkStatus, "share file with Dropbox please"));



    }




}
