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
package com.couchbase.todo.ui;

import android.util.Log;

import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.UsersFragment;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;


public class ListDetailFragmentPagerAdapter extends FragmentPagerAdapter {
    private static final String TAG = "DETAILS";
    private static final String[] TABS = new String[] {"Tasks", "Users"};

    private final int pageCount;

    public ListDetailFragmentPagerAdapter(FragmentManager fm, int pageCount) {
        super(fm);
        this.pageCount = pageCount;
    }

    @Override
    public CharSequence getPageTitle(int position) { return TABS[position]; }

    @Override
    public int getCount() { return pageCount; }

    @Override
    public Fragment getItem(int position) {
        if (position == 1) { return new UsersFragment(); }
        else {
            if (position != 0) { Log.w(TAG, "Unrecognize tab: " + position); }
            return new TasksFragment();
        }
    }
}
