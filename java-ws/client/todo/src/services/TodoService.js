import axios from "axios";

const baseURL = "http://localhost:8080/todo";

const service = axios.create({
  baseURL: baseURL,
  withCredentials: true,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json"
  }
});

export default {
  login(user) {
    return service.post("/login", user);
  },

  logout() {
    return service.post("logout");
  },

  createTaskList(list) {
    return service.post("/lists", list);
  },

  deleteTaskList(taskListId) {
    return service.delete("/lists/" + taskListId);
  },

  getTaskLists() {
    return service.get("/lists");
  },

  createTask(taskListId, task) {
    return service.post("/lists/" + taskListId + "/tasks", task);
  },

  updateTask(taskListId, taskId, task) {
    return service.put("/lists/" + taskListId + "/tasks/" + taskId, task);
  },

  updateTaskImage(taskListId, taskId, imageFile) {
    let formData = new FormData();
    formData.append("data", imageFile);
    return service.post(
      "/lists/" + taskListId + "/tasks/" + taskId + "/image",
      formData,
      { headers: { "Content-Type": "multipart/form-data" } }
    );
  },

  deleteTaskImage(taskListId, taskId) {
    console.log("delete: " + taskListId + "/" + taskId);
    return service.delete(
      "/lists/" + taskListId + "/tasks/" + taskId + "/image"
    );
  },

  getTaskImageURL(taskListId, taskId) {
    return baseURL + "/lists/" + taskListId + "/tasks/" + taskId + "/image";
  },

  deleteTask(taskListId, taskId) {
    return service.delete("/lists/" + taskListId + "/tasks/" + taskId);
  },

  getTasks(taskListId) {
    return service.get("/lists/" + taskListId + "/tasks");
  },

  addUser(taskListId, user) {
    return service.post("/lists/" + taskListId + "/users", user);
  },

  deleteUser(taskListId, userId) {
    return service.delete("/lists/" + taskListId + "/users/" + userId);
  },

  getUsers(taskListId) {
    return service.get("/lists/" + taskListId + "/users");
  }
};
