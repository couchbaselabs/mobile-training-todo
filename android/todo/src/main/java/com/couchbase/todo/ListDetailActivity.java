package com.couchbase.todo;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.viewpager.widget.ViewPager;

import com.google.android.material.tabs.TabLayout;

import com.couchbase.lite.Database;
import com.couchbase.lite.Document;

public class ListDetailActivity extends AppCompatActivity {

    private Database db;
    private Document taskList;
    private String username;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list_detail);

        db = ((Application) getApplication()).getDatabase();
        taskList = db.getDocument(getIntent().getStringExtra(ListsActivity.INTENT_LIST_ID));
        username = ((Application) getApplication()).getUsername();

        int tabCount = (isOwner() || hasModeratorAccess()) ? 2 : 1;

        ViewPager viewPager = findViewById(R.id.viewpager);
        viewPager.setAdapter(new ListDetailFragmentPagerAdapter(getSupportFragmentManager(), tabCount));

        // Give the TabLayout the ViewPager
        TabLayout tabLayout = findViewById(R.id.sliding_tabs);
        tabLayout.setupWithViewPager(viewPager);
    }

    private boolean isOwner() {
        return taskList.getString("owner").equals(username);
    }

    private boolean hasModeratorAccess() {
        return db.getDocument("moderator." + username) != null;
    }
}
