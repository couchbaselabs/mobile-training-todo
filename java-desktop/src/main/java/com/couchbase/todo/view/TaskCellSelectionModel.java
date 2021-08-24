package com.couchbase.todo.view;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.control.MultipleSelectionModel;

import com.couchbase.todo.model.Task;


public class TaskCellSelectionModel extends MultipleSelectionModel<Task> {

    @Override
    public ObservableList<Integer> getSelectedIndices() {
        return FXCollections.emptyObservableList();
    }

    @Override
    public ObservableList<Task> getSelectedItems() {
        return FXCollections.emptyObservableList();
    }

    @Override
    public void selectIndices(int i, int... ints) { }

    @Override
    public void selectAll() { }

    @Override
    public void selectFirst() { }

    @Override
    public void selectLast() { }

    @Override
    public void clearAndSelect(int i) { }

    @Override
    public void select(int i) { }

    @Override
    public void select(Task task) { }

    @Override
    public void clearSelection(int i) { }

    @Override
    public void clearSelection() { }

    @Override
    public boolean isSelected(int i) { return false; }

    @Override
    public boolean isEmpty() { return true; }

    @Override
    public void selectPrevious() { }

    @Override
    public void selectNext() { }

}
