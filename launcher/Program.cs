// SethWriter launcher.
// On each run it: installs itself for the current user (no admin rights needed), writes the editor page next to it,
// makes sure there is a Start menu shortcut (and a Desktop shortcut on first install), then opens the editor in its
// own Microsoft Edge app window. Edge comes with Windows 11, so there is nothing else to install.
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("SethWriter")]
[assembly: AssemblyProduct("SethWriter")]
[assembly: AssemblyDescription("SethWriter, a simple word processor")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

static class Program
{
    const string AppName = "SethWriter";

    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            string appDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", AppName);
            string startMenuLink = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), AppName + ".lnk");
            string desktopLink = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), AppName + ".lnk");

            if (HasArg(args, "--uninstall"))
            {
                Uninstall(appDir, startMenuLink, desktopLink);
                return 0;
            }

            Directory.CreateDirectory(appDir);

            // 1. Install: copy this exe to %LOCALAPPDATA%\Programs\SethWriter, unless it is already running from there.
            string self = Assembly.GetExecutingAssembly().Location;
            string installed = Path.Combine(appDir, AppName + ".exe");
            bool runningInstalled = SamePath(self, installed);
            bool firstInstall = !File.Exists(installed);
            if (!runningInstalled)
            {
                try { File.Copy(self, installed, true); }
                catch (IOException) { }                  // the installed copy is open right now; keep using it
                catch (UnauthorizedAccessException) { }
            }
            string target = File.Exists(installed) ? installed : self;

            // 2. Write the editor page that is packed inside this exe.
            string page = Path.Combine(appDir, AppName + ".html");
            WriteResource(AppName + ".html", page);

            // 3. Shortcuts. The Desktop one is only made on first install, so deleting it keeps it gone.
            if (!HasArg(args, "--no-shortcuts"))
            {
                if (!File.Exists(startMenuLink) || !runningInstalled) MakeShortcut(startMenuLink, target, appDir);
                if (firstInstall) MakeShortcut(desktopLink, target, appDir);
            }

            // 4. Open the editor in its own window.
            string url = new Uri(page).AbsoluteUri;
            string edge = FindEdge();
            if (edge != null)
            {
                string profile = Path.Combine(appDir, "Profile");   // a private Edge profile keeps your documents with SethWriter
                var psi = new ProcessStartInfo(edge,
                    "--app=\"" + url + "\" --user-data-dir=\"" + profile + "\" --no-first-run --no-default-browser-check --window-size=1280,860");
                psi.UseShellExecute = false;
                Process.Start(psi);
            }
            else
            {
                Process.Start(new ProcessStartInfo(page) { UseShellExecute = true });   // fall back to the default browser
            }

            if (firstInstall && !runningInstalled && !HasArg(args, "--quiet"))
            {
                MessageBox.Show(
                    "SethWriter is installed.\n\nYou can open it any time from the Start menu or the SethWriter shortcut on your Desktop. " +
                    "To pin it to the taskbar, right-click SethWriter in the Start menu and choose Pin to taskbar.\n\n" +
                    "You can delete the file you downloaded.",
                    AppName, MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("SethWriter couldn't start.\n\n" + ex.Message, AppName, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    static bool HasArg(string[] args, string name)
    {
        foreach (string a in args) if (string.Equals(a, name, StringComparison.OrdinalIgnoreCase)) return true;
        return false;
    }

    static bool SamePath(string a, string b)
    {
        return string.Equals(Path.GetFullPath(a).TrimEnd('\\'), Path.GetFullPath(b).TrimEnd('\\'), StringComparison.OrdinalIgnoreCase);
    }

    static void WriteResource(string name, string path)
    {
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
        {
            if (s == null) throw new InvalidOperationException("The editor page is missing from this exe. Rebuild it with build.ps1.");
            using (FileStream f = File.Create(path)) s.CopyTo(f);
        }
    }

    static string FindEdge()
    {
        const string appPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe";
        foreach (RegistryKey hive in new[] { Registry.CurrentUser, Registry.LocalMachine })
        {
            using (RegistryKey k = hive.OpenSubKey(appPath))
            {
                string p = k == null ? null : k.GetValue("") as string;
                if (!string.IsNullOrEmpty(p) && File.Exists(p)) return p;
            }
        }
        foreach (Environment.SpecialFolder f in new[] { Environment.SpecialFolder.ProgramFilesX86, Environment.SpecialFolder.ProgramFiles })
        {
            string p = Path.Combine(Environment.GetFolderPath(f), @"Microsoft\Edge\Application\msedge.exe");
            if (File.Exists(p)) return p;
        }
        return null;
    }

    static void MakeShortcut(string linkPath, string target, string workDir)
    {
        Type shellType = Type.GetTypeFromProgID("WScript.Shell");
        if (shellType == null) return;
        object shell = Activator.CreateInstance(shellType);
        object link = null;
        try
        {
            link = shellType.InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, shell, new object[] { linkPath });
            Type lt = link.GetType();
            lt.InvokeMember("TargetPath", BindingFlags.SetProperty, null, link, new object[] { target });
            lt.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, link, new object[] { workDir });
            lt.InvokeMember("Description", BindingFlags.SetProperty, null, link, new object[] { "SethWriter, a simple word processor" });
            lt.InvokeMember("IconLocation", BindingFlags.SetProperty, null, link, new object[] { target + ",0" });
            lt.InvokeMember("Save", BindingFlags.InvokeMethod, null, link, null);
        }
        finally
        {
            if (link != null) Marshal.ReleaseComObject(link);
            Marshal.ReleaseComObject(shell);
        }
    }

    static void Uninstall(string appDir, string startMenuLink, string desktopLink)
    {
        foreach (string p in new[] { startMenuLink, desktopLink }) { try { if (File.Exists(p)) File.Delete(p); } catch { } }
        // The running exe can't delete itself, so a short-lived command removes the folder once this process exits.
        Process.Start(new ProcessStartInfo("cmd.exe", "/c timeout /t 2 /nobreak >nul & rmdir /s /q \"" + appDir + "\"")
        { CreateNoWindow = true, UseShellExecute = false });
        MessageBox.Show("SethWriter has been removed, along with the documents saved in it.", AppName, MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}
