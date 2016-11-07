module.exports = {
  "swagger": "2.0",
  "info": {
  "title": "Sync Gateway",
    "description": "Documentation for the Sync Gateway Admin REST API. This page is generated from the Sync Gateway Admin Swagger spec, the exact same information is also available at [developer.couchbase.com/mobile/swagger/sync-gateway-admin](http://developer.couchbase.com/mobile/swagger/sync-gateway-admin/).\n",
    "version": "1.3"
},
  "host": "localhost:4985",
  "schemes": [
  "http",
  "https"
],
  "basePath": "/",
  "consumes": [
  "application/json"
],
  "produces": [
  "application/json"
],
  "parameters": {
  "access": {
    "name": "access",
      "in": "query",
      "description": "Indicates whether to include in the response a list of what access this document grants (i.e. which users it allows to access which channels.) This option may only be used from the admin port.",
      "type": "boolean",
      "default": false
  },
  "active_only": {
    "name": "active_only",
      "in": "query",
      "description": "Default is false. When true, the changes response doesn't include either deleted documents, or notification for documents that the user no longer has access to.",
      "type": "boolean",
      "default": false
  },
  "attachment": {
    "in": "path",
      "name": "attachment",
      "description": "Attachment name",
      "type": "string",
      "required": true
  },
  "attachments": {
    "in": "query",
      "name": "attachments",
      "description": "Default is false. Include attachment bodies in response.",
      "type": "boolean",
      "default": false
  },
  "atts_since": {
    "name": "atts_since",
      "in": "query",
      "description": "Include attachments only since specified revisions. Does not include attachments for specified revisions.",
      "type": "array",
      "items": {
      "type": "string"
    },
    "required": false
  },
  "body": {
    "name": "body",
      "in": "body",
      "description": "The request body",
      "schema": {
      "type": "object"
    }
  },
  "bulkget": {
    "in": "body",
      "name": "BulkGetBody",
      "description": "List of documents being requested. Each array element is an object that must contain an id property giving the document ID. It may contain a rev property if a specific revision is desired. It may contain an atts_since property (as in a single-document GET) to limit which attachments are sent.",
      "schema": {
      "type": "object",
        "properties": {
        "docs": {
          "type": "array",
            "items": {
            "type": "string"
          }
        }
      }
    }
  },
  "channels": {
    "in": "query",
      "name": "channels",
      "description": "Indicates whether to include in the response a channels property containing an array of channels this document is assigned to. (Channels not accessible by the user making the request will not be listed.)",
      "type": "boolean",
      "default": false
  },
  "channels_list": {
    "in": "query",
      "name": "channels",
      "description": "A comma-separated list of channel names. The response will be filtered to only documents in these channels. (This parameter must be used with the sync_gateway/bychannel filter parameter; see below.)",
      "type": "string",
      "required": false
  },
  "db": {
    "name": "db",
      "in": "path",
      "description": "Database name",
      "type": "string",
      "required": true
  },
  "ddoc": {
    "name": "ddoc",
      "in": "path",
      "description": "Design document name",
      "type": "string",
      "required": true
  },
  "descending": {
    "name": "descending",
      "in": "query",
      "description": "Default is false. Return documents in descending order.",
      "type": "boolean",
      "required": false
  },
  "doc": {
    "name": "doc",
      "in": "path",
      "description": "Document ID",
      "type": "string",
      "required": true
  },
  "doc_ids": {
    "in": "query",
      "name": "doc_ids",
      "description": "A list of document IDs as a valid JSON array. The response will be filtered to only documents with these IDs. (This parameter must be used with the _doc_ids filter parameter; see below.)",
      "type": "array",
      "items": {
      "type": "string"
    }
  },
  "endkey": {
    "name": "endkey",
      "in": "query",
      "description": "If this parameter is provided, stop returning records when the specified key is reached.",
      "type": "string",
      "required": false
  },
  "feed": {
    "in": "query",
      "name": "feed",
      "description": "Default is 'normal'. Specifies type of change feed. Valid values are normal, continuous, longpoll, websocket.",
      "type": "string",
      "default": "normal"
  },
  "heartbeat": {
    "in": "query",
      "name": "heartbeat",
      "description": "Default is 0. Interval in milliseconds at which an empty line (CRLF) is written to the response. This helps prevent gateways from deciding the socket is idle and closing it. Only applicable to longpoll or continuous feeds. Overrides any timeout to keep the feed alive indefinitely. Setting to 0 results in no heartbeat.",
      "type": "integer",
      "default": 0
  },
  "include_docs": {
    "in": "query",
      "name": "include_docs",
      "description": "Default is false. Indicates whether to include the associated document with each result. If there are conflicts, only the winning revision is returned.",
      "type": "boolean",
      "default": false
  },
  "keys": {
    "in": "query",
      "name": "keys",
      "description": "Specify a list of document IDs.",
      "type": "array",
      "items": {
      "type": "string"
    },
    "required": false
  },
  "limit": {
    "in": "query",
      "name": "limit",
      "description": "Limits the number of result rows to the specified value. Using a value of 0 has the same effect as the value 1.",
      "type": "integer"
  },
  "local_doc": {
    "in": "path",
      "name": "local_doc",
      "description": "Local document IDs begin with _local/.",
      "type": "string",
      "required": true
  },
  "new_edits": {
    "name": "new_edits",
      "in": "query",
      "description": "Default is true. Setting this to false indicates that the request body is an already-existing revision that should be directly inserted into the database, instead of a modification to apply to the current document. (This mode is used by the replicato.)",
      "type": "boolean",
      "default": true
  },
  "open_revs": {
    "name": "open_revs",
      "in": "query",
      "description": "Option to fetch specified revisions of the document. The value can be `all` to fetch all leaf revisions or an array of revision numbers (i.e. open_revs=[\"rev1\", \"rev2\"]). If this option is specified the response will be in multipart format. Use the `Accept: application/json` request header to get the result as a JSON object.",
      "type": "array",
      "items": {
      "type": "string"
    },
    "required": false
  },
  "rev": {
    "name": "rev",
      "in": "query",
      "description": "Revision identifier of the parent revision the new one should replace. (Not used when creating a new document.)",
      "type": "string",
      "required": false
  },
  "revs": {
    "in": "query",
      "name": "revs",
      "description": "Default is false. Indicates whether to include a _revisions property for each document in the response, which contains a revision history of the document.",
      "type": "boolean",
      "default": false
  },
  "role": {
    "in": "body",
      "name": "role",
      "description": "The message body is a JSON document that contains the following objects.",
      "schema": {
      "type": "object",
        "properties": {
        "name": {
          "type": "string",
            "description": "Name of the role that will be created"
        },
        "admin_channels": {
          "type": "array",
            "description": "Array of channel names to give the role access to",
            "items": {
            "type": "string"
          }
        }
      }
    }
  },
  "sessionid": {
    "name": "sessionid",
      "in": "path",
      "description": "Session id",
      "type": "string",
      "required": true
  },
  "startkey": {
    "name": "startkey",
      "in": "query",
      "description": "Returns records starting with the specified key.",
      "type": "string",
      "required": false
  },
  "since": {
    "in": "query",
      "name": "since",
      "description": "Starts the results from the change immediately after the given sequence ID. Sequence IDs should be considered opaque; they come from the last_seq property of a prior response.",
      "type": "integer",
      "required": false
  },
  "style": {
    "in": "query",
      "name": "style",
      "description": "Default is 'main_only'. Number of revisions to return in the changes array. main_only returns the current winning revision, all_docs returns all leaf revisions including conflicts and deleted former conflicts.",
      "type": "string",
      "default": "main_only"
  },
  "timeout": {
    "in": "query",
      "name": "timeout",
      "description": "Default is 300000. Maximum period in milliseconds to wait for a change before the response is sent, even if there are no results. Only applicable for longpoll or continuous feeds. Setting to 0 results in no timeout.",
      "type": "integer",
      "default": 300000
  },
  "update_seq": {
    "in": "query",
      "name": "update_seq",
      "description": "Default is false. Indicates whether to include the update_seq (document sequence ID) property in the response.",
      "type": "boolean",
      "default": false
  },
  "user": {
    "in": "body",
      "name": "body",
      "description": "Request body",
      "schema": {
      "type": "object",
        "properties": {
        "name": {
          "type": "string",
            "description": "Name of the user that will be created"
        },
        "password": {
          "type": "string",
            "description": "Password of the user that will be created. Required, unless the allow_empty_password Sync Gateway per-database configuration value is set to true, in which case the password can be omitted."
        },
        "admin_channels": {
          "type": "array",
            "description": "Array of channel names to give the user access to",
            "items": {
            "type": "string",
              "description": "Channel name"
          }
        },
        "admin_roles": {
          "type": "array",
            "description": "Array of role names to assign to this user",
            "items": {
            "type": "string",
              "description": "Role name"
          }
        },
        "email": {
          "type": "string",
            "description": "Email of the user that will be created."
        },
        "disabled": {
          "type": "boolean",
            "description": "Boolean property to disable this user. The user will not be able to login if this property is set to true."
        }
      }
    }
  },
  "view": {
    "name": "view",
      "in": "path",
      "description": "View name",
      "type": "string",
      "required": true
  },
  "bulkdocs": {
    "in": "body",
      "name": "BulkDocsBody",
      "description": "The request body",
      "schema": {
      "properties": {
        "docs": {
          "description": "List containing new or updated documents. Each object in the array can contain the following properties _id, _rev, _deleted, and values for new and updated documents.",
            "type": "array",
            "items": {
            "type": "object"
          }
        },
        "new_edits": {
          "description": "Indicates whether to assign new revision identifiers to new edits.",
            "type": "boolean",
            "default": true
        }
      }
    }
  },
  "batch": {
    "in": "query",
      "name": "batch",
      "description": "Stores the document in batch mode. To use, set the value to ok.",
      "type": "string",
      "required": false
  },
  "changes_body": {
    "in": "body",
      "name": "ChangesBody",
      "description": "The request body",
      "schema": {
      "properties": {
        "limit": {
          "description": "Limits the number of result rows to the specified value. Using a value of 0 has the same effect as the value 1.",
            "type": "integer"
        },
        "style": {
          "description": "Default is 'main_only'. Number of revisions to return in the changes array. The only possible value is all_docs and it returns all leaf revisions including conflicts and deleted former conflicts.",
            "type": "string",
            "default": "main_only"
        },
        "active_only": {
          "description": "Default is false. When true, the changes response doesn't include either deleted documents, or notification for documents that the user no longer has access to.",
            "type": "boolean",
            "default": false
        },
        "include_docs": {
          "description": "Default is false. Indicates whether to include the associated document with each result. If there are conflicts, only the winning revision is returned.",
            "type": "boolean",
            "default": false
        },
        "filter": {
          "description": "Indicates that the returned documents should be filtered. The valid values are sync_gateway/bychannel and _doc_ids.",
            "type": "string"
        },
        "channels": {
          "description": "A comma-separated list of channel names. The response will be filtered to only documents in these channels. (This parameter must be used with the sync_gateway/bychannel filter parameter; see below.)",
            "type": "string"
        },
        "doc_ids": {
          "description": "A list of document IDs as a valid JSON array. The response will be filtered to only documents with these IDs. (This parameter must be used with the _doc_ids filter parameter; see below.)",
            "type": "array",
            "items": {
            "type": "string"
          }
        },
        "feed": {
          "description": "Default is 'normal'. Specifies type of change feed. Valid values are normal, continuous, longpoll, websocket.",
            "type": "string",
            "default": "normal"
        },
        "since": {
          "description": "Starts the results from the change immediately after the given sequence ID. Sequence IDs should be considered opaque; they come from the last_seq property of a prior response.",
            "type": "integer"
        },
        "heartbeat": {
          "description": "Default is 0. Interval in milliseconds at which an empty line (CRLF) is written to the response. This helps prevent gateways from deciding the socket is idle and closing it. Only applicable to longpoll or continuous feeds. Overrides any timeout to keep the feed alive indefinitely. Setting to 0 results in no heartbeat.",
            "type": "integer",
            "default": 0
        },
        "timeout": {
          "description": "Default is 300000. Maximum period in milliseconds to wait for a change before the response is sent, even if there are no results. Only applicable for longpoll or continuous feeds. Setting to 0 results in no timeout.",
            "type": "integer",
            "default": 300000
        }
      }
    }
  },
  "filter": {
    "in": "query",
      "name": "filter",
      "description": "Indicates that the reported documents should be filtered. The valid values are sync_gateway/bychannel and _doc_ids.",
      "type": "string",
      "required": false
  },
  "name": {
    "in": "path",
      "name": "name",
      "description": "User's name",
      "type": "string",
      "required": true
  },
  "replication": {
    "in": "body",
      "name": "ReplicationBody",
      "description": "The request message body is a JSON document that contains the following objects.",
      "schema": {
      "type": "object",
        "properties": {
        "create_target": {
          "type": "boolean",
            "description": "Indicates whether to create the target database"
        },
        "source": {
          "type": "string",
            "description": "Identifies the database to copy revisions from. Can be a string containing a local database name or a remote database URL, or an object whose url property contains the database name or URL. Also an object can contain headers property that contains custom header values such as a cookie."
        },
        "target": {
          "type": "string",
            "description": "Identifies the database to copy revisions to. Same format and interpretation as source."
        },
        "continuous": {
          "type": "boolean",
            "description": "Specifies whether the replication should be in continuous mode."
        },
        "filter": {
          "type": "string",
            "description": "Indicates that the documents should be filtered using the specified filter function name. A common value used when replicating from Sync Gateway is sync_gateway/bychannel to limit the pull replication to a set of channels."
        },
        "query_params": {
          "type": "object",
            "description": "A set of key/value pairs to use in the querystring of the replication. For example, the channels field can be used to pull from a set of channels (in this particular case, the filter key must be set for the channels field to work as expected)."
        },
        "replication_id": {
          "type": "string",
            "description": "If the cancel parameter is true then this is the id of the active replication task to be cancelled, otherwise this is the replication_id to be used for the new replication. If no replication_id is given for a new replication it will be assigned a random UUID."
        },
        "cancel": {
          "type": "boolean",
            "description": "Indicates that a running replication task should be cancelled, the running task is identified by passing its replication_id or by passing the original source and target values."
        }
      }
    }
  },
  "show_exp": {
    "in": "query",
      "name": "show_exp",
      "description": "Whether to show the _exp property in the response.",
      "type": "boolean",
      "default": false,
      "required": false
  }
},
  "paths": {
  "/{db}/{doc}/{attachment}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/doc"
      },
      {
        "$ref": "#/parameters/attachment"
      }
    ],
      "get": {
      "tags": [
        "attachment"
      ],
        "summary": "Get attachment",
        "description": "This request retrieves a file attachment associated with the document. The raw data of the associated attachment is returned (just as if you were accessing a static file). The Content-Type response header is the same content type set when the document attachment was added to the database.\n",
        "parameters": [
        {
          "$ref": "#/parameters/rev"
        }
      ],
        "responses": {
        "200": {
          "description": "The message body contains the attachment, in the format specified in the Content-Type header."
        },
        "304": {
          "description": "Not Modified, the attachment wasn't modified if ETag equals the If-None-Match header"
        },
        "404": {
          "description": "Not Found, the specified database, document or attachment was not found."
        }
      }
    },
    "put": {
      "tags": [
        "attachment"
      ],
        "summary": "Add or update document",
        "description": "This request adds or updates the supplied request content as an attachment to the specified document. The attachment name must be a URL-encoded string (the file name). You must also supply either the rev query parameter or the If-Match HTTP header for validation, and the Content-Type headers (to set the attachment content type).\n\n  When uploading an attachment using an existing attachment name, the corresponding stored content of the database will be updated. Because you must supply the revision information to add an attachment to the document, this serves as validation to update the existing attachment.\n\n  Uploading an attachment updates the corresponding document revision. Revisions are tracked for the parent document, not individual attachments.\n",
        "responses": {
        "200": {
          "description": "Operation completed successfully",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        },
        "409": {
          "description": "Conflict, the document revision wasn't specified or it's not the latest."
        }
      }
    }
  },
  "/{db}/_bulk_docs": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "database"
      ],
        "summary": "Bulk docs",
        "description": "This request enables you to add, update, or delete multiple documents to a database in a single request. To add new documents, you can either specify the ID (_id) or let the software create an ID. To update existing documents, you must provide the document ID, revision identifier (_rev), and new document values. To delete existing documents you must provide the document ID, revision identifier, and the deletion flag (_deleted).\n",
        "parameters": [
        {
          "$ref": "#/parameters/bulkdocs"
        }
      ],
        "responses": {
        "201": {
          "description": "Documents have been created or updated",
            "schema": {
            "type": "array",
              "items": {
              "$ref": "#/definitions/Success"
            }
          }
        }
      }
    }
  },
  "/": {
    "get": {
      "tags": [
        "server"
      ],
        "summary": "Server",
        "description": "Returns meta-information about the server.\n",
        "responses": {
        "200": {
          "description": "Meta-information about the server.",
            "schema": {
            "$ref": "#/definitions/Server"
          }
        }
      }
    }
  },
  "/_replicate": {
    "post": {
      "tags": [
        "server"
      ],
        "summary": "Starts or cancels a database replication operation",
        "description": "This request starts or cancels a database replication operation.\n\nYou can cancel continuous replications by adding the cancel field to the JSON request object and setting the value to true. Note that the structure of the request must be identical to the original for the cancellation request to be honoured. For example, if you requested continuous replication, the cancellation request must also contain the continuous field.\n",
        "parameters": [
        {
          "$ref": "#/parameters/replication"
        }
      ],
        "responses": {
        "200": {
          "description": "200 OK",
            "schema": {
            "$ref": "#/definitions/Replication"
          }
        }
      }
    }
  },
  "/{db}/_bulk_get": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "database"
      ],
        "summary": "Bulk get",
        "description": "This request returns any number of documents, as individual bodies in a MIME multipart response.\nEach enclosed body contains one requested document. The bodies appear in the same order as in the request, but can also be identified by their X-Doc-ID and X-Rev-ID headers.\nA body for a document with no attachments will have content type application/json and contain the document itself.\nA body for a document that has attachments will be written as a nested multipart/related body. Its first part will be the document's JSON, and the subsequent parts will be the attachments (each identified by a Content-Disposition header giving its attachment name.)\n",
        "parameters": [
        {
          "$ref": "#/parameters/revs"
        },
        {
          "$ref": "#/parameters/attachments"
        },
        {
          "$ref": "#/parameters/bulkget"
        }
      ],
        "responses": {
        "200": {
          "description": "Request completed successfully",
            "schema": {
            "type": "object",
              "properties": {
              "docs": {
                "type": "array",
                  "items": {
                  "$ref": "#/definitions/Success"
                }
              }
            }
          }
        }
      }
    }
  },
  "/{db}/_local/{local_doc}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/local_doc"
      }
    ],
      "get": {
      "tags": [
        "document"
      ],
        "summary": "Get local doc",
        "description": "This request retrieves a local document. Local document IDs begin with _local/. Local documents are not replicated or indexed, don't support attachments, and don't save revision histories. In practice they are almost only used by Couchbase Lite's replicator, as a place to store replication checkpoint data.\n",
        "responses": {
        "200": {
          "description": "The message body contains the following objects in a JSON document.",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    },
    "put": {
      "tags": [
        "document"
      ],
        "summary": "Create or update a local document",
        "description": "This request creates or updates a local document. Local document IDs begin with _local/. Local documents are not replicated or indexed, don't support attachments, and don't save revision histories. In practice they are almost only used by the client's replicator, as a place to store replication checkpoint data.\n",
        "responses": {
        "201": {
          "description": "Created",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    },
    "delete": {
      "tags": [
        "document"
      ],
        "summary": "Delete a local document",
        "description": "This request deletes a local document. Local document IDs begin with _local/. Local documents are not replicated or indexed, don't support attachments, and don't save revision histories. In practice they are almost only used by Couchbase Lite's replicator, as a place to store replication checkpoint data.\n",
        "parameters": [
        {
          "$ref": "#/parameters/rev"
        },
        {
          "$ref": "#/parameters/batch"
        }
      ],
        "responses": {
        "200": {
          "description": "Document successfully removed",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    }
  },
  "/{db}/_changes": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "database"
      ],
        "parameters": [
        {
          "$ref": "#/parameters/limit"
        },
        {
          "$ref": "#/parameters/style"
        },
        {
          "$ref": "#/parameters/active_only"
        },
        {
          "$ref": "#/parameters/include_docs"
        },
        {
          "$ref": "#/parameters/filter"
        },
        {
          "$ref": "#/parameters/channels_list"
        },
        {
          "$ref": "#/parameters/doc_ids"
        },
        {
          "$ref": "#/parameters/feed"
        },
        {
          "$ref": "#/parameters/since"
        },
        {
          "$ref": "#/parameters/heartbeat"
        },
        {
          "$ref": "#/parameters/timeout"
        }
      ],
        "summary": "Changes",
        "description": "This request retrieves a sorted list of changes made to documents in the database, in time order of application. Each document appears at most once, ordered by its most recent change, regardless of how many times it's been changed.\nThis request can be used to listen for update and modifications to the database for post processing or synchronization. A continuously connected changes feed is a reasonable approach for generating a real-time log for most applications.\n",
        "responses": {
        "200": {
          "description": "Request completed successfully",
            "schema": {
            "$ref": "#/definitions/Changes"
          }
        }
      }
    },
    "post": {
      "tags": [
        "database"
      ],
        "parameters": [
        {
          "$ref": "#/parameters/changes_body"
        }
      ],
        "summary": "Changes",
        "description": "Same as the GET /_changes request except the parameters are in the JSON body.\n",
        "responses": {
        "200": {
          "description": "Request completed successfully",
            "schema": {
            "$ref": "#/definitions/Changes"
          }
        }
      }
    }
  },
  "/{db}/{doc}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/doc"
      }
    ],
      "get": {
      "tags": [
        "document"
      ],
        "parameters": [
        {
          "$ref": "#/parameters/attachments"
        },
        {
          "$ref": "#/parameters/atts_since"
        },
        {
          "$ref": "#/parameters/open_revs"
        },
        {
          "$ref": "#/parameters/revs"
        },
        {
          "$ref": "#/parameters/show_exp"
        }
      ],
        "summary": "Get document",
        "description": "This request retrieves a document from a database.",
        "responses": {
        "200": {
          "description": "The message body contains the following objects in a JSON document.",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    },
    "put": {
      "tags": [
        "document"
      ],
        "parameters": [
        {
          "in": "body",
          "name": "Document",
          "description": "Request body",
          "schema": {
            "$ref": "#/definitions/Document"
          }
        },
        {
          "$ref": "#/parameters/new_edits"
        },
        {
          "$ref": "#/parameters/rev"
        }
      ],
        "summary": "Create or update document",
        "description": "This request creates a new document or creates a new revision of an existing document. It enables you to specify the identifier for a new document rather than letting the software create an identifier. If you want to create a new document and let the software create an identifier, use the POST /db request.\nIf the document specified by doc does not exist, a new document is created and assigned the identifier specified in doc. If the document already exists, the document is updated with the JSON document in the message body and given a new revision.\n",
        "responses": {
        "200": {
          "description": "The response is a JSON document that contains the following objects",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    },
    "delete": {
      "tags": [
        "document"
      ],
        "parameters": [
        {
          "$ref": "#/parameters/rev"
        }
      ],
        "summary": "Delete document",
        "description": "This request deletes a document from the database. When a document is deleted, the revision number is updated so the database can track the deletion in synchronized copies.\n",
        "responses": {
        "200": {
          "description": "Document successfully removed",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    }
  },
  "/{db}/_design/{ddoc}/_view/{view}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/ddoc"
      },
      {
        "$ref": "#/parameters/view"
      }
    ],
      "get": {
      "tags": [
        "query"
      ],
        "summary": "Query a view",
        "description": "Query a view on a design document. This endpoint is only accessible if you have enabled views in the Sync Gateway configuration file (see [this guide](/documentation/mobile/current/develop/guides/sync-gateway/views/index.html) for more information on this topic).\n",
        "parameters": [
        {
          "in": "query",
          "name": "conflicts",
          "description": "Include conflict information in the response. This parameter is ignored if the include_docs parameter is false.",
          "type": "boolean"
        },
        {
          "in": "query",
          "name": "descending",
          "description": "Return documents in descending order.",
          "type": "boolean"
        },
        {
          "in": "query",
          "name": "endkey",
          "description": "If this parameter is provided, stop returning records when the specified key is reached.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "end_key",
          "description": "Alias for the endkey parameter.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "endkey_docid",
          "description": "If this parameter is provided, stop returning records when the specified document identifier is reached.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "end_key_doc_id",
          "description": "Alias for the endkey_docid parameter.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "include_docs",
          "description": "Indicates whether to include the full content of the documents in the response.",
          "type": "boolean"
        },
        {
          "in": "query",
          "name": "inclusive_end",
          "description": "Indicates whether the specified end key should be included in the result.",
          "type": "boolean"
        },
        {
          "in": "query",
          "name": "key",
          "description": "If this parameter is provided, return only document that match the specified key.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "limit",
          "description": "If this parameter is provided, return only the specified number of documents.",
          "type": "integer"
        },
        {
          "in": "query",
          "name": "skip",
          "description": "If this parameter is provided, skip the specified number of documents before starting to return results.",
          "type": "integer"
        },
        {
          "in": "query",
          "name": "stale",
          "description": "Allow the results from a stale view to be used, without triggering a rebuild of all views within the encompassing design document. Valid values are ok and update_after.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "startkey",
          "description": "If this parameter is provided, return documents starting with the specified key.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "start_key",
          "description": "Alias for startkey param.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "startkey_docid",
          "description": "If this parameter is provided, return documents starting with the specified document identifier.",
          "type": "string"
        },
        {
          "in": "query",
          "name": "update_seq",
          "description": "Indicates whether to include the update_seq property in the response.",
          "type": "boolean"
        }
      ],
        "responses": {
        "200": {
          "description": "Query results",
            "schema": {
            "$ref": "#/definitions/QueryResult"
          }
        }
      }
    },
    "post": {
      "tags": [
        "query"
      ],
        "summary": "Query a view",
        "description": "Executes the specified view function from the specified design document. Unlike GET /{db}/{design-doc-id}/_view/{view} for accessing views, the POST method supports the specification of explicit keys to be retrieved from the view results. The remainder of the POST view functionality is identical to the GET /{db}/{design-doc-id}/_view/{view} API.\n",
        "parameters": [
        {
          "in": "body",
          "name": "keys",
          "description": "List of identifiers of the documents to retrieve",
          "schema": {
            "type": "array",
            "items": {
              "type": "string"
            }
          }
        }
      ],
        "responses": {
        "200": {
          "description": "200 OK"
        }
      }
    }
  },
  "/{db}/_all_docs": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "query"
      ],
        "summary": "All docs",
        "description": "This request returns a built-in view of all the documents in the database.\n",
        "parameters": [
        {
          "$ref": "#/parameters/access"
        },
        {
          "$ref": "#/parameters/channels"
        },
        {
          "$ref": "#/parameters/include_docs"
        },
        {
          "$ref": "#/parameters/revs"
        },
        {
          "$ref": "#/parameters/update_seq"
        },
        {
          "$ref": "#/parameters/limit"
        },
        {
          "$ref": "#/parameters/keys"
        },
        {
          "$ref": "#/parameters/startkey"
        },
        {
          "$ref": "#/parameters/endkey"
        }
      ],
        "responses": {
        "200": {
          "description": "Query results",
            "schema": {
            "$ref": "#/definitions/QueryResult"
          }
        }
      }
    },
    "post": {
      "tags": [
        "query"
      ],
        "summary": "All docs",
        "description": "This request retrieves specified documents from the database.\n",
        "parameters": [
        {
          "$ref": "#/parameters/access"
        },
        {
          "$ref": "#/parameters/channels"
        },
        {
          "$ref": "#/parameters/include_docs"
        },
        {
          "$ref": "#/parameters/revs"
        },
        {
          "$ref": "#/parameters/update_seq"
        },
        {
          "in": "body",
          "name": "body",
          "description": "Request body",
          "schema": {
            "$ref": "#/definitions/AllDocs"
          }
        }
      ],
        "responses": {
        "200": {
          "description": "Query results",
            "schema": {
            "$ref": "#/definitions/QueryResult"
          }
        }
      }
    }
  },
  "/{db}/_oidc": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "auth"
      ],
        "summary": "OpenID Connect Authentication.",
        "description": "Called by clients to initiate the OIDC Authorization Code flow. \n",
        "parameters": [
        {
          "in": "query",
          "name": "offline",
          "description": "When true, requests a refresh token from the OP. Sets access_type=offline and prompt=consent on the redirect to the OP. Secure clients should set offline=true and persist the returned refresh token to secure storage.",
          "type": "boolean",
          "required": false
        },
        {
          "in": "query",
          "name": "provider",
          "description": "OpenId Connect provider to be used for authentication, from the list of providers defined in the Sync Gateway Config. If not specified, will attempt to authenticate using the default provider.",
          "type": "string",
          "required": false
        }
      ],
        "responses": {
        "302": {
          "description": "Redirect to the requested OpenID Connect provider for authentication. Redirect link is returned in the Location header."
        },
        "400": {
          "description": "Bad request.  Reason is returned as \"OpenID Connect not configured for database default\".  If a provider was specified in the request, that provider was not defined in the Sync Gateway config.  If no provider was specified, OpenID Connect is not configured in the Sync Gateway config."
        },
        "500": {
          "description": "Server Error.  Sync Gateway is unable to connect and validate the OpenID Connect provider requested."
        }
      }
    }
  },
  "/{db}/_oidc_callback": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "auth"
      ],
        "summary": "OpenID Connect Authentication callback.",
        "description": "Sync Gateway callback URL that clients are redirected to by the OpenID Connect provider. \n",
        "parameters": [
        {
          "in": "query",
          "name": "code",
          "description": "OpenID Connect Authorization code.",
          "type": "string",
          "required": true
        },
        {
          "in": "query",
          "name": "provider",
          "description": "OpenId Connect provider to be used for authentication, from the list of providers defined in the Sync Gateway Config. If not specified, will attempt to authenticate using the default provider.",
          "type": "string",
          "required": false
        }
      ],
        "responses": {
        "200": {
          "description": "Successful OpenID Connect authentication.",
            "schema": {
            "type": "object",
              "properties": {
              "id_token": {
                "type": "string",
                  "description": "OpenID Connect ID token"
              },
              "refresh_token": {
                "type": "string",
                  "description": "OpenID Connect refresh token"
              },
              "session_id": {
                "type": "string",
                  "description": "Sync Gateway session token"
              },
              "name": {
                "type": "string",
                  "description": "Sync Gateway username"
              },
              "access_token": {
                "type": "string",
                  "description": "OpenID Connect access token"
              },
              "token_type": {
                "type": "string",
                  "description": "OpenID Connect token type"
              },
              "expires_in": {
                "type": "number",
                  "description": "TTL for id_token"
              }
            }
          }
        },
        "400": {
          "description": "Bad request."
        },
        "401": {
          "description": "Authentication failed.  Reason returned in the response body."
        }
      }
    }
  },
  "/{db}/_oidc_challenge": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "auth"
      ],
        "summary": "OpenID Connect Authentication.",
        "description": "Called by clients to initiate the OIDC Authorization Code flow. \n",
        "parameters": [
        {
          "in": "query",
          "name": "offline",
          "description": "When true, requests a refresh token from the OP. Sets access_type=offline and prompt=consent on the redirect to the OP. Secure clients should set offline=true and persist the returned refresh token to secure storage.",
          "type": "boolean",
          "required": false
        },
        {
          "in": "query",
          "name": "provider",
          "description": "OpenId Connect provider to be used for authentication, from the list of providers defined in the Sync Gateway Config. If not specified, will attempt to authenticate using the default provider.",
          "type": "string",
          "required": false
        }
      ],
        "responses": {
        "302": {
          "description": "Redirect to the requested OpenID Connect provider for authentication. Redirect link is returned in the Location header."
        },
        "400": {
          "description": "Bad request.  Reason is returned as \"OpenID Connect not configured for database default\".  If a provider was specified in the request, that provider was not defined in the Sync Gateway config.  If no provider was specified, OpenID Connect is not configured in the Sync Gateway config."
        },
        "500": {
          "description": "Server Error.  Sync Gateway is unable to connect and validate the OpenID Connect provider requested."
        }
      }
    }
  },
  "/{db}/_oidc_refresh": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "auth"
      ],
        "summary": "OpenID Connect refresh.",
        "description": "Used to obtain a new OpenID Connect ID token based on the provided refresh token.\n",
        "parameters": [
        {
          "in": "query",
          "name": "refresh_token",
          "description": "OpenID Connect refresh token.",
          "type": "string",
          "required": true
        },
        {
          "in": "query",
          "name": "provider",
          "description": "OpenId Connect provider to be used for authentication, from the list of providers defined in the Sync Gateway Config. If not specified, will attempt to authenticate using the default provider.",
          "type": "string",
          "required": false
        }
      ],
        "responses": {
        "200": {
          "description": "Successful OpenID Connect authentication.",
            "schema": {
            "type": "object",
              "properties": {
              "id_token": {
                "type": "string",
                  "description": "OpenID Connect ID token"
              },
              "session_id": {
                "type": "string",
                  "description": "Sync Gateway session token"
              },
              "name": {
                "type": "string",
                  "description": "Sync Gateway username"
              },
              "access_token": {
                "type": "string",
                  "description": "OpenID Connect access token"
              },
              "token_type": {
                "type": "string",
                  "description": "OpenID Connect token type"
              },
              "expires_in": {
                "type": "number",
                  "description": "TTL for id_token"
              }
            }
          }
        },
        "400": {
          "description": "Bad request."
        },
        "401": {
          "description": "Authentication failed.  Unable to refresh token."
        }
      }
    }
  },
  "/_config": {
    "get": {
      "tags": [
        "server"
      ],
        "summary": "Server configuration",
        "description": "Returns the Sync Gateway configuration of the running instance. This is a good method to check if a \nparticular key was set correctly on the config file.\n",
        "responses": {
        "200": {
          "description": "Sync Gateway configuration of the running instance."
        }
      }
    }
  },
  "/_expvar": {
    "get": {
      "tags": [
        "server"
      ],
        "summary": "Debugging/monitoring at runtime",
        "description": "Number of runtime variables that you can view for debugging or performance monitoring purposes.",
        "responses": {
        "200": {
          "description": "hello",
            "schema": {
            "$ref": "#/definitions/ExpVars"
          }
        }
      }
    }
  },
  "/_logging": {
    "get": {
      "tags": [
        "server"
      ],
        "summary": "Logging tags",
        "description": "Get logging tags of running instance.\n",
        "responses": {
        "200": {
          "description": "Logging tags",
            "schema": {
            "$ref": "#/definitions/LogTags"
          }
        }
      }
    },
    "put": {
      "tags": [
        "server"
      ],
        "summary": "Specify logging tags",
        "description": "Log keys specify functional areas. Enabling logging for a log key provides additional diagnostic information for that area.\n\nFollowing are descriptions of the log keys that you can specify as a comma-separated list in the Log property. In some cases, a log key has two forms, one with a plus sign (+) suffix and one without, for example CRUD+ and CRUD. The log key with the plus sign logs more verbosely. For example for CRUD+, the log contains all of the messages for CRUD and additional ones for CRUD+.\n",
        "responses": {
        "200": {
          "description": "yoo"
        }
      }
    }
  },
  "/{db}/": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "database"
      ],
        "summary": "Database info",
        "description": "This request retrieves information about the database.\n",
        "responses": {
        "200": {
          "description": "Request completed successfully.",
            "schema": {
            "$ref": "#/definitions/Database"
          }
        },
        "401": {
          "description": "Unauthorized. Login required."
        },
        "404": {
          "description": "Not Found. Requested database not found."
        }
      }
    },
    "post": {
      "tags": [
        "document"
      ],
        "operationId": "post",
        "summary": "Create document",
        "description": "This request creates a new document in the specified database. You can either specify the document ID by including the _id in the request message body (the value must be a string), or let the software generate an ID.\n",
        "parameters": [
        {
          "in": "body",
          "name": "body",
          "description": "The document body",
          "schema": {
            "type": "object"
          }
        }
      ],
        "responses": {
        "201": {
          "description": "The document was written successfully",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    },
    "put": {
      "tags": [
        "database"
      ],
        "summary": "Create database",
        "description": "This request creates a database.\nYou can optionally pass the database config as the JSON body. For example:\n\n  {\n    \"server\":\"http://localhost:8091\",\n    \"bucket\": \"todo_app\",\n    \"users\": {\n      \"john\": {\"password\": \"pass\", \"admin_channels\": [\"*\"]}\n    }\n  }\n\nNote that if you pass the entire config file it won't work, it must be the database portion only (the database name is specified in the URL path). If the parameters passed are invalid it will create a walrus-backed database with all values set to default.\n",
        "responses": {
        "201": {
          "description": "The database was created successfully."
        }
      }
    },
    "delete": {
      "tags": [
        "database"
      ],
        "summary": "Delete database",
        "description": "Delete database",
        "responses": {
        "200": {
          "description": "Success",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    }
  },
  "/{db}/_compact": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "database"
      ],
        "summary": "Compact the database",
        "description": "This request deletes obsolete backup revisions. When a new revision is created, the body of the previous non-conflicting revision is temporarily stored in a separate document. These backup documents are set to expire after 5 minutes. Calling the _compact endpoint will remove these backup documents immediately.\n",
        "responses": {
        "200": {
          "description": "Request completed successfully.",
            "schema": {
            "type": "object",
              "properties": {
              "revs": {
                "type": "integer",
                  "description": "Count of the number of revisions that were compacted away."
              }
            }
          }
        }
      }
    }
  },
  "/{db}/_config": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "database"
      ],
        "summary": "Database configuration",
        "description": "Returns the Sync Gateway configuration of the database specified in the URL. This is a good method to check if a particular key was set correctly on the config file.\n",
        "responses": {
        "200": {
          "description": "Sync Gateway configuration of the running instance."
        }
      }
    },
    "put": {
      "tags": [
        "database"
      ],
        "summary": "Update database configuration",
        "description": "This request updates the configuration for the database specified in the URL.",
        "parameters": [
        {
          "in": "body",
          "name": "body",
          "description": "The message body is a JSON document with the same set of properties described in the Database configuration section of the configuration file documentation.",
          "schema": {
            "type": "object"
          }
        }
      ],
        "responses": {
        "201": {
          "description": "Created"
        }
      }
    }
  },
  "/{db}/_design/{ddoc}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/ddoc"
      }
    ],
      "get": {
      "tags": [
        "query"
      ],
        "summary": "Get Views of a design document",
        "description": "Query a design document.\n",
        "responses": {
        "200": {
          "description": "Views for design document",
            "schema": {
            "type": "object",
              "properties": {
              "my_view_name": {
                "$ref": "#/definitions/View"
              }
            }
          }
        }
      }
    },
    "put": {
      "tags": [
        "query"
      ],
        "summary": "Update views of a design document",
        "parameters": [
        {
          "in": "body",
          "name": "body",
          "description": "The request body",
          "required": false,
          "schema": {
            "$ref": "#/definitions/View"
          }
        }
      ],
        "responses": {
        "201": {
          "description": "Successful operation",
            "schema": {
            "$ref": "#/definitions/Success"
          }
        }
      }
    },
    "delete": {
      "tags": [
        "query"
      ],
        "summary": "Delete design document",
        "description": "Delete a design document.\n",
        "responses": {
        "200": {
          "description": "The status",
            "schema": {
            "type": "object",
              "items": {
              "$ref": "#/definitions/Design"
            }
          }
        },
        "default": {
          "description": "Unexpected error",
            "schema": {
            "$ref": "#/definitions/Error"
          }
        }
      }
    }
  },
  "/{db}/_offline": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "database"
      ],
        "summary": "This request takes the specified database offline.",
        "description": "Taking a database offline:\n\n- Cleanly closes all active _changes feeds for this database.\n- Rejects all access to the database through the Public REST API (503 Service Unavailable).\n- Rejects most Admin API requests (503 Service Unavailable). Sync Gateway processes a small set of Admin API \nrequests.\n- Does not take the backing Couchbase Server bucket offline. The bucket remains available and Sync Gateway \nkeeps its connection to the bucket.\n\nFor more information about taking a database offline and bringing it back online, see Taking databases offline and bringing them online.\n",
        "responses": {
        "200": {
          "description": "Database brought online"
        }
      }
    }
  },
  "/{db}/_online": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "database"
      ],
        "summary": "Bring a database online.",
        "description": "This request brings the specified database online, either immediately or after a specified delay.\n\nBringing a database online:\n\n- Closes the datbases connection to the backing Couchbase Server bucket.\n- Reloads the databse configuration, and connects to the backing Cocuhbase Server bucket.\n- Re-establishes access to the database from the Public REST API.\n- Accepts all Admin API reqieste.\n\nFor more information about taking a database offline and bringing it back online, see Taking databases \noffline and bringing them online.\n",
        "parameters": [
        {
          "in": "body",
          "name": "body",
          "description": "Optional request body to specify a delay.",
          "required": false,
          "schema": {
            "type": "object",
            "properties": {
              "delay": {
                "type": "integer",
                "description": "Delay in seconds before bringing the database online."
              }
            }
          }
        }
      ],
        "responses": {
        "200": {
          "description": "OK â€“ online request accepted."
        },
        "503": {
          "description": "Service Unavailable â€“ Database resync is in progress."
        }
      }
    }
  },
  "/{db}/_purge": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "document"
      ],
        "summary": "Purge document",
        "description": "When an application deletes a document a tombstone revision is created, over time the number of tombstones can become significant. Tombstones allow document deletions to be propagated to other clients via replication. For some applications the replication of a tombstone may not be useful after a period of time. The purge command provides a way to remove the tombstones from a Sync Gateway database, recovering storage space and reducing the amount of data replicated to clients.\n",
        "parameters": [
        {
          "in": "body",
          "name": "body",
          "description": "The message body is a JSON document that contains the following objects.",
          "schema": {
            "$ref": "#/definitions/PurgeBody"
          }
        }
      ],
        "responses": {
        "200": {
          "description": "OK â€“ The purge operation was successful",
            "schema": {
            "type": "object",
              "description": "Response object",
              "properties": {
              "a_doc_id": {
                "type": "array",
                  "description": "Contains one property for each document ID successfully purged, the property key is the \"docID\" and the property value is a list containing the single entry \"*\".",
                  "items": {
                  "type": "string",
                    "description": "Revision ID that was purged"
                }
              }
            }
          }
        }
      }
    }
  },
  "/{db}/_raw/{doc}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/doc"
      }
    ],
      "get": {
      "tags": [
        "document"
      ],
        "summary": "Document with metadata",
        "description": "Returns the document with the metadata.",
        "responses": {
        "200": {
          "description": "hello",
            "schema": {
            "$ref": "#/definitions/DocMetadata"
          }
        }
      }
    }
  },
  "/{db}/_resync": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "database"
      ],
        "summary": "Reprocess all documents by the database in the sync function.",
        "description": "This request causes all documents to be reprocessed by the database sync function. The _resync operation should be called if the sync function for a databse has been modified in such a way that the channel or access mappings for any existing document would change as a result.\n\nWhen the sync function is invoked by _resync, the requireUser() and requireRole() calls will always return 'true'.\n\nA _resync operation on a database that is not in the offline state will be rejected (503 Service Unavailable).\n\nA _resync operation will block until all documents in the database have been processed.\n",
        "responses": {
        "200": {
          "description": "OK â€“ The _resync operation has completed",
            "schema": {
            "type": "object",
              "description": "The number of documents that were successfully updated.",
              "properties": {
              "changes": {
                "type": "integer",
                  "description": "The number of documents that were successfully updated"
              }
            }
          }
        }
      }
    }
  },
  "/{db}/_role": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "database"
      ],
        "summary": "Get roles",
        "description": "This request returns all the roles in the specified database.",
        "responses": {
        "200": {
          "description": "200 OK â€“ Returns the list of roles as an array of strings",
            "schema": {
            "type": "array",
              "description": "The message body contains the list of roles in a JSON array. Each element of the array is a string representing the name of a role in the specified database.",
              "items": {
              "type": "string"
            }
          }
        }
      }
    },
    "post": {
      "tags": [
        "database"
      ],
        "summary": "Role",
        "description": "This request creates a new role in the specified database.",
        "parameters": [
        {
          "$ref": "#/parameters/role"
        }
      ],
        "responses": {
        "201": {
          "description": "201 OK â€“ The role was created successfully"
        },
        "409": {
          "description": "409 Conflict â€“ A role with this name already exists"
        }
      }
    }
  },
  "/{db}/_role/{name}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/name"
      }
    ],
      "get": {
      "tags": [
        "database"
      ],
        "summary": "Get role",
        "description": "Request a specific role by name.",
        "responses": {
        "200": {
          "description": "The response contains information about this role.",
            "schema": {
            "type": "object",
              "properties": {
              "name": {
                "type": "string"
              },
              "admin_channels": {
                "type": "array",
                  "description": "The admin channels that this role has granted access to. Admin channels are the ones which were \ngranted access to in the config file or via the Admin REST API.\n",
                  "items": {
                  "type": "string"
                }
              },
              "all_channels": {
                "type": "array",
                  "description": "All the channels that this role has access to."
              }
            }
          }
        }
      }
    },
    "put": {
      "tags": [
        "role"
      ],
        "summary": "Creates or updates a role",
        "description": "This request creates or updates a role in the specified database.",
        "parameters": [
        {
          "$ref": "#/parameters/role"
        }
      ],
        "responses": {
        "200": {
          "description": "200 OK â€“ The role was updated successfully"
        },
        "201": {
          "description": "201 Created â€“ The role was created successfully"
        }
      }
    },
    "delete": {
      "tags": [
        "role"
      ],
        "summary": "Deletes the role",
        "description": "This request deletes the role with the specified name in the specified database.",
        "responses": {
        "200": {
          "description": "200 OK â€“ The role was successfully deleted"
        }
      }
    }
  },
  "/{db}/_session": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "post": {
      "tags": [
        "session"
      ],
        "summary": "Creates a new session",
        "description": "This request creates a new session in the specified database.\n",
        "parameters": [
        {
          "in": "body",
          "name": "SessionBody",
          "description": "The message body is a JSON document that contains the following objects.",
          "schema": {
            "type": "object",
            "properties": {
              "name": {
                "type": "string",
                "description": "Username of the user the session will be associated to."
              },
              "ttl": {
                "description": "Default is 24 hours (86400 seconds). The TTL (time-to-live) of the session, in seconds.",
                "type": "integer",
                "default": 86400
              }
            }
          }
        }
      ],
        "responses": {
        "200": {
          "description": "Session successfully created.",
            "schema": {
            "type": "object",
              "properties": {
              "cookie_name": {
                "type": "string",
                  "description": "Cookie used for session handling"
              },
              "expires": {
                "type": "string",
                  "description": "Expiration time for session."
              },
              "session_id": {
                "type": "string",
                  "description": "Session ID."
              }
            }
          }
        }
      }
    }
  },
  "/{db}/_session/{sessionid}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/sessionid"
      }
    ],
      "get": {
      "tags": [
        "session"
      ],
        "summary": "Retrieves information about a session",
        "description": "This request retrieves information about a session.\n",
        "responses": {
        "200": {
          "description": "200 OK â€“ Request completed successfully.",
            "schema": {
            "type": "object",
              "properties": {
              "authentication_handlers": {
                "type": "array",
                  "items": {
                  "type": "object",
                    "description": "List of supported authentication handlers"
                }
              },
              "ok": {
                "type": "boolean",
                  "description": "Success flag"
              },
              "userCtx": {
                "type": "object",
                  "description": "Contains an object with properties channels (the list of channels for the user associated with the session) and name (the user associated with the session)"
              }
            }
          }
        }
      }
    },
    "delete": {
      "tags": [
        "session"
      ],
        "summary": "Deletes a single session",
        "description": "This request deletes a single session.\n",
        "responses": {
        "200": {
          "description": "200 OK â€“ Request completed successfully. If the session is successfully deleted, the response has an empty message body. If the session is not deleted, the message body contains error information."
        }
      }
    }
  },
  "/{db}/_user/{name}/_session": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/name"
      }
    ],
      "delete": {
      "tags": [
        "session"
      ],
        "summary": "Deletes all user sessions",
        "description": "This request delete the session for the specified user.",
        "responses": {
        "200": {
          "description": "User session deleted."
        }
      }
    }
  },
  "/{db}/_user/{name}/_session/{sessionid}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/name"
      },
      {
        "$ref": "#/parameters/sessionid"
      }
    ],
      "delete": {
      "tags": [
        "session"
      ],
        "summary": "Deletes a specific user session",
        "description": "This request delete the specified session for the specified user.",
        "responses": {
        "200": {
          "description": "User session deleted."
        }
      }
    }
  },
  "/{db}/_user/": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      }
    ],
      "get": {
      "tags": [
        "user"
      ],
        "summary": "Retrieves all users",
        "description": "This request returns all the users in the specified database.",
        "responses": {
        "200": {
          "description": "The message body contains the list of users in a JSON array. Each element of the array is a string representing the name of a user in the specified database.",
            "schema": {
            "type": "array",
              "items": {
              "type": "string",
                "description": "username"
            }
          }
        }
      }
    },
    "post": {
      "tags": [
        "user"
      ],
        "summary": "Creates a new user",
        "description": "This request creates a new user in the specified database.",
        "parameters": [
        {
          "$ref": "#/parameters/user"
        }
      ],
        "responses": {
        "201": {
          "description": "201 OK â€“ The user was created successfully"
        },
        "409": {
          "description": "409 Conflict â€“ A user with this name already exists"
        }
      }
    }
  },
  "/{db}/_user/{name}": {
    "parameters": [
      {
        "$ref": "#/parameters/db"
      },
      {
        "$ref": "#/parameters/name"
      }
    ],
      "get": {
      "tags": [
        "user"
      ],
        "summary": "Retrieves a specific user",
        "description": "This request returns information about the specified user.",
        "responses": {
        "200": {
          "description": "200 OK â€“ Returns information about the specified user",
            "schema": {
            "$ref": "#/definitions/User"
          }
        }
      }
    },
    "put": {
      "tags": [
        "user"
      ],
        "summary": "Creates or updates a user",
        "description": "This request creates or updates a user in the specified database.",
        "parameters": [
        {
          "$ref": "#/parameters/user"
        }
      ],
        "responses": {
        "200": {
          "description": "200 OK â€“ The user record was updated successfully"
        },
        "201": {
          "description": "201 Created â€“ The user record was created successfully"
        }
      }
    },
    "delete": {
      "tags": [
        "user"
      ],
        "summary": "Deletes a user",
        "description": "This request deletes the user with the specified name in the specified database.",
        "responses": {
        "200": {
          "description": "200 OK â€“ The user was successfully deleted"
        }
      }
    }
  }
},
  "definitions": {
  "DocMetadata": {
    "type": "object",
      "properties": {
      "_sync": {
        "type": "object",
          "properties": {
          "rev": {
            "type": "string",
              "description": "Revision number of the current revision"
          },
          "sequence": {
            "type": "integer",
              "description": "Sequence number of this document"
          },
          "recent_sequences": {
            "type": "array",
              "items": {
              "type": "integer",
                "description": "Previous sequence numbers"
            }
          },
          "parents": {
            "type": "array",
              "items": {
              "type": "integer",
                "description": "N/A"
            }
          },
          "history": {
            "type": "object",
              "properties": {
              "revs": {
                "type": "array",
                  "items": {
                  "type": "string",
                    "description": "N/A"
                }
              },
              "parents": {
                "type": "array",
                  "items": {
                  "type": "integer",
                    "description": "N/A"
                }
              },
              "channels": {
                "type": "array",
                  "items": {
                  "type": "string",
                    "description": "N/A"
                }
              },
              "time_saved": {
                "type": "string",
                  "description": "Timestamp of the last operation?"
              }
            }
          }
        }
      }
    }
  },
  "Error": {
    "type": "object",
      "properties": {
      "code": {
        "type": "integer",
          "format": "int32"
      },
      "message": {
        "type": "string"
      },
      "fields": {
        "type": "string"
      }
    }
  },
  "ExpVars": {
    "type": "object",
      "properties": {
      "cmdline": {
        "type": "object",
          "description": "Built-in variables from the Go runtime, lists the command-line arguments"
      },
      "memstats": {
        "type": "object",
          "description": "Dumps a large amount of information about the memory heap and garbage collector"
      },
      "cb": {
        "type": "object",
          "description": "Variables reported by the Couchbase SDK (go_couchbase package)"
      },
      "mc": {
        "type": "object",
          "description": "Variables reported by the low-level memcached API (gomemcached package)"
      },
      "syncGateway_changeCache": {
        "type": "object",
          "properties": {
          "maxPending": {
            "type": "object",
              "description": "Max number of sequences waiting on a missing earlier sequence number"
          },
          "lag-tap-0000ms": {
            "type": "object",
              "description": "Histogram of delay from doc save till it shows up in Tap feed"
          },
          "lag-queue-0000ms": {
            "type": "object",
              "description": "Histogram of delay from Tap feed till doc is posted to changes feed"
          },
          "lag-total-0000ms": {
            "type": "object",
              "description": "Histogram of total delay from doc save till posted to changes feed"
          },
          "outOfOrder": {
            "type": "object",
              "description": "Number of out-of-order sequences posted"
          },
          "view_queries": {
            "type": "object",
              "description": "Number of queries to channels view"
          }
        }
      },
      "syncGateway_db": {
        "type": "object",
          "properties": {
          "channelChangesFeeds": {
            "type": "object",
              "description": "Number of calls to db.changesFeed, i.e. generating a changes feed for a single channel."
          },
          "channelLogAdds": {
            "type": "object",
              "description": "Number of entries added to channel logs"
          },
          "channelLogAppends": {
            "type": "object",
              "description": "Number of times entries were written to channel logs using an APPEND operation"
          },
          "channelLogCacheHits": {
            "type": "object",
              "description": "Number of requests for channel-logs that were fulfilled from the in-memory cache"
          },
          "channelLogRewrites": {
            "type": "object",
              "description": "Number of times entries were written to channel logs using a SET operation (rewriting the entire log)"
          },
          "channelLogRewriteCollisions": {
            "type": "object",
              "description": "Number of collisions while attempting to rewrite channel logs using SET"
          },
          "document_gets": {
            "type": "object",
              "description": "Number of times a document was read from the database"
          },
          "revisionCache_adds": {
            "type": "object",
              "description": "Number of revisions added to the revision cache"
          },
          "revisionCache_hits": {
            "type": "object",
              "description": "Number of times a revision-cache lookup succeeded"
          },
          "revisionCache_misses": {
            "type": "object",
              "description": "Number of times a revision-cache lookup failed"
          },
          "revs_added": {
            "type": "object",
              "description": "Number of revisions added to the database (including deletions)"
          },
          "sequence_gets": {
            "type": "object",
              "description": "Number of times the database's lastSequence was read"
          },
          "sequence_reserves": {
            "type": "object",
              "description": "Number of times the database's lastSequence was incremented"
          }
        }
      }
    }
  },
  "LogTags": {
    "type": "object",
      "properties": {
      "Access": {
        "type": "boolean",
          "description": "access() calls made by the sync function"
      },
      "Attach": {
        "type": "boolean",
          "description": "Attachment processing"
      },
      "Auth": {
        "type": "boolean",
          "description": "Authentication"
      },
      "Bucket": {
        "type": "boolean",
          "description": "Sync Gateway interactions with the bucket (verbose logging)."
      },
      "Cache": {
        "type": "boolean",
          "description": "Interactions with Sync Gateway's in-memory channel cache (Cache+ for verbose logging)"
      },
      "Changes": {
        "type": "boolean",
          "description": "Processing of _changes requests (Changes+ for verbose logging)"
      },
      "CRUD": {
        "type": "boolean",
          "description": "Updates made by Sync Gateway to documents (CRUD+ for verbose logging)"
      },
      "DCP": {
        "type": "boolean",
          "description": "DCP-feed processing (verbose logging)"
      },
      "Events": {
        "type": "boolean",
          "description": "Event processing (webhooks) (Events+ for verbose logging)"
      },
      "Feed": {
        "type": "boolean",
          "description": "Server-feed processing (Feed+ for verbose logging)"
      },
      "HTTP": {
        "type": "boolean",
          "description": "All requests made to the Sync Gateway REST APIs (Sync and Admin). Note that the log keyword HTTP is always enabled, which means that HTTP requests and error responses are always logged (in a non-verbose manner). HTTP+ provides more verbose HTTP logging."
      }
    }
  },
  "PurgeBody": {
    "type": "object",
      "description": "Document ID",
      "properties": {
      "a_doc_id": {
        "type": "array",
          "description": "List containing the revision numbers to purge for the given docID. Passing \"*\" as an item in the array will remove all the revisions for that document.",
          "items": {
          "type": "string",
            "description": "Revision ID to delete or \"*\" to delete all the revisions of the document."
        }
      }
    }
  },
  "Success": {
    "type": "object",
      "properties": {
      "id": {
        "type": "string",
          "description": "Design document identifier"
      },
      "rev": {
        "type": "string",
          "description": "Revision identifier"
      },
      "ok": {
        "type": "boolean",
          "description": "Indicates whether the operation was successful"
      }
    }
  },
  "User": {
    "type": "object",
      "properties": {
      "name": {
        "type": "string",
          "description": "Name of the user that will be created"
      },
      "password": {
        "type": "string",
          "description": "Password of the user that will be created. Required, unless the allow_empty_password Sync Gateway per-database configuration value is set to true, in which case the password can be omitted."
      },
      "admin_channels": {
        "type": "array",
          "description": "Array of channel names to give the user access to",
          "items": {
          "type": "string",
            "description": "Channel name"
        }
      },
      "admin_roles": {
        "type": "array",
          "description": "Array of role names to assign to this user",
          "items": {
          "type": "string",
            "description": "Role name"
        }
      },
      "email": {
        "type": "string",
          "description": "Email of the user that will be created."
      },
      "disabled": {
        "type": "boolean",
          "description": "Boolean property to disable this user. The user will not be able to login if this property is set to true."
      }
    }
  },
  "ChangesFeedRow": {
    "type": "object",
      "properties": {
      "changes": {
        "type": "array",
          "description": "List of the documentâ€™s leafs. Each leaf object contains one field, rev.",
          "items": {
          "type": "string"
        }
      },
      "id": {
        "type": "string",
          "description": "Document identifier"
      },
      "seq": {
        "type": "integer",
          "description": "Update sequence number"
      }
    }
  },
  "InvalidJSON": {
    "description": "The request provided invalid JSON data"
  },
  "View": {
    "type": "object",
      "properties": {
      "_rev": {
        "type": "string",
          "description": "Revision identifier of the parent revision the new one should replace. (Not used when creating a new document.)"
      },
      "views": {
        "type": "object",
          "description": "List of views to save on this design document.",
          "properties": {
          "my_view_name": {
            "type": "object",
              "description": "The view's map/reduce functions.",
              "properties": {
              "map": {
                "type": "string",
                  "description": "Inline JavaScript definition for the map function"
              },
              "reduce": {
                "type": "string",
                  "description": "Inline JavaScript definition for the reduce function"
              }
            }
          }
        }
      }
    }
  },
  "QueryRow": {
    "type": "object",
      "properties": {
      "id": {
        "type": "string",
          "description": "The ID of the document"
      },
      "key": {
        "type": "object",
          "description": "The key in the output row"
      },
      "value": {
        "type": "object",
          "description": "The value in the output row"
      }
    }
  },
  "Design": {
    "type": "object",
      "properties": {
      "offset": {
        "type": "integer",
          "format": "int32",
          "description": "Position in pagination."
      },
      "limit": {
        "type": "integer",
          "format": "int32",
          "description": "Number of items to retrieve (100 max)."
      },
      "count": {
        "type": "integer",
          "format": "int32",
          "description": "Total number of items available."
      }
    }
  },
  "AllDocs": {
    "type": "object",
      "properties": {
      "keys": {
        "type": "array",
          "description": "List of identifiers of the documents to retrieve",
          "items": {
          "type": "string",
            "description": "Document ID"
        }
      }
    }
  },
  "Changes": {
    "type": "object",
      "properties": {
      "last_seq": {
        "type": "integer",
          "description": "Last change sequence number"
      },
      "results": {
        "type": "array",
          "description": "List of changes to the database. See the following table for a list of fields in this object.",
          "items": {
          "$ref": "#/definitions/ChangesFeedRow"
        }
      }
    }
  },
  "Database": {
    "type": "object",
      "properties": {
      "db_name": {
        "type": "string",
          "description": "Name of the database"
      },
      "db_uuid": {
        "type": "integer",
          "description": "Database identifier"
      },
      "disk_format_version": {
        "type": "integer",
          "description": "Database schema version"
      },
      "disk_size": {
        "type": "integer",
          "description": "Total amount of data stored on the disk (in bytes)"
      },
      "instance_start_time": {
        "type": "string",
          "description": "Date and time the database was opened (in microseconds since 1 January 1970)"
      },
      "update_seq": {
        "type": "string",
          "description": "Number of updates to the database"
      }
    }
  },
  "Document": {
    "type": "object",
      "properties": {
      "_id": {
        "type": "string",
          "description": "The document ID."
      },
      "_rev": {
        "type": "string",
          "description": "Revision identifier of the parent revision the new one should replace. (Not used when creating a new document.)"
      },
      "_exp": {
        "type": "string",
          "description": "Expiry time after which the document will be purged. The expiration time is set and managed on the Couchbase Server document (TTL is not supported for databases in walrus mode). The value can be specified in two ways; in ISO-8601 format, for example the 6th of July 2016 at 17:00 in the BST timezone would be 2016-07-06T17:00:00+01:00; it can also be specified as a numeric Couchbase Server expiry value. Couchbase Server expiries are specified as Unix time, and if the desired TTL is below 30 days then it can also represent an interval in seconds from the current time (for example, a value of 5 will remove the document 5 seconds after it is written to Couchbase Server). The document expiration time is returned in the response of GET /{db}/{doc} when show_exp=true is included in the querystring.\n\nAs with the existing explicit purge mechanism, this applies only to the local database; it has nothing to do with replication. This expiration time is not propagated when the document is replicated. The purge of the document does not cause it to be deleted on any other database.\n"
      }
    }
  },
  "QueryResult": {
    "type": "object",
      "properties": {
      "offset": {
        "type": "string",
          "description": "Starting index of the returned rows."
      },
      "row": {
        "type": "array",
          "items": {
          "$ref": "#/definitions/QueryRow"
        }
      },
      "total_rows": {
        "type": "integer",
          "description": "Number of documents in the database. This number is not the number of rows returned."
      }
    }
  },
  "Replication": {
    "type": "object",
      "properties": {
      "ok": {
        "type": "boolean",
          "description": "Indicates whether the replication operation was successful"
      },
      "session_id": {
        "type": "string",
          "description": "Session identifier"
      }
    }
  },
  "Server": {
    "type": "object",
      "properties": {
      "couchdb": {
        "type": "string",
          "description": "Contains the string 'Welcome' (this is required for compatibility with CouchDB)"
      },
      "vendor/name": {
        "type": "string",
          "description": "The server type ('Couchbase Sync Gateway)"
      },
      "vendor/version": {
        "type": "string",
          "description": "The server version"
      },
      "version": {
        "type": "string",
          "description": "Sync Gateway version number"
      }
    }
  },
  "Session": {
    "type": "object",
      "properties": {
      "authentication_handlers": {
        "type": "array",
          "description": "List of authentication methods.",
          "items": {
          "type": "string"
        }
      },
      "ok": {
        "type": "boolean",
          "description": "Always true if the operation was successful."
      },
      "userCtx": {
        "$ref": "#/definitions/UserContext"
      }
    }
  },
  "UserContext": {
    "type": "object",
      "description": "Context for this user.",
      "properties": {
      "channels": {
        "type": "object",
          "description": "Key-value pairs with a channel name as the key and the sequence number that granted the user access to the channel as value. `!` is the public channel and every user has access to it."
      },
      "name": {
        "type": "string",
          "description": "The user's name."
      }
    }
  }
}
}