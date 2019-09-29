package com.couchbase.lite.todo;

import com.couchbase.lite.Blob;
import com.couchbase.lite.todo.model.Task;
import com.couchbase.lite.todo.model.TaskListUser;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.model.TaskList;
import com.couchbase.lite.todo.model.User;
import com.couchbase.lite.todo.support.SessionManager;
import com.couchbase.lite.todo.support.UserContext;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.RequestBody;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataContentDisposition;
import org.glassfish.jersey.media.multipart.FormDataParam;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.ws.rs.*;
import javax.ws.rs.core.*;

import java.io.InputStream;
import java.net.URI;
import java.util.*;

import static com.couchbase.lite.todo.Application.SESSION_MAX_INACTIVE_INTERVAL_SECONDS;
import static com.couchbase.lite.todo.support.SessionManager.HTTP_SESSION_USER_CONTEXT_KEY;
import static javax.ws.rs.core.MediaType.*;

@Path("/todo")
public class Todo {
    interface Server { Response service(UserContext context) throws Throwable; }

    private static final OkHttpClient HTTP_CLIENT = new OkHttpClient();

    @POST
    @Path("login")
    @Consumes(APPLICATION_JSON)
    public Response login(@Context HttpServletRequest request, User user) {
        HttpSession session = request.getSession(true);

        if (session.getMaxInactiveInterval() == 0) {
            session.setMaxInactiveInterval(SESSION_MAX_INACTIVE_INTERVAL_SECONDS);
        }

        UserContext context = (UserContext) session.getAttribute(HTTP_SESSION_USER_CONTEXT_KEY);
        if (context != null) {
            if (!context.getUsername().equals(user.getName())) {
                return unauthorized(session);
            }
            SessionManager.manager().unregister(session);
        }

        // Authenticate with Sync Gateway:
        String sgSessionID = login(user);
        if (sgSessionID == null) {
            return unauthorized(session);
        }

        if (!SessionManager.manager().register(session, user, sgSessionID)) {
            return unauthorized(session);
        }

        return Response.ok().build();
    }

    private String login(User user) {
        okhttp3.Response response = null;
        try {
            URI base = new URI(Application.getSyncGatewayUrl() + "/_session");
            String scheme = base.getScheme().equals("wss") ? "https" : "http";
            URI uri = new URI(scheme, null, base.getHost(), base.getPort(), base.getPath(), null, null);
            HttpUrl url = HttpUrl.get(uri);
            okhttp3.MediaType contentType =  okhttp3.MediaType.parse("application/json; charset=utf-8");
            okhttp3.Request request = new okhttp3.Request.Builder()
                    .url(url)
                    .post(RequestBody.create(contentType, new ObjectMapper().writeValueAsString(user)))
                    .build();

            response = HTTP_CLIENT.newCall(request).execute();

            if (response.isSuccessful()) {
                for (okhttp3.Cookie c : okhttp3.Cookie.parseAll(url, response.headers())) {
                    if ("SyncGatewaySession".equals(c.name())) {
                        return c.value();
                    }
                }
            }
        } catch (Throwable th) {
            th.printStackTrace();
        } finally {
            if (response != null) response.close();
        }
        return null;
    }

    @POST
    @Path("logout")
    public Response logout(@Context HttpServletRequest request) {
        invalidateSession(request.getSession());
        return ok();
    }

    @POST
    @Path("lists")
    @Consumes(APPLICATION_JSON)
    @Produces(APPLICATION_JSON)
    public Response createTaskList(@Context HttpServletRequest request, TaskList list) {
        return service(request, context -> {
            String id = TaskList.create(context, list);
            return created(id);
        });
    }

    @PUT
    @Path("lists/{id}")
    @Consumes(APPLICATION_JSON)
    public Response updateTaskList(@Context HttpServletRequest request, @PathParam("id") String id, TaskList list) {
        return service(request, context -> {
            TaskList.update(context, id, list);
            return ok();
        });
    }

    @DELETE
    @Path("lists/{id}")
    @Consumes(APPLICATION_JSON)
    public Response deleteTaskList(@Context HttpServletRequest request, @PathParam("id") String id) {
        return service(request, context -> {
            TaskList.delete(context, id);
            return ok();
        });
    }

    @GET
    @Path("lists")
    @Produces(APPLICATION_JSON)
    public Response getTaskLists(@Context HttpServletRequest request) {
        return service(request, context -> {
            List<TaskList> taskLists = TaskList.getTaskLists(context);
            return ok(taskLists);
        });
    }

    @POST
    @Path("lists/{taskListId}/tasks")
    @Consumes(APPLICATION_JSON)
    @Produces(APPLICATION_JSON)
    public Response createTask(@Context HttpServletRequest request, @PathParam("taskListId") String taskListId, Task task) {
        return service(request, context -> {
            String id = Task.create(context, taskListId, task);
            return created(id);
        });
    }

    @PUT
    @Path("lists/{taskListId}/tasks/{id}")
    @Consumes(APPLICATION_JSON)
    public Response updateTask(@Context HttpServletRequest request,
                               @PathParam("taskListId") String taskListId,
                               @PathParam("id") String id,
                               Task task) {
        return service(request, context -> {
            Task.update(context, taskListId, id, task);
            return ok();
        });
    }

    @DELETE
    @Path("lists/{taskListId}/tasks/{id}")
    @Consumes(APPLICATION_JSON)
    public Response deleteTask(@Context HttpServletRequest request,
                               @PathParam("taskListId") String taskListId,
                               @PathParam("id") String id) {
        return service(request, context -> {
            Task.delete(context, id);
            return ok();
        });
    }

    @POST
    @Path("lists/{taskListId}/tasks/{id}/image")
    @Consumes(MULTIPART_FORM_DATA)
    public Response updateTaskPhoto(@Context HttpServletRequest request,
                                    @PathParam("taskListId") String taskListId,
                                    @PathParam("id") String id,
                                    @FormDataParam("data") FormDataBodyPart content,
                                    @FormDataParam("data") FormDataContentDisposition contentDisposition,
                                    @FormDataParam("data") final InputStream input) {
        return service(request, context -> {
            String contentType = content.getMediaType().toString();
            Task.updateImage(context, taskListId, id, input, contentType);
            return ok();
        });
    }

    @DELETE
    @Path("lists/{taskListId}/tasks/{id}/image")
    @Consumes(APPLICATION_JSON)
    public Response deleteTaskImage(@Context HttpServletRequest request,
                                    @PathParam("taskListId") String taskListId,
                                    @PathParam("id") String id) {
        return service(request, context -> {
            Task.deleteImage(context, taskListId, id);
            return ok();
        });
    }

    @GET
    @Path("lists/{taskListId}/tasks/{id}/image")
    @Produces(APPLICATION_OCTET_STREAM)
    public Response getTaskImage(@Context HttpServletRequest request,
                                 @PathParam("taskListId") String taskListId,
                                 @PathParam("id") String id) {
        return service(request, context -> {
            Blob image = Task.getPhoto(context, taskListId, id);
            StreamingOutput out = output -> {
                InputStream input = image.getContentStream();
                try {
                    byte[] buffer = new byte[8 * 1024];
                    int bytes;
                    while ((bytes = input.read(buffer)) != -1) {
                        output.write(buffer, 0, bytes);
                    }
                }
                finally {
                    input.close();
                }
            };
            return Response.ok().entity(out).type(image.getContentType()).build();
        });
    }

    @GET
    @Path("lists/{taskListId}/tasks")
    @Produces(APPLICATION_JSON)
    public Response getTasks(@Context HttpServletRequest request, @PathParam("taskListId") String taskListId) {
        return service(request, context -> {
            List<Task> tasks = Task.getTasks(context, taskListId);
            return ok(tasks);
        });
    }

    @POST
    @Path("lists/{taskListId}/users")
    @Consumes(APPLICATION_JSON)
    @Produces(APPLICATION_JSON)
    public Response addUser(@Context HttpServletRequest request,
                            @PathParam("taskListId") String taskListId,
                            TaskListUser user) {
        return service(request, context -> {
            String id = TaskListUser.add(context, taskListId, user);
            return created(id);
        });
    }

    @DELETE
    @Path("lists/{taskListId}/users/{id}")
    @Consumes(APPLICATION_JSON)
    public Response deleteUser(@Context HttpServletRequest request,
                               @PathParam("taskListId") String taskListId,
                               @PathParam("id") String id) {
        return service(request, context -> {
            TaskListUser.delete(context, id);
            return ok();
        });
    }

    @GET
    @Path("lists/{taskListId}/users")
    @Produces(APPLICATION_JSON)
    public Response getUsers(@Context HttpServletRequest request, @PathParam("taskListId") String taskListId) {
        return service(request, context -> {
            List<TaskListUser> users = TaskListUser.getUsers(context, taskListId);
            return ok(users);
        });
    }

    private Response service(HttpServletRequest request, Server server) {
        try {
            UserContext context = getUserContext(request);
            return server.service(context);
        } catch (Throwable th) {
            System.err.println(th);
            return error(th);
        }
    }

    private UserContext getUserContext(HttpServletRequest request) {
        HttpSession session = request.getSession();
        if (session != null) {
            if (SessionManager.manager().isRegistered(session)) {
                UserContext context = (UserContext) session.getAttribute(HTTP_SESSION_USER_CONTEXT_KEY);
                if (context != null) {
                    return context;
                }
            }
        }
        throw new ResponseException(Response.Status.UNAUTHORIZED);
    }

    private static Response ok() {
        return Response.ok().build();
    }

    private static Response ok(Object entity) {
        return Response.ok().entity(entity).type(APPLICATION_JSON).build();
    }

    private static Response created(String id) {
        Map<String, Object> entity = null;
        if (id != null) {
            entity = new HashMap<>();
            entity.put("id", id);
        }
        return Response.status(Response.Status.CREATED).entity(entity).build();
    }

    private static Response unauthorized(HttpSession session) {
        invalidateSession(session);
        return Response.status(Response.Status.UNAUTHORIZED).build();
    }

    private static Response error(Throwable th) {
        if (th instanceof ResponseException){
            return ((ResponseException) th).getResonse();
        } else {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(th.getMessage()).build();
        }
    }

    private static void invalidateSession(HttpSession session) {
        try {
            if (session != null) { session.invalidate(); }
        } catch (Throwable th) { }
    }
}
