<template>
  <div>
    <v-dialog v-model="dialog" persistent max-width="600px">
      <template v-slot:activator="{ on }">
        <v-container class="">
          <v-row>
            <v-col>
              <v-btn tile outlined color="blue" v-on="on" class="ml-3">
                <v-icon>mdi-plus</v-icon>
                CREATE TASK LIST
              </v-btn>
            </v-col>
          </v-row>
        </v-container>
      </template>
      <v-card>
        <v-card-text>
          <v-container class="pa-0">
            <v-row>
              <v-col cols="12">
                <v-text-field
                  v-model="newListName"
                  label="Enter your list name"
                  required
                  hide-details
                ></v-text-field>
              </v-col>
            </v-row>
          </v-container>
        </v-card-text>
        <v-card-actions>
          <div class="flex-grow-1"></div>
          <v-btn color="blue darken-1" text @click="dialog = false">
            Close
          </v-btn>
          <v-btn color="blue darken-1" text @click="createTaskList">
            Save
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-list>
      <v-list-item-group :value="1" mandatory color="blue">
        <v-list-item
          v-for="list in lists"
          :key="list.id"
          :to="{ name: 'tasks', params: { id: list.id } }"
        >
          <v-list-item-content>
            <v-list-item-title>
              {{ list.name }}
            </v-list-item-title>
          </v-list-item-content>
        </v-list-item>
      </v-list-item-group>
    </v-list>
  </div>
</template>

<script>
import TodoService from "@/services/TodoService.js";
import event from "@/event.js";

export default {
  data() {
    return {
      newListName: "",
      dialog: false,
      lists: []
    };
  },
  created() {
    TodoService.getTaskLists()
      .then(response => {
        this.lists = response.data;
      })
      .catch(error => {
        event.$emit("ws-error", { error, when: "Get Task Lists" });
      });
  },
  methods: {
    createTaskList: function() {
      if (!this.newListName) return;
      var list = { name: this.newListName };
      TodoService.createTaskList(list)
        .then(response => {
          list.id = response.data.id;
          this.lists.push(list);
        })
        .catch(error => {
          event.$emit("ws-error", { error, when: "Create Task List" });
        });
      this.dialog = false;
      this.newListName = "";
    }
  }
};
</script>

<style scoped></style>
