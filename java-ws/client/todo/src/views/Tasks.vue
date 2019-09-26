<template>
  <div>
    <v-card flat class="mt-4 mx-4">
      <v-container fluid class="pa-0 mx">
        <v-row>
          <v-col>
            <v-text-field
              label="What needs to be done?"
              filled
              single-line
              clearable
              hide-details
              class="mx-10"
              v-model="newTask"
              @keyup.enter="createTask"
            ></v-text-field>
          </v-col>
        </v-row>
      </v-container>
    </v-card>
    <v-card flat class="mx-12">
      <input
        type="file"
        ref="fileInput"
        accept="image/*"
        style="display: none;"
        @change="selectTaskImageFile()"
      />
      <v-list flat>
        <template v-for="(task, index) in tasks">
          <v-list-item :key="task.id">
            <v-list-item-action>
              <v-checkbox
                v-model="task.complete"
                @change="completeTask(task)"
                hide-details
              />
            </v-list-item-action>
            <v-list-item-icon
              width="75"
              height="75"
              :style="{ cursor: 'pointer' }"
              @click="showTaskImageMenu(task, $event)"
            >
              <v-img
                v-if="task.image"
                :src="getTaskImageUrl(task)"
                width="75"
                height="75"
              ></v-img>
              <v-img
                v-else
                src="https://via.placeholder.com/150"
                width="75"
                height="75"
              ></v-img>
            </v-list-item-icon>
            <v-list-item-content>
              <v-list-item-title
                class="ml-5"
                @dblclick="openEditTaskDialog(task)"
              >
                {{ task.task }}
              </v-list-item-title>
            </v-list-item-content>
            <v-list-item-action>
              <v-btn icon @click="deleteTask(task)">
                <v-icon>mdi-close</v-icon>
              </v-btn>
            </v-list-item-action>
          </v-list-item>
          <v-divider :key="index"></v-divider>
        </template>
      </v-list>
    </v-card>
    <v-dialog v-model="editTaskDialog" persistent max-width="600px">
      <v-card>
        <v-card-text>
          <v-container class="pa-0">
            <v-row>
              <v-col cols="12">
                <v-text-field
                  v-model="editTask.task"
                  label="What needs to be done?"
                  required
                  hide-details
                ></v-text-field>
              </v-col>
            </v-row>
          </v-container>
        </v-card-text>
        <v-card-actions>
          <div class="flex-grow-1"></div>
          <v-btn color="blue darken-1" text @click="closeEditTaskDialog">
            Close
          </v-btn>
          <v-btn color="blue darken-1" text @click="saveEditTask">
            Save
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-menu
      v-model="imageMenu"
      :position-x="imageMenuX"
      :position-y="imageMenuY"
      absolute
      offset-y
    >
      <v-list>
        <v-list-item @click="openTaskImageDialog()">
          <v-list-item-title>Update</v-list-item-title>
        </v-list-item>
        <v-list-item @click="deleteTaskImage()" v-if="imageTask.image">
          <v-list-item-title>Delete</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-menu>
  </div>
</template>

<script>
import TodoService from "@/services/TodoService.js";
import event from "@/event.js";

export default {
  data() {
    return {
      newTask: "",
      editTask: {},
      editTaskDialog: false,
      tasks: [],
      imageTask: {},
      imageMenu: false,
      imageMenuX: 0,
      imageMenuY: 0
    };
  },

  created() {
    this.getTasks();
  },

  watch: {
    "$route.params.id": function() {
      this.getTasks();
    }
  },

  methods: {
    createTask: function() {
      if (!this.newTask) return;
      let taskListId = this.$route.params.id;
      let task = { task: this.newTask, complete: false };
      TodoService.createTask(taskListId, task)
        .then(() => {
          this.getTasks();
        })
        .catch(error => {
          event.$emit("ws-error", { error, when: "Create Task" });
        });
      this.newTask = "";
    },

    openEditTaskDialog: function(task) {
      this.editTask = task;
      this.editTaskDialog = true;
    },

    closeEditTaskDialog: function() {
      this.editTask = {};
      this.editTaskDialog = false;
    },

    saveEditTask: function() {
      let taskListId = this.$route.params.id;
      let taskId = this.editTask.id;
      let updateTask = {
        task: this.editTask.task,
        complete: this.editTask.complete
      };
      TodoService.updateTask(taskListId, taskId, updateTask).catch(error => {
        event.$emit("ws-error", { error, when: "Update Task" });
      });
      this.closeEditTaskDialog();
    },

    completeTask: function(task) {
      let taskListId = this.$route.params.id;
      let taskId = task.id;
      let updateTask = { task: task.task, complete: task.complete };
      TodoService.updateTask(taskListId, taskId, updateTask).catch(error => {
        event.$emit("ws-error", { error, when: "Toggle Complete Task" });
      });
    },

    deleteTask: function(task) {
      let taskListId = this.$route.params.id;
      let taskId = task.id;
      TodoService.deleteTask(taskListId, taskId)
        .then(() => {
          this.getTasks();
        })
        .catch(error => {
          event.$emit("ws-error", { error, when: "Delete Task" });
        });
    },

    getTasks: function() {
      let taskListId = this.$route.params.id;
      TodoService.getTasks(taskListId)
        .then(response => {
          this.tasks = response.data;
        })
        .catch(error => {
          event.$emit("ws-error", { error, when: "Get Tasks" });
        });
    },

    openTaskImageDialog: function() {
      this.$refs.fileInput.click();
    },

    selectTaskImageFile: function() {
      let files = this.$refs.fileInput.files;
      if (files.length > 0) {
        let taskListId = this.$route.params.id;
        let taskId = this.imageTask.id;
        var imageFile = files[0];
        TodoService.updateTaskImage(taskListId, taskId, imageFile)
          .then(() => {
            this.getTasks();
          })
          .catch(error => {
            event.$emit("ws-error", { error, when: "Update Task Image" });
          });
      }
      this.imageTask = {};
    },

    deleteTaskImage: function() {
      let taskListId = this.$route.params.id;
      let taskId = this.imageTask.id;
      TodoService.deleteTaskImage(taskListId, taskId)
        .then(() => {
          this.getTasks();
        })
        .catch(error => {
          event.$emit("ws-error", { error, when: "Delete Task Image" });
        });
      this.imageTask = {};
    },

    getTaskImageUrl: function(task) {
      let taskListId = this.$route.params.id;
      let taskId = task.id;
      return TodoService.getTaskImageURL(taskListId, taskId);
    },

    showTaskImageMenu: function(task, e) {
      e.preventDefault();
      this.imageMenu = false;
      this.imageMenuX = e.clientX;
      this.imageMenuY = e.clientY;
      this.imageTask = {};
      this.$nextTick(() => {
        this.imageTask = task;
        this.imageMenu = true;
      });
    }
  }
};
</script>

<style scoped></style>
