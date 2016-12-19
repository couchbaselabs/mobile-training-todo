package com.couchbase.todo;

import android.os.Bundle;
import android.support.design.widget.TabLayout;
import android.support.v4.view.ViewPager;
import android.support.v7.app.AppCompatActivity;

import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.todo.util.ListFragmentPagerAdapter;

public class ListDetailActivity extends AppCompatActivity {

    public static final String INTENT_LIST_ID = "list_id";

    private static final int REQUEST_TAKE_PHOTO = 1;
    private static final int REQUEST_CHOOSE_PHOTO = 2;
    private static final int THUMBNAIL_SIZE = 150;

    private Database mDatabase;
    private Document mTaskList;
    private String mUsername;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list_detail);

        Application application = (Application)getApplication();
        mDatabase = application.getDatabase();
        mUsername = application.getUsername();
        mTaskList = mDatabase.getDocument(getIntent().getStringExtra(INTENT_LIST_ID));

        int tabCount = (isOwner() || hasModeratorAccess()) ? 2 : 1;

        // Get the ViewPager and set it's PagerAdapter so that it can display items
        ViewPager viewPager = (ViewPager) findViewById(R.id.viewpager);
        viewPager.setAdapter(new ListFragmentPagerAdapter(getSupportFragmentManager(), tabCount));

        // Give the TabLayout the ViewPager
        TabLayout tabLayout = (TabLayout) findViewById(R.id.sliding_tabs);
        tabLayout.setupWithViewPager(viewPager);
    }

    private boolean isOwner()
    {
        return mTaskList.getProperty("owner").equals(mUsername);
    }

    private boolean hasModeratorAccess()
    {
        return mDatabase.getExistingDocument("moderator." + mUsername) != null;
    }

}