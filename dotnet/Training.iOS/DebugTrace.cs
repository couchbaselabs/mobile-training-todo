﻿//
// DebugTrace.cs
//
// Author:
// 	Jim Borden  <jim.borden@couchbase.com>
//
// Copyright (c) 2016 Couchbase, Inc All rights reserved.
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
using System;
using System.Diagnostics;
using MvvmCross.Platform.Platform;

namespace Training.iOS
{
    public class DebugTrace : IMvxTrace
    {
        public void Trace(MvxTraceLevel level, string tag, Func<string> message)
        {
            Debug.WriteLine(tag + ":" + level + ":" + message());
        }

        public void Trace(MvxTraceLevel level, string tag, string message)
        {
            Debug.WriteLine(tag + ":" + level + ":" + message);
        }

        public void Trace(MvxTraceLevel level, string tag, string message, params object[] args)
        {
            try {
                Debug.WriteLine(tag + ":" + level + ":" + message, args);
            } catch(FormatException) {
                Trace(MvxTraceLevel.Error, tag, "Exception during trace of {0} {1}", level, message);
            }
        }
    }
}