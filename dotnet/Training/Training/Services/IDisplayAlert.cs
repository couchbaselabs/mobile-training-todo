using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace Training.Services
{
    public interface IDisplayAlert
    {
        Task DisplayAlertAsync(string title, string message, string cancel);
        Task<bool> DisplayAlertAsync(string title, string message, string accept, string cancel);
        Task<string> DisplayActionSheetAsync(string title, string cancel, string destruction, params string[] buttons);
    }
}
