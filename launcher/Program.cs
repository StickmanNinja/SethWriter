// Writer for Windows: installer and launcher in one small exe.
// On each run it installs itself for the current user (no admin rights needed), writes the editor page next to it,
// makes sure there are Start menu and Desktop shortcuts and an entry in Apps & features (so it can be uninstalled
// like any other app), then opens the editor in its own app window using Microsoft Edge, or Google Chrome when Edge
// is missing (older Windows), or the default browser as a last resort.
// Works on Windows 7 SP1, 8, 8.1, 10 and 11 (x86, x64 and ARM). Needs .NET Framework 4, which is built into Windows 8 and later.
// Written for the C# 5 compiler that comes with Windows, so no newer language features.
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("Writer")]
[assembly: AssemblyProduct("Writer")]
[assembly: AssemblyDescription("Writer, a simple word processor")]
[assembly: AssemblyVersion("1.2.0.0")]
[assembly: AssemblyFileVersion("1.2.0.0")]

static class Program
{
    const string AppName = "Writer";
    const string Version = "1.2.0";
    const string OldName = "SethWriter";   // the app's first name; its documents move over on first run
    const string UninstallKey = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\Writer";
    const string HomePage = "https://github.com/StickmanNinja/SethWriter";

    [STAThread]
    static int Main(string[] args)
    {
        bool quiet = HasArg(args, "--quiet");
        try
        {
            string programs = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs");
            string appDir = Path.Combine(programs, AppName);
            string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
            string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            string startMenuLink = Path.Combine(startMenu, AppName + ".lnk");
            string desktopLink = Path.Combine(desktop, AppName + ".lnk");

            if (HasArg(args, "--uninstall"))
            {
                if (!quiet && MessageBox.Show("Remove Writer and the documents saved in it?\n\nUse File › Download first to keep a copy of anything you need.",
                        AppName, MessageBoxButtons.OKCancel, MessageBoxIcon.Warning) != DialogResult.OK) return 0;
                Uninstall(appDir, startMenuLink, desktopLink, quiet);
                return 0;
            }

            Directory.CreateDirectory(appDir);

            // 1. Install: copy this exe to %LOCALAPPDATA%\Programs\Writer, unless it is already running from there.
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

            // 2. Move documents and shortcuts over from SethWriter, the app's old name.
            MoveFromOldName(programs, appDir, startMenu, desktop);

            // 3. Write the editor page that is packed inside this exe.
            string page = Path.Combine(appDir, AppName + ".html");
            WriteResource(AppName + ".html", page);

            // 4. Shortcuts and the Apps & features entry. The Desktop shortcut is only made on first install,
            //    so deleting it keeps it gone.
            if (!HasArg(args, "--no-shortcuts"))
            {
                if (!File.Exists(startMenuLink) || !runningInstalled) MakeShortcut(startMenuLink, target, appDir);
                if (firstInstall) MakeShortcut(desktopLink, target, appDir);
            }
            Register(target, appDir);

            // 5. Open the editor in its own window.
            if (!HasArg(args, "--no-launch")) Launch(page, appDir);

            if (firstInstall && !runningInstalled && !quiet)
            {
                MessageBox.Show(
                    "Writer is installed.\n\nOpen it any time from the Start menu or the Writer shortcut on your Desktop. " +
                    "To pin it to the taskbar, right-click Writer in the Start menu and choose Pin to taskbar.\n\n" +
                    "You can delete the file you downloaded. To remove Writer later, use Apps & features (or Programs and Features) in Windows Settings.",
                    AppName, MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            return 0;
        }
        catch (Exception ex)
        {
            if (!quiet) MessageBox.Show("Writer couldn't start.\n\n" + ex.Message, AppName, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    static void Launch(string page, string appDir)
    {
        string url = new Uri(page).AbsoluteUri;
        string edge = FindBrowser("msedge.exe", @"Microsoft\Edge\Application\msedge.exe");
        string chrome = edge == null ? FindBrowser("chrome.exe", @"Google\Chrome\Application\chrome.exe") : null;
        string browser = edge ?? chrome;
        if (browser != null)
        {
            // A private profile keeps your documents with Writer. Edge and Chrome each get their own.
            string profile = Path.Combine(appDir, edge != null ? "Profile" : "ChromeProfile");
            var psi = new ProcessStartInfo(browser,
                "--app=\"" + url + "\" --user-data-dir=\"" + profile + "\" --no-first-run --no-default-browser-check --window-size=1280,860");
            psi.UseShellExecute = false;
            Process.Start(psi);
        }
        else
        {
            Process.Start(new ProcessStartInfo(page) { UseShellExecute = true });   // last resort: the default browser
        }
    }

    // SethWriter kept its documents in %LOCALAPPDATA%\Programs\SethWriter\Profile. Move them into Writer's folder,
    // remove the old shortcuts, then the old folder. If SethWriter is open right now this is tried again next time.
    static void MoveFromOldName(string programs, string appDir, string startMenu, string desktop)
    {
        string oldDir = Path.Combine(programs, OldName);
        if (!Directory.Exists(oldDir)) return;
        try
        {
            foreach (string name in new[] { "Profile", "ChromeProfile" })
            {
                string from = Path.Combine(oldDir, name), to = Path.Combine(appDir, name);
                if (Directory.Exists(from) && !Directory.Exists(to)) Directory.Move(from, to);
            }
            foreach (string dir in new[] { startMenu, desktop })
            {
                string link = Path.Combine(dir, OldName + ".lnk");
                if (File.Exists(link)) File.Delete(link);
            }
            Directory.Delete(oldDir, true);
        }
        catch (IOException) { }
        catch (UnauthorizedAccessException) { }
    }

    // Lists Writer in Apps & features (Windows 10/11) and Programs and Features (Windows 7/8) for this user.
    static void Register(string exe, string appDir)
    {
        try
        {
            using (RegistryKey k = Registry.CurrentUser.CreateSubKey(UninstallKey))
            {
                k.SetValue("DisplayName", AppName);
                k.SetValue("DisplayVersion", Version);
                k.SetValue("DisplayIcon", exe + ",0");
                k.SetValue("Publisher", AppName);
                k.SetValue("InstallLocation", appDir);
                k.SetValue("UninstallString", "\"" + exe + "\" --uninstall");
                k.SetValue("QuietUninstallString", "\"" + exe + "\" --uninstall --quiet");
                k.SetValue("URLInfoAbout", HomePage);
                k.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
                k.SetValue("EstimatedSize", 400, RegistryValueKind.DWord);   // KB
                k.SetValue("NoModify", 1, RegistryValueKind.DWord);
                k.SetValue("NoRepair", 1, RegistryValueKind.DWord);
            }
        }
        catch (Exception) { }   // not being listed is no reason to stop Writer from opening
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

    static string FindBrowser(string exeName, string relativePath)
    {
        string appPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" + exeName;
        foreach (RegistryKey hive in new[] { Registry.CurrentUser, Registry.LocalMachine })
        {
            using (RegistryKey k = hive.OpenSubKey(appPath))
            {
                string p = k == null ? null : k.GetValue("") as string;
                if (!string.IsNullOrEmpty(p)) p = p.Trim('"');
                if (!string.IsNullOrEmpty(p) && File.Exists(p)) return p;
            }
        }
        foreach (Environment.SpecialFolder f in new[] { Environment.SpecialFolder.ProgramFilesX86, Environment.SpecialFolder.ProgramFiles, Environment.SpecialFolder.LocalApplicationData })
        {
            string root = Environment.GetFolderPath(f);
            if (string.IsNullOrEmpty(root)) continue;
            string p = Path.Combine(root, relativePath);
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
            lt.InvokeMember("Description", BindingFlags.SetProperty, null, link, new object[] { "Writer, a simple word processor" });
            lt.InvokeMember("IconLocation", BindingFlags.SetProperty, null, link, new object[] { target + ",0" });
            lt.InvokeMember("Save", BindingFlags.InvokeMethod, null, link, null);
        }
        finally
        {
            if (link != null) Marshal.ReleaseComObject(link);
            Marshal.ReleaseComObject(shell);
        }
    }

    static void Uninstall(string appDir, string startMenuLink, string desktopLink, bool quiet)
    {
        foreach (string p in new[] { startMenuLink, desktopLink }) { try { if (File.Exists(p)) File.Delete(p); } catch { } }
        try { Registry.CurrentUser.DeleteSubKeyTree(UninstallKey); } catch { }
        // The running exe can't delete itself, so a short-lived command removes the folder once this process exits.
        // ping is used as the delay because it works on every Windows version, even without a console.
        Process.Start(new ProcessStartInfo("cmd.exe", "/c ping 127.0.0.1 -n 3 >nul & rmdir /s /q \"" + appDir + "\"")
        { CreateNoWindow = true, UseShellExecute = false });
        if (!quiet) MessageBox.Show("Writer has been removed, along with the documents saved in it.", AppName, MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}
