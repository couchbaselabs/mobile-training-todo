//
//  WpfPresenter.cs
//
//  Author:
//  	Jim Borden  <jim.borden@couchbase.com>
//
//  Copyright (c) 2016 Couchbase, Inc All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;

using MvvmCross.Core.ViewModels;
using MvvmCross.Wpf.Views;

namespace Training.WPF
{
    // The logic for presenting views in WPF.  Needed to track history
    internal sealed class WpfPresenter : MvxWpfViewPresenter
    {

        #region Variables

        private readonly ContentControl _contentControl;
        private Stack<FrameworkElement> _history = new Stack<FrameworkElement>();
        private bool _first = true;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="contentControl">The parent view to swap children in</param>
        public WpfPresenter(ContentControl contentControl)
        {
            _contentControl = contentControl;
        }

        #endregion

        #region Overrides

        public override void Present(FrameworkElement frameworkElement)
        {
            if(!_first) {
                _history.Push(_contentControl.Content as FrameworkElement);
            }

            _first = false;
            _contentControl.Content = frameworkElement;
        }

        public override void ChangePresentation(MvxPresentationHint hint)
        {
            if(HandlePresentationChange(hint)) return;

            
            if(_history.Count == 0) {
                base.ChangePresentation(hint);
                return;
            }

            (_contentControl as IDisposable)?.Dispose();
            _contentControl.Content = _history.Pop();
        }

        #endregion

    }
}
