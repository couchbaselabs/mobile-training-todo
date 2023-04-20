//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.todo;

import java.io.PrintStream;

import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;


public class Logger {
    private Logger() { }

    private static ConsoleLogger logger;

    public static void setLogger(ConsoleLogger logr) { logger = logr; }

    public static void log(String message) { log(message, null); }

    public static void log(String message, Throwable err) {
        if (null == logger) { return; }
        logger.log(LogLevel.INFO, LogDomain.DATABASE, message);
        final PrintStream logStream = ConsoleLogger.getLogStream(LogLevel.INFO);
        if (err != null) { err.printStackTrace(logStream); }
    }
}
