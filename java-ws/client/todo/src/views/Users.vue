<template>
  <div>
    <v-card max-width="800" class="mx-auto mt-8 pb-1" flat>
      <v-text-field
        label="Enter a username"
        filled
        single-line
        clearable
        hide-details
        v-model="newUser"
        @keyup.enter="addUser"
      ></v-text-field>
    </v-card>

    <v-card max-width="800" class="mx-auto mt-4" flat>
      <v-list>
        <template v-for="(user, index) in users">
          <v-list-item :key="user.id">
            <v-list-item-content>
              <v-list-item-title>
                {{ user.name }}
              </v-list-item-title>
            </v-list-item-content>
            <v-list-item-action>
              <v-btn icon @click="deleteUser(user)">
                <v-icon>mdi-close</v-icon>
              </v-btn>
            </v-list-item-action>
          </v-list-item>
          <v-divider :key="index"></v-divider>
        </template>
      </v-list>
    </v-card>
  </div>
</template>

<script>
import TodoService from "@/services/TodoService.js";

export default {
  data() {
    return {
      newUser: "",
      users: []
    };
  },

  created() {
    this.getUsers();
  },

  watch: {
    "$route.params.id": function() {
      this.getUsers();
    }
  },

  methods: {
    addUser: function() {
      if (!this.newUser) return;
      var taskListId = this.$route.params.id;
      var user = { name: this.newUser };
      TodoService.addUser(taskListId, user)
        .then(() => {
          this.getUsers();
        })
        .catch(error => {
          console.log("There was an error: " + error.response);
        });
      this.newUser = "";
    },

    deleteUser: function(user) {
      var taskListId = this.$route.params.id;
      var userId = user.id;
      TodoService.deleteUser(taskListId, userId)
        .then(() => {
          this.getUsers();
        })
        .catch(error => {
          console.log("There was an error: " + error.response);
        });
    },

    getUsers: function() {
      var taskListId = this.$route.params.id;
      TodoService.getUsers(taskListId)
        .then(response => {
          this.users = response.data;
          console.log(JSON.stringify(this.users));
        })
        .catch(error => {
          console.log("There was an error: " + error.response);
        });
    }
  }
};
</script>

<style scoped></style>
