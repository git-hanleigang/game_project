using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;

namespace slotTool
{
    class Common
    {
        public static string baseDir = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        public static string configPath = baseDir + @"\slotsClumpConfig_1.txt";

        public static MainForm curMainForm;
        public static string curExeDir;
        public static string ORG_FILE_DIR;

        //检测是否存在配置文件
        public static string tryGetConfigInfo(MainForm mainForm, string dir)
        {
            curMainForm = mainForm;
            curExeDir = dir;
            ORG_FILE_DIR = dir;
            string strRes = "";

            if (!File.Exists(configPath))
            {
                return "";
            }
            StreamReader m_sr = new StreamReader(configPath);
            strRes = m_sr.ReadLine();
            m_sr.Close();
            return strRes;
        }

        public static List<string> getCurClickIconInfo()
        {
            string filename;
            List<string> resList = new List<string>();
            ArrayList selected = new ArrayList();
            SHDocVw.ShellWindows shellWindows = new SHDocVw.ShellWindows();
            foreach (SHDocVw.InternetExplorer window in shellWindows)
            {
                filename = Path.GetFileNameWithoutExtension(window.FullName).ToLower();
                if (filename.ToLowerInvariant() == "explorer" || filename.ToLowerInvariant() == "资源管理器")
                {
                    Shell32.FolderItems items = ((Shell32.IShellFolderViewDual2)window.Document).SelectedItems();
                    if (items.Count == 1)
                    {
                        foreach (Shell32.FolderItem item in items)
                        {
                            if (item.Path.EndsWith(".json"))
                            {
                                resList.Add(item.Path);
                            }
                        }
                    }
                }
            }
            return resList;
        }

        //复制 文件/文件夹
        public static int CopyFolder(string sourceFolder, string destFolder)
        {
            try
            {
                //如果目标路径不存在，则创建目标路径
                if (!System.IO.Directory.Exists(destFolder))
                {
                    System.IO.Directory.CreateDirectory(destFolder);
                }

                //得到原文件根目录下的所有文件
                string[] files = System.IO.Directory.GetFiles(sourceFolder);
                foreach (string file in files)
                {
                    string fileName = System.IO.Path.GetFileName(file);
                    string dest = System.IO.Path.Combine(destFolder, fileName);
                    System.IO.File.Copy(file, dest);
                }

                //得到原文件根目录下的所有文件夹
                string[] folders = System.IO.Directory.GetDirectories(sourceFolder);
                foreach (string folder in folders)
                {
                    string name = System.IO.Path.GetFileName(folder);
                    string dest = System.IO.Path.Combine(destFolder, name);
                    CopyFolder(folder, dest);//构建目标路径，递归复制文件
                }
                return 1;
            }
            catch(Exception e)
            {
                MessageBox.Show(e.Message);
                return 0;
            }
        }

        public static bool checkExistSpineDialog()
        {
            string tempName = "";
            foreach (System.Diagnostics.Process thisProc in System.Diagnostics.Process.GetProcesses())
            {
                tempName = thisProc.ProcessName;
                if (tempName == "lua-tests")
                    {
                    return true;
                }
            }
            return false;
        }

        public static void reOpenExe()
        {
            System.Diagnostics.Process.Start(System.Reflection.Assembly.GetExecutingAssembly().Location);
            closeExe();
        }

        public static void closeExe()
        {
            //curMainForm.closeWebSocket();
            System.Environment.Exit(0);
        }

        public static void tryCloseAgoSpineDialog()
        {
            string tempName = "";
            foreach (System.Diagnostics.Process thisProc in System.Diagnostics.Process.GetProcesses())
            {
                tempName = thisProc.ProcessName;
                if (tempName == "lua-tests")
                {
                    if (!thisProc.CloseMainWindow())
                    {
                        thisProc.Kill();//当发送关闭窗口命令无效时强行结束进程
                    }
                }
            }
        }

        //运行cmd命令
        public static void RunCMDCommand(out string outPut, params string[] command)
        {
            using (Process pc = new Process())
            {
                pc.StartInfo.FileName = "cmd.exe";
                pc.StartInfo.CreateNoWindow = false;//隐藏窗口运行
                pc.StartInfo.RedirectStandardError = true;//重定向错误流
                pc.StartInfo.RedirectStandardInput = true;//重新向输入流
                pc.StartInfo.RedirectStandardOutput = true;//重新向输入流
                pc.StartInfo.UseShellExecute = false;
                pc.Start();
                int length = command.Length;
                foreach (string com in command)
                {
                    pc.StandardInput.WriteLine(com);//输入CMD命令
                }
                pc.StandardInput.WriteLine("exit");//结束执行，很重要的
                pc.StandardInput.AutoFlush = true;

                outPut = pc.StandardOutput.ReadToEnd();//读取结果
                pc.WaitForExit();
                pc.Close();
            }
        }

        public static string getBaseDir()
        {
            return baseDir;
        }
    }
}
