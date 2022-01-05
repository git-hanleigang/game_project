using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace slotTool
{
    public partial class WinEncry : Form
    {
        public WinEncry()
        {
            InitializeComponent();
        }

        string oldFoler = "";

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void btnEncry_Click(object sender, EventArgs e)
        {
            if (richTextBox1.Text == "")
            {
                return;
            }
            string clsid = "{645FF040-5081-101B-9F08-00AA002F954E}";
            if (richTextBox2.Text != "")
            {
                clsid = richTextBox2.Text;
                clsid = clsid.Replace(" ", "");
            }
            Directory.Move(richTextBox1.Text, richTextBox1.Text + "." + clsid);
            richTextBox1.Text = richTextBox1.Text + "." + clsid;
        }

        private void btnDecrypt_Click(object sender, EventArgs e)
        {
            string oriFoler = richTextBox1.Text;
            if (oriFoler == oldFoler)
            {
                int indexStart = oriFoler.IndexOf(".{");
                oldFoler = oriFoler.Substring(0, indexStart);
            }
            Directory.Move(richTextBox1.Text, oldFoler);
            richTextBox1.Text = oldFoler;
        }

        public void encry_DragOver(object sender, DragEventArgs e, string str)
        {
            string fileInfo = str;
            if (!Directory.Exists(fileInfo))
            {
                return;
            }
            richTextBox1.Text = fileInfo;
            oldFoler = fileInfo;
        }

        private void richTextBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void richTextBox2_TextChanged(object sender, EventArgs e)
        {

        }
    }
}
