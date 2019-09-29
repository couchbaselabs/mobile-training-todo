import Vue from "vue";
import Router from "vue-router";
import Login from "@/views/Login.vue";
import Home from "@/views/Home.vue";
import TaskList from "@/views/TaskList.vue";
import Tasks from "@/views/Tasks.vue";
import Users from "@/views/Users.vue";

Vue.use(Router);

export default new Router({
  mode: "history",
  routes: [
    {
      path: "/",
      name: "home",
      component: Home,
      alias: "/lists",
      children: [
        {
          path: "lists/:id",
          component: TaskList,
          children: [
            { path: "tasks", name: "tasks", component: Tasks },
            { path: "users", name: "users", component: Users }
          ]
        }
      ]
    },
    {
      path: "/login",
      name: "login",
      component: Login
    }
  ]
});
