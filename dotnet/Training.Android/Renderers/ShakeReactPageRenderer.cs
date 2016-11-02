//
// ShakeReactPageRenderer.cs
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
using System.Threading;
using System.Threading.Tasks;

using Android.Hardware;
using Xamarin.Forms;
using Xamarin.Forms.Platform.Android;

namespace Training.Android
{
    // http://stackoverflow.com/a/23146330/1155387
    public abstract class ShakeReactPageRenderer : PageRenderer, ISensorEventListener
    {

        bool hasUpdated = false;
        DateTime lastUpdate;
        float last_x = 0.0f;
        float last_y = 0.0f;
        float last_z = 0.0f;
        private int _isCoolingDown;

        const int ShakeDetectionTimeLapse = 250;
        const double ShakeThreshold = 800;

        protected abstract void HandleShake();

        protected override void OnAttachedToWindow()
        {
            base.OnAttachedToWindow();

            // Register this as a listener with the underlying service.
            var sensorManager = Context.GetSystemService(global::Android.Content.Context.SensorService) as SensorManager;
            var sensor = sensorManager.GetDefaultSensor(SensorType.Accelerometer);
            sensorManager.RegisterListener(this, sensor, SensorDelay.Normal);
        }

        protected override void OnDetachedFromWindow()
        {
            base.OnDetachedFromWindow();

            var sensorManager = Context.GetSystemService(global::Android.Content.Context.SensorService) as SensorManager;
            var sensor = sensorManager.GetDefaultSensor(SensorType.Accelerometer);
            sensorManager.UnregisterListener(this);
        }

        #region ISensorEventListener

        public void OnAccuracyChanged(Sensor sensor, SensorStatus accuracy)
        {
        }

        public void OnSensorChanged(SensorEvent e)
        {
            if(!this.Element.IsVisible) {
                return;    
            }

            if(e.Sensor.Type == SensorType.Accelerometer) {
                float x = e.Values[0];
                float y = e.Values[1];
                float z = e.Values[2];

                DateTime curTime = System.DateTime.Now;
                if(hasUpdated == false) {
                    hasUpdated = true;
                    lastUpdate = curTime;
                    last_x = x;
                    last_y = y;
                    last_z = z;
                } else {
                    if((curTime - lastUpdate).TotalMilliseconds > ShakeDetectionTimeLapse) {
                        float diffTime = (float)(curTime - lastUpdate).TotalMilliseconds;
                        lastUpdate = curTime;
                        float total = x + y + z - last_x - last_y - last_z;
                        float speed = Math.Abs(total) / diffTime * 10000;

                        if(speed > ShakeThreshold && Interlocked.CompareExchange(ref _isCoolingDown, 1, 0) == 0) {
                            Task.Delay(5000).ContinueWith(t => Interlocked.Exchange(ref _isCoolingDown, 0));
                            HandleShake();
                        }

                        last_x = x;
                        last_y = y;
                        last_z = z;
                    }
                }
            }
        }
        #endregion
    }
}
