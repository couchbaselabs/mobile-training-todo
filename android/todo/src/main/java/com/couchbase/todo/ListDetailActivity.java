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

import android.os.Bundle;

import androidx.viewpager.widget.ViewPager;

import com.google.android.material.tabs.TabLayout;

import com.couchbase.lite.Document;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.ui.ListDetailFragmentPagerAdapter;


public class ListDetailActivity extends ToDoActivity {
    private Document taskList;
    private String username;
    private ListDetailFragmentPagerAdapter pageAdapter;

    @Override
    protected void onCreateLoggedIn(Bundle state) {
        setContentView(R.layout.activity_list_detail);

        taskList = DAO.get().fetchDocument(getIntent().getStringExtra(ListsActivity.INTENT_LIST_ID));
        username = DAO.get().getUsername();

        pageAdapter = new ListDetailFragmentPagerAdapter(
            getSupportFragmentManager(),
            (isOwner() || hasModeratorAccess()) ? 2 : 1);

        ViewPager viewPager = findViewById(R.id.viewpager);
        viewPager.setAdapter(pageAdapter);

        // Give the TabLayout the ViewPager
        ((TabLayout) findViewById(R.id.sliding_tabs)).setupWithViewPager(viewPager);
    }

    private boolean isOwner() {
        return taskList.getString("owner").equals(username);
    }

    private boolean hasModeratorAccess() {
        return DAO.get().fetchDocument("moderator." + username) != null;
    }
}
