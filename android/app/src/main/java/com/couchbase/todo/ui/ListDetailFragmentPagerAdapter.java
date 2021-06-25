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

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.couchbase.todo.R;
import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.UsersFragment;
import com.couchbase.todo.app.ToDo;

public class ListDetailFragmentPagerAdapter extends FragmentPagerAdapter {
    private static final String TAG = "DETAILS";


    private final int pageCount;

    public ListDetailFragmentPagerAdapter(FragmentManager fm, int pageCount) {
        super(fm, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT);
        this.pageCount = pageCount;
    }

    @Override
    public int getCount() { return pageCount; }

    @Override
    public CharSequence getPageTitle(int i) {
        Context ctxt = ToDo.getAppContext();
        switch (i) {
            case 0:
                return ctxt.getResources().getString(R.string.tasks);
            case 1:
                return ctxt.getResources().getString(R.string.shares);
            default:
                throw new IllegalArgumentException("Page index out of bounds: " + i);
        }
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        if (position == 1) { return new UsersFragment(); }

        if (position != 0) { Log.w(TAG, "Unrecognized tab: " + position); }
        return new TasksFragment();
    }
}
