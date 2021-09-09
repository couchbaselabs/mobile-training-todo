<template>
  <v-app>
    <v-app-bar app flat clipped-left color="light-blue lighten-4">
      <v-app-bar-nav-icon @click.stop="drawer = !drawer"></v-app-bar-nav-icon>
      <v-toolbar-title
          class="headline text-uppercase light-blue--text text--darken-4"
      >
        <span class="font-weight-light">Todo</span>
      </v-toolbar-title>
      <div class="flex-grow-1"></div>
      <v-btn icon @click="logout">
        <v-icon>mdi-logout</v-icon>
      </v-btn>
    </v-app-bar>
    <v-navigation-drawer
        app
        clipped
        floating
        color="grey lighten-4"
        v-model="drawer"
    >
      <Lists/>
    </v-navigation-drawer>
    <v-content class="white">
      <span id="refresh"> Refresh browser to get all updates from database </span>
      <router-view/>
      <v-snackbar v-model="alert" bottom color="blue">
        {{ alertMessage }}
        <v-btn color="white" text @click="alert = false">Close</v-btn>
      </v-snackbar>
    </v-content>
  </v-app>
</template>
<script>
import event from "@/event.js";
import TodoService from "@/services/TodoService.js";

import Lists from "@/components/Lists.vue";

export default {
  components: {
    Lists
  },
  data() {
    return {
      drawer: true,
      alert: false,
      alertMessage: ""
    };
  },
  mounted() {
    event.$on("ws-error", info => {
      let error = info.error;
      let message = info.when + ", " + error.message;
      if (error.response && error.response.status === 401) {
        this.$router.push({name: "login"});
      } else {
        this.alertMessage = message;
        this.alert = true;
      }
    });
  },
  methods: {
    logout: function () {
      TodoService.logout()
          .then(() => {
            this.$router.push({name: "login"});
          })
          .catch(error => {
            event.$emit("ws-error", {error, when: "Logout"});
          });
    }
  }
};

</script>

<style>
#refresh {
  margin-left: 10px;
  margin-top: 10px;
}
</style>