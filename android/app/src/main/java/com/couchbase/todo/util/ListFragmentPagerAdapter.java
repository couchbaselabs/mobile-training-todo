package com.couchbase.todo.util;

import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;

import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.UsersFragment;

public class ListFragmentPagerAdapter extends FragmentPagerAdapter {
    final int PAGE_COUNT;
    private String tabTitles[] = new String[]{"Tasks", "Users"};

    public ListFragmentPagerAdapter(FragmentManager fm, int tabCount) {
        super(fm);

        PAGE_COUNT = tabCount;
    }

    @Override
    public int getCount() {
        return PAGE_COUNT;
    }

    @Override
    public Fragment getItem(int position) {
        switch (position) {
            case 0:
                return new TasksFragment();
            case 1:
                return new UsersFragment();
            default:
                return null;
        }
    }

    @Override
    public CharSequence getPageTitle(int position) {
        // Generate title based on item position
        return tabTitles[position];
    }
}
