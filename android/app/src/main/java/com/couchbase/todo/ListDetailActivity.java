//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.todo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.viewpager.widget.ViewPager;

import java.util.List;

import com.google.android.material.tabs.TabLayout;

import com.couchbase.lite.Document;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.db.FetchTask;
import com.couchbase.todo.ui.ListDetailFragmentPagerAdapter;


public class ListDetailActivity extends ToDoActivity {
    private static final String TAG = "ACT_DETAIL";

    private static final String INTENT_LIST_ID = "list_id";

    public static void start(Activity ctxt, String docId) {
        if (TextUtils.isEmpty(docId)) { throw new IllegalArgumentException("Doc id cannot be empty"); }
        final Intent intent = new Intent(ctxt, ListDetailActivity.class);
        intent.putExtra(INTENT_LIST_ID, docId);
        ctxt.startActivity(intent);
    }


    private ViewPager viewPager;
    private TabLayout tabLayout;

    @NonNull
    public String getListId() {
        final String listId = getIntent().getStringExtra(INTENT_LIST_ID);
        if (listId == null) { throw new IllegalStateException("List id is null in Detail Activity"); }
        return listId;
    }

    @Override
    protected void onCreateLoggedIn(Bundle state) {
        setContentView(R.layout.activity_list_detail);

        viewPager = findViewById(R.id.viewpager);
        tabLayout = findViewById(R.id.sliding_tabs);

        new FetchTask(this::populateView).execute(getListId(), "moderator." + DAO.get().getUsername());
    }

    void populateView(List<Document> docs) {
        final String username = DAO.get().getUsername();
        final Document taskList = docs.get(0);
        final Document moderator = docs.get(1);

        if (taskList == null) { return; }

        final ListDetailFragmentPagerAdapter pageAdapter = new ListDetailFragmentPagerAdapter(
            getSupportFragmentManager(),
            (taskList.getString("owner").equals(username) || (moderator != null)) ? 2 : 1);

        viewPager.setAdapter(pageAdapter);

        // Give the TabLayout the ViewPager
        tabLayout.setupWithViewPager(viewPager);
    }
}
