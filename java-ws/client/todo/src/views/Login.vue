<template>
  <v-app>
    <v-content>
      <v-container fluid fill-height>
        <v-layout align-center justify-center>
          <v-flex xs12 sm8 md4>
            <v-card>
              <v-toolbar color="light blue" dark flat>
                <v-toolbar-title>Login</v-toolbar-title>
              </v-toolbar>
              <v-card-text>
                <v-form>
                  <v-text-field
                    v-model="username"
                    label="Username"
                    name="login"
                    prepend-icon="mdi-account-circle"
                    type="text"
                  ></v-text-field>
                  <v-text-field
                    v-model="password"
                    id="password"
                    label="Password"
                    name="password"
                    prepend-icon="mdi-lock"
                    type="password"
                  ></v-text-field>
                </v-form>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="light blue" class="mr-2 mb-2" dark @click="login">
                  Login
                </v-btn>
              </v-card-actions>
            </v-card>
            <v-snackbar v-model="alert" bottom color="blue">
              {{ alertMessage }}
              <v-btn color="white" text @click="alert = false">Close</v-btn>
            </v-snackbar>
          </v-flex>
        </v-layout>
      </v-container>
    </v-content>
  </v-app>
</template>

<script>
import TodoService from "@/services/TodoService.js";

export default {
  data() {
    return {
      username: "",
      password: "",
      alert: false,
      alertMessage: ""
    };
  },

  beforeRouteEnter(to, from, next) {
    TodoService.logout()
      .then(() => {
        next();
      })
      .catch(error => {
        console.log("Error when logging out: " + error.message);
      });
  },

  methods: {
    login: function() {
      let user = { name: this.username, password: this.password };
      TodoService.login(user)
        .then(() => {
          this.$router.push({ name: "home" });
        })
        .catch(error => {
          this.alert = true;
          this.alertMessage = "Login " + error.message;
        });
    }
  }
};
</script>

<style scoped></style>
