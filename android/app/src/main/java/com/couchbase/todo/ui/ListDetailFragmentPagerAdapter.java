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

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.UsersFragment;


public class ListDetailFragmentPagerAdapter extends FragmentPagerAdapter {
    private static final String TAG = "DETAILS";

    private static final List<String> TAB_NAMES;

    static {
        final List<String> l = new ArrayList<>(2);
        l.add(0, "Tasks");
        l.add(1, "Users");
        TAB_NAMES = Collections.unmodifiableList(l);
    }


    private final int pageCount;

    public ListDetailFragmentPagerAdapter(FragmentManager fm, int pageCount) {
        super(fm);
        this.pageCount = pageCount;
    }

    @Override
    public int getCount() { return pageCount; }

    @Override
    public CharSequence getPageTitle(int i) {
        if ((i < 0) || (i >= pageCount)) {
            throw new IllegalArgumentException("Page index out of bounds: " + i);
        }
        return TAB_NAMES.get(i);
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        if (position == 1) { return new UsersFragment(); }

        if (position != 0) { Log.w(TAG, "Unrecognized tab: " + position); }
        return new TasksFragment();
    }
}
