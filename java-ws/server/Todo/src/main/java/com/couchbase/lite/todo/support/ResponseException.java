package com.couchbase.lite.todo.support;

import javax.ws.rs.core.Response;

public class ResponseException extends RuntimeException {
    private Response.Status status;

    public ResponseException(Response.Status status) {
        this(status, null);
    }

    public ResponseException(Response.Status status, String message) {
        super(message);
        this.status = status;
    }

    public Response getResonse() {
        return Response.status(status).entity(getMessage()).build();
    }

    public static ResponseException NOT_FOUND(String entity) {
        return new ResponseException(Response.Status.NOT_FOUND, entity + " not found.");
    }

    public static ResponseException BAD_REQUEST(String message) {
        return new ResponseException(Response.Status.BAD_REQUEST, message);
    }
}
