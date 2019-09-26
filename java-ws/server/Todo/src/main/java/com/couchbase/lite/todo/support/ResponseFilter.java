package com.couchbase.lite.todo.support;

import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.MultivaluedMap;
import java.io.IOException;

/** For supporting CORS */
public class ResponseFilter implements ContainerResponseFilter {
    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) throws IOException {
        MultivaluedMap<String, Object> headers = responseContext.getHeaders();
        // This allows all of the client host to connect to the server.
        // DO NOT DO THIS IN THE PRODUCTION CODE
        headers.putSingle("Access-Control-Allow-Origin", requestContext.getHeaderString("Origin"));
        headers.putSingle("Access-Control-Allow-Headers", "Content-Type,X-Requested-With,accept,Origin,Set-Cookie");
        headers.putSingle("Access-Control-Allow-Methods", "DELETE,GET,HEAD,OPTIONS,POST,PUT");
        headers.putSingle("Access-Control-Allow-Credentials", "true");
    }
}
