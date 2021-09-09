<template>
  <div>
    <v-tabs background-color="white" color="light-blue accent-4" left>
      <v-tab :to="{ name: 'tasks' }">TASKS</v-tab>
      <v-tab :to="{ name: 'users' }">USERS</v-tab>
    </v-tabs>
    <span> Refresh browser to get all updates from the database </span>
    <router-view/>
  </div>
</template>

<script>
export default {
  data() {
    return {};
  }
};
</script>

<style scoped></style>
