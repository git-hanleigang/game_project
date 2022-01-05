using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace slotTool
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
        }

        public string slotsFolderDir = "";
        private string curExeDir = Application.ExecutablePath;

        private List<Button> programBtnList = new List<Button>();
        private string curShowFormName = "";
        private string curSelectSlotsDir = "";


        WinUseMost winUseMost;
        WinSeeSpine winSeeSpine;
        WinEncry winEncry;



        private void MainForm_Load(object sender, EventArgs e)
        {
            slotsFolderDir = Common.tryGetConfigInfo(this, curExeDir);
            curSelectSlotsDir = "game2";

            winUseMost = new WinUseMost();
            winSeeSpine = new WinSeeSpine();
            winEncry = new WinEncry();

            //programBtnList.Add(btnMain);

            if (slotsFolderDir != "")
            {
                CommonChangePage(winUseMost);
                this.Text = "slots工具集合-版本号";
            }
            else
            {
                MessageBox.Show("当前为没有选择您需要的弹窗");
            }

        }

        private void panelMainShow_Paint(object sender, PaintEventArgs e)
        {

        }

        private void CommonChangePage(Form curForm)
        {
            if (curForm.Name == curShowFormName)
            {
                return;
            }

            this.panelMainShow.Controls.Clear();
            curForm.TopLevel = false;
            curForm.FormBorderStyle = FormBorderStyle.None;
            curForm.Dock = System.Windows.Forms.DockStyle.Fill;
            this.panelMainShow.Controls.Add(curForm);
            curForm.Show();
            curShowFormName = curForm.Name;
        }

        private bool tryShowMainDialog()
        {
            if (slotsFolderDir == "")
            {
                MessageBox.Show("当前为没有选择您需要的弹窗");
            }
            return false;
        }

        private void btnMain_Click(object sender, EventArgs e)
        {
            if (tryShowMainDialog())
            {
                return;
            }
            CommonChangePage(winUseMost);
        }

        private void btnSeeSpine_Click(object sender, EventArgs e)
        {
            CommonChangePage(winSeeSpine);
        }

        private void MainForm_DragEnter(object sender, DragEventArgs e)
        {
            string dragInfo = ((System.Array)e.Data.GetData(DataFormats.FileDrop)).GetValue(0).ToString();
            if (curShowFormName == winSeeSpine.Name)
            {
                winSeeSpine.seeSpine_DragOver(sender, e, dragInfo);
            }else if (curShowFormName == winEncry.Name)
            {
                winEncry.encry_DragOver(sender, e, dragInfo);
            }
        }

        private void panelBtn_Paint(object sender, PaintEventArgs e)
        {

        }

        private void btnEncryFile_Click(object sender, EventArgs e)
        {
            CommonChangePage(winEncry);
        }
    }
}
