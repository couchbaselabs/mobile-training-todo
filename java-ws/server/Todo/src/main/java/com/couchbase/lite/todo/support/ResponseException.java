package com.couchbase.lite.todo.support;


import jakarta.ws.rs.core.Response;


public class ResponseException extends RuntimeException {
    public static ResponseException notFound(String entity) {
        return new ResponseException(Response.Status.NOT_FOUND, entity + " not found.");
    }

    public static ResponseException badRequest(String message) {
        return new ResponseException(Response.Status.BAD_REQUEST, message);
    }


    private final Response.Status status;

    public ResponseException(Response.Status status) { this(status, null); }

    public ResponseException(Response.Status status, String message) {
        super(message);
        this.status = status;
    }

    public Response getResponse() { return Response.status(status).entity(getMessage()).build(); }
}
