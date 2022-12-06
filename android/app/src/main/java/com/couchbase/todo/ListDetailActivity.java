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
import android.content.res.Resources;
import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.viewpager2.widget.ViewPager2;

import com.google.android.material.tabs.TabLayoutMediator;

import com.couchbase.todo.tasks.GetListOwnerTask;
import com.couchbase.todo.ui.ListDetailFragmentPagerAdapter;


public class ListDetailActivity extends ToDoActivity {
    private static final String TAG = "ACT_DETAIL";

    private static final String PARAM_LIST_ID = "list_id";

    public static void start(Activity ctxt, String docId) {
        if (TextUtils.isEmpty(docId)) { throw new IllegalArgumentException("Doc id cannot be empty"); }
        final Intent intent = new Intent(ctxt, ListDetailActivity.class);
        intent.putExtra(PARAM_LIST_ID, docId);
        ctxt.startActivity(intent);
    }


    @Nullable
    private ViewPager2 viewPager;

    @Override
    protected void onCreateLoggedIn(Bundle state) {
        setContentView(R.layout.activity_list_detail);

        viewPager = findViewById(R.id.viewpager);

        new GetListOwnerTask(this::populateView).execute(getListId());
    }

    @NonNull
    public String getListId() {
        final String listId = getIntent().getStringExtra(PARAM_LIST_ID);
        if (listId == null) { throw new IllegalStateException("List id is null in Detail Activity"); }
        return listId;
    }

    void populateView(@NonNull Boolean isOwner) {
        viewPager.setAdapter(new ListDetailFragmentPagerAdapter(this, (isOwner) ? 2 : 1));

        new TabLayoutMediator(
            findViewById(R.id.sliding_tabs),
            viewPager,
            (tab, position) -> {
                final Resources rez = getResources();
                final int title;
                switch (position) {
                    case 0:
                        title = R.string.tasks;
                        break;
                    case 1:
                        title = R.string.shares;
                        break;
                    default:
                        throw new IllegalArgumentException("Page index out of bounds: " + position);
                }
                tab.setText(title);
            })
            .attach();
    }
}
