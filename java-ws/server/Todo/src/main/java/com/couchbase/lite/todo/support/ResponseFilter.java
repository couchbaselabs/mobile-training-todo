package com.couchbase.lite.todo.support;


import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.MultivaluedMap;


/**
 * For supporting CORS
 */
public class ResponseFilter implements ContainerResponseFilter {
    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
        MultivaluedMap<String, Object> headers = responseContext.getHeaders();
        // This allows just about anybody to connect to the server.
        // !!! DO NOT DO THIS IN THE PRODUCTION CODE
        headers.putSingle("Access-Control-Allow-Origin", requestContext.getHeaderString("Origin"));
        headers.putSingle("Access-Control-Allow-Headers", "Content-Type,X-Requested-With,accept,Origin,Set-Cookie");
        headers.putSingle("Access-Control-Allow-Methods", "DELETE,GET,HEAD,OPTIONS,POST,PUT");
        headers.putSingle("Access-Control-Allow-Credentials", "true");
    }
}
