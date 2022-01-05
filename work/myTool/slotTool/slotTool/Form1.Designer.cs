namespace slotTool
{
    partial class MainForm
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要修改
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MainForm));
            this.panelMainShow = new System.Windows.Forms.Panel();
            this.btnMain = new System.Windows.Forms.Button();
            this.panelBtn = new System.Windows.Forms.Panel();
            this.btnSeeSpine = new System.Windows.Forms.Button();
            this.btnEncryFile = new System.Windows.Forms.Button();
            this.panelBtn.SuspendLayout();
            this.SuspendLayout();
            // 
            // panelMainShow
            // 
            this.panelMainShow.Location = new System.Drawing.Point(12, 12);
            this.panelMainShow.Name = "panelMainShow";
            this.panelMainShow.Size = new System.Drawing.Size(801, 610);
            this.panelMainShow.TabIndex = 2;
            this.panelMainShow.Paint += new System.Windows.Forms.PaintEventHandler(this.panelMainShow_Paint);
            // 
            // btnMain
            // 
            this.btnMain.Location = new System.Drawing.Point(3, 3);
            this.btnMain.Name = "btnMain";
            this.btnMain.Size = new System.Drawing.Size(120, 40);
            this.btnMain.TabIndex = 3;
            this.btnMain.Text = "主界面";
            this.btnMain.UseVisualStyleBackColor = true;
            this.btnMain.Click += new System.EventHandler(this.btnMain_Click);
            // 
            // panelBtn
            // 
            this.panelBtn.Controls.Add(this.btnEncryFile);
            this.panelBtn.Controls.Add(this.btnSeeSpine);
            this.panelBtn.Controls.Add(this.btnMain);
            this.panelBtn.Location = new System.Drawing.Point(830, 12);
            this.panelBtn.Name = "panelBtn";
            this.panelBtn.Size = new System.Drawing.Size(180, 610);
            this.panelBtn.TabIndex = 4;
            this.panelBtn.Paint += new System.Windows.Forms.PaintEventHandler(this.panelBtn_Paint);
            // 
            // btnSeeSpine
            // 
            this.btnSeeSpine.Location = new System.Drawing.Point(3, 49);
            this.btnSeeSpine.Name = "btnSeeSpine";
            this.btnSeeSpine.Size = new System.Drawing.Size(120, 40);
            this.btnSeeSpine.TabIndex = 4;
            this.btnSeeSpine.Text = "spine查看器";
            this.btnSeeSpine.UseVisualStyleBackColor = true;
            this.btnSeeSpine.Click += new System.EventHandler(this.btnSeeSpine_Click);
            // 
            // btnEncryFile
            // 
            this.btnEncryFile.Location = new System.Drawing.Point(3, 95);
            this.btnEncryFile.Name = "btnEncryFile";
            this.btnEncryFile.Size = new System.Drawing.Size(120, 40);
            this.btnEncryFile.TabIndex = 5;
            this.btnEncryFile.Text = "文件加密";
            this.btnEncryFile.UseVisualStyleBackColor = true;
            this.btnEncryFile.Click += new System.EventHandler(this.btnEncryFile_Click);
            // 
            // MainForm
            // 
            this.AllowDrop = true;
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1034, 634);
            this.Controls.Add(this.panelBtn);
            this.Controls.Add(this.panelMainShow);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Name = "MainForm";
            this.Text = "slots工具集合";
            this.Load += new System.EventHandler(this.MainForm_Load);
            this.DragEnter += new System.Windows.Forms.DragEventHandler(this.MainForm_DragEnter);
            this.panelBtn.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Panel panelMainShow;
        private System.Windows.Forms.Button btnMain;
        private System.Windows.Forms.Panel panelBtn;
        private System.Windows.Forms.Button btnSeeSpine;
        private System.Windows.Forms.Button btnEncryFile;
    }
}

