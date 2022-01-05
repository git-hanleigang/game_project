using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace slotTool
{
    public partial class WinSeeSpine : Form
    {
        public WinSeeSpine()
        {
            InitializeComponent();
        }

        private Thread curSpineThread;

        public string curInfo = "";
        private string curSpineName = "";
        private string fileName = "";
        private string orgTip = "";
        private int dealyCount = 1;

        private string winWidth = "1280";
        private string winHeight = "720";
        private string spineScale = "1";

        private string strWidth = "runWidth";
        private string strHeight = "runHeight";
        private string strScale = "runScale";

        private string spineFileName = "spineCocos1.6";

        private void WinSeeSpine_Load(object sender, EventArgs e)
        {
            fileName = Common.getBaseDir() + @"\" + spineFileName;
            if (Directory.Exists(fileName))
            {
                labelTip1.Visible = false;
                readConfigInfo();
                textWidth.Text = winWidth;
                textHeight.Text = winHeight;
                textScale.Text = spineScale;
                textSpineName.Text = "1";
                btnCopy.Visible = false;

                clearOldRes();
            }
            else
            {
                labelTip1.Visible = true;
                btnShowSpine.Text = "显示spine动画(失效)";
                btnShowSpine.Enabled = false;
                orgTip = labelTip1.Text;
                labelTip1.Text = "缺少所需文件，请点击下方按钮！";
                btnCopy.Visible = true;
            }
        }

        private void richTextBox2_TextChanged(object sender, EventArgs e)
        {

        }

        private void btnShowSpine_Click(object sender, EventArgs e)
        {
            if (tryShowByClickJsonFile())
            {
                return;
            }
        }

        public bool tryShowByClickJsonFile()
        {
            List<string> listTemp = Common.getCurClickIconInfo();
            if (listTemp.Count == 0)
            {
                return false;
            }
            foreach (string item in listTemp)
            {
                if (item != curInfo)
                {
                    string atlasDir = item.Replace(".png", ".atlas");
                    if (File.Exists(atlasDir))
                    {
                        tryShowActionByClickJsonFile(item);
                        return true;
                    }
                }
            }

            if (!Common.checkExistSpineDialog())
            {
                tryShowActionByClickJsonFile(curInfo);
            }
            return false;
        }

        private void tryShowActionByClickJsonFile(string fileInfo)
        {
            curInfo = fileInfo;
            richTextBox2.Text = fileInfo;
            textSpineStart.Text = "";
            textSpineEnd.Text = "";
            dealShowAction();
        }

        public void seeSpine_DragOver(object sender, DragEventArgs e, string str)
        {
            string fileInfo = str;
            if (fileInfo.EndsWith(".json") && !curInfo.Equals(fileInfo))
            {
                curInfo = fileInfo;
                richTextBox2.Text = fileInfo;

                dealShowAction();
            }
        }

        private void dealShowAction()
        {
            string spineName = setSpineKey(richTextBox2.Text);  // 获取 spineName

            updateSpineFile(richTextBox2.Text); // 获取 复制  spine 动画

            List<String> nameList = dealJsonFile();    // 获取 spine 动画名字

            writeInfo(nameList);  //  动画名写入本地 info。lua  中

            textBoxSpineName.Text = getShowInfo(nameList); //  右侧  richBox  显示 文本 更新

            int curAniNum = nameList.ToArray().Length;
            label5.Text = "当前spine动画 总数: " + curAniNum;

            if (curAniNum <= 200)
            {
                if (textSpineStart.Text == "" || textSpineEnd.Text == "")
                {
                    textSpineStart.Text = "1";
                    textSpineEnd.Text = curAniNum + "";
                }
                runExe();
            }
        }

        private string setSpineKey(string dir)
        {
            string[] infos = dir.Split('\\');
            curSpineName = infos[infos.Length - 1].Replace(".json", "");

            return curSpineName;
        }

        private void updateSpineFile(string needFilePath)
        {
            string aimsDir = fileName + @"\res\spine";

            if (!Directory.Exists(aimsDir))
            {
                Directory.CreateDirectory(aimsDir);
            }
            Clear_Files(aimsDir);

            FileInfo fileInfo = new FileInfo(needFilePath);
            DirectoryInfo fatherInfo = fileInfo.Directory;
            //string strFatherInfo = fileInfo.DirectoryName;
            //string strFatherInfo1 = fileInfo.Name;
            foreach (FileInfo NextFile in fatherInfo.GetFiles())
            {
                string tempFileName = NextFile.Name;
                if (tempFileName.StartsWith(curSpineName))
                {
                    NextFile.CopyTo(aimsDir + @"\" + tempFileName);
                }
            }

        }

        private List<string> dealJsonFile()
        {
            string jsonPath = fileName + @"\res\spine\" + curSpineName + ".json";
            StreamReader m_sr = new StreamReader(jsonPath);
            string orgInfo = m_sr.ReadToEnd();
            m_sr.Close();
            orgInfo = orgInfo.Replace("\n", "").Replace(" ", "").Replace("\t", "").Replace("\r", "");

            string strDealInfo = orgInfo.Substring(orgInfo.IndexOf("animations\":{")).Substring(13);
            int tempSymbolNum = 0;
            bool isRecording = true;
            string strKeyPaty = "";

            List<String> keyList = new List<String>();
            for (int i = 0; i < strDealInfo.Length; i++)
            {
                string strTemp = strDealInfo.Substring(i, 1);
                if (isRecording)
                {
                    strKeyPaty = strKeyPaty + strTemp;
                }
                if ("{".Equals(strTemp))
                {
                    tempSymbolNum = tempSymbolNum + 1;
                    if (isRecording)
                    {
                        keyList.Add(strKeyPaty);
                        isRecording = false;
                        strKeyPaty = "";
                    }
                }
                else if ("}".Equals(strTemp))
                {
                    tempSymbolNum = tempSymbolNum - 1;
                    if (tempSymbolNum == 0)
                    {
                        isRecording = true;
                    }
                }
            }

            for (int i = 0; i < keyList.ToArray().Length; i++)
            {
                keyList[i] = keyList[i].Replace("\":{", "").Replace("\"", "").Replace(",", "");
            }

            return keyList;
        }

        private void writeInfo(List<string> list)
        {
            string dirFilePath = fileName + @"\src\info.lua";
            string info = "tblAnimName = {";
            foreach (var item in list)
            {
                info = info + "\"" + item + "\", ";
            }
            info = info + "}";
            StreamWriter m_sw = new StreamWriter(dirFilePath);
            m_sw.Write(info);
            m_sw.Close();
        }

        private void runExe()
        {
            if (curSpineThread != null)
            {
                curSpineThread.Abort();
            }
            curSpineThread = new Thread(runSpineShowExe);
            curSpineThread.Start();
        }

        private void runSpineShowExe()
        {
            Common.tryCloseAgoSpineDialog();
            string resultStr = "";
            string strCmdStr = "start " + fileName + @"\lua-tests.exe";
            string[] cmdK = { strCmdStr };
            Common.RunCMDCommand(out resultStr, cmdK);
        }

        private string getShowInfo(List<string> List)
        {
            string strShow = "";
            string[] strList = List.ToArray();
            for (int i = 0; i < strList.ToArray().Length; i++)
            {
                strShow = strShow + strList[i] + "\n";
            }
            return strShow;
        }

        private void Clear_Files(string path)
        {
            if (Directory.Exists(path))
            {
                
                DirectoryInfo fatherInfo = new DirectoryInfo(path);
                foreach (FileInfo NextFile in fatherInfo.GetFiles())
                {
                  NextFile.Delete();
                }

                /*
                string[] filePathList = Directory.GetFiles(path);
                foreach (string filePath in filePathList)
                {
                    File.Delete(filePath);
                }
                */
            }
        }

        private void readConfigInfo()
        {
            string dirFilePath = fileName + @"\src\spineConfig.lua";
            StreamReader m_rd = new StreamReader(dirFilePath);

            string strLine = m_rd.ReadLine();
            while (strLine != null)
            {
                if (strLine.StartsWith(strWidth))
                {
                    winWidth = strLine.Replace(" ", "").Replace(strWidth + "=", "");
                }
                else if (strLine.StartsWith(strHeight))
                {
                    winHeight = strLine.Replace(" ", "").Replace(strHeight + "=", "");
                }
                else if (strLine.StartsWith(strScale))
                {
                    spineScale = strLine.Replace(" ", "").Replace(strScale + "=", "");
                }
                strLine = m_rd.ReadLine();
            }
            m_rd.Close();
        }

        private void clearOldRes()
        {
            string baseDir = fileName + @"\res";

            DirectoryInfo fatherInfo = new DirectoryInfo(baseDir);
            foreach (FileInfo NextFile in fatherInfo.GetFiles())
            {
                if (!NextFile.Name.Contains("arial.ttf") && !NextFile.Name.Contains("btn_bg.png"))
                {
                    NextFile.Delete();
                }
            }
            foreach (DirectoryInfo folder in fatherInfo.GetDirectories())
            {
                folder.Delete(true);
            }
        }

        private void textWidth_TextChanged(object sender, EventArgs e)
        {

        }

        private void btnCopy_Click(object sender, EventArgs e)
        {
            labelTip1.Text = orgTip;
            timer.Enabled = true;
            btnCopy.Enabled = false;
        }

        private void timer_Tick(object sender, EventArgs e)
        {
            if (dealyCount >= 2)
            {
                timer.Enabled = false;
                Common.CopyFolder(@"\\192.168.1.152\share\user_\user_牛永恒\commonRes\" + spineFileName, Common.baseDir + @"/" + spineFileName);
                Common.reOpenExe();
            }
            dealyCount += dealyCount;
        }
    }
}
