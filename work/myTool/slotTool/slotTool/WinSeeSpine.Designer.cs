namespace slotTool
{
    partial class WinSeeSpine
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.label1 = new System.Windows.Forms.Label();
            this.richTextBox2 = new System.Windows.Forms.RichTextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.btnShowSpine = new System.Windows.Forms.Button();
            this.textWidth = new System.Windows.Forms.TextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.textHeight = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.textScale = new System.Windows.Forms.TextBox();
            this.label17 = new System.Windows.Forms.Label();
            this.textSpineName = new System.Windows.Forms.TextBox();
            this.btnCopy = new System.Windows.Forms.Button();
            this.textBoxSpineName = new System.Windows.Forms.RichTextBox();
            this.label6 = new System.Windows.Forms.Label();
            this.label9 = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.textSpineEnd = new System.Windows.Forms.TextBox();
            this.textSpineStart = new System.Windows.Forms.TextBox();
            this.timer = new System.Windows.Forms.Timer(this.components);
            this.labelTip1 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(31, 35);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(341, 24);
            this.label1.TabIndex = 0;
            this.label1.Text = "请拖入skeleton.json 文件 或者输入.json 文件 所在的文件夹\r\n或者拖入.plist文件/.fnt文件\r\n";
            // 
            // richTextBox2
            // 
            this.richTextBox2.Location = new System.Drawing.Point(33, 74);
            this.richTextBox2.Name = "richTextBox2";
            this.richTextBox2.Size = new System.Drawing.Size(453, 74);
            this.richTextBox2.TabIndex = 2;
            this.richTextBox2.Text = "";
            this.richTextBox2.TextChanged += new System.EventHandler(this.richTextBox2_TextChanged);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(31, 174);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(239, 12);
            this.label2.TabIndex = 3;
            this.label2.Text = "请拖入或输入 需要加入的背景图（可不加）\r\n";
            // 
            // btnShowSpine
            // 
            this.btnShowSpine.Location = new System.Drawing.Point(299, 263);
            this.btnShowSpine.Name = "btnShowSpine";
            this.btnShowSpine.Size = new System.Drawing.Size(187, 39);
            this.btnShowSpine.TabIndex = 43;
            this.btnShowSpine.Text = "显示spine动画/plist粒子";
            this.btnShowSpine.UseVisualStyleBackColor = true;
            this.btnShowSpine.Click += new System.EventHandler(this.btnShowSpine_Click);
            // 
            // textWidth
            // 
            this.textWidth.Location = new System.Drawing.Point(65, 247);
            this.textWidth.Name = "textWidth";
            this.textWidth.Size = new System.Drawing.Size(76, 21);
            this.textWidth.TabIndex = 45;
            this.textWidth.TextChanged += new System.EventHandler(this.textWidth_TextChanged);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(31, 253);
            this.label4.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(29, 12);
            this.label4.TabIndex = 46;
            this.label4.Text = "宽度";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(31, 290);
            this.label3.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(29, 12);
            this.label3.TabIndex = 47;
            this.label3.Text = "高度";
            // 
            // textHeight
            // 
            this.textHeight.Location = new System.Drawing.Point(65, 287);
            this.textHeight.Name = "textHeight";
            this.textHeight.Size = new System.Drawing.Size(76, 21);
            this.textHeight.TabIndex = 48;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(31, 331);
            this.label5.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(53, 12);
            this.label5.TabIndex = 49;
            this.label5.Text = "缩放比例";
            // 
            // textScale
            // 
            this.textScale.Location = new System.Drawing.Point(89, 328);
            this.textScale.Name = "textScale";
            this.textScale.Size = new System.Drawing.Size(76, 21);
            this.textScale.TabIndex = 50;
            // 
            // label17
            // 
            this.label17.AutoSize = true;
            this.label17.Location = new System.Drawing.Point(31, 373);
            this.label17.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label17.Name = "label17";
            this.label17.Size = new System.Drawing.Size(59, 12);
            this.label17.TabIndex = 63;
            this.label17.Text = "spine数量";
            // 
            // textSpineName
            // 
            this.textSpineName.Location = new System.Drawing.Point(89, 370);
            this.textSpineName.Margin = new System.Windows.Forms.Padding(2);
            this.textSpineName.Name = "textSpineName";
            this.textSpineName.Size = new System.Drawing.Size(76, 21);
            this.textSpineName.TabIndex = 64;
            // 
            // btnCopy
            // 
            this.btnCopy.Location = new System.Drawing.Point(325, 328);
            this.btnCopy.Name = "btnCopy";
            this.btnCopy.Size = new System.Drawing.Size(141, 41);
            this.btnCopy.TabIndex = 65;
            this.btnCopy.Text = "复制所需文件";
            this.btnCopy.UseVisualStyleBackColor = true;
            this.btnCopy.Click += new System.EventHandler(this.btnCopy_Click);
            // 
            // textBoxSpineName
            // 
            this.textBoxSpineName.Location = new System.Drawing.Point(538, 74);
            this.textBoxSpineName.Name = "textBoxSpineName";
            this.textBoxSpineName.Size = new System.Drawing.Size(181, 401);
            this.textBoxSpineName.TabIndex = 66;
            this.textBoxSpineName.Text = "";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(323, 200);
            this.label6.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(131, 12);
            this.label6.TabIndex = 67;
            this.label6.Text = "当前spine动画 总数: 0";
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(210, 228);
            this.label9.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(107, 12);
            this.label9.TabIndex = 68;
            this.label9.Text = "输入显示 索引范围";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(387, 231);
            this.label10.Margin = new System.Windows.Forms.Padding(2, 0, 2, 0);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(17, 12);
            this.label10.TabIndex = 71;
            this.label10.Text = "到";
            // 
            // textSpineEnd
            // 
            this.textSpineEnd.Location = new System.Drawing.Point(420, 225);
            this.textSpineEnd.Margin = new System.Windows.Forms.Padding(2);
            this.textSpineEnd.Name = "textSpineEnd";
            this.textSpineEnd.Size = new System.Drawing.Size(43, 21);
            this.textSpineEnd.TabIndex = 70;
            // 
            // textSpineStart
            // 
            this.textSpineStart.Location = new System.Drawing.Point(329, 225);
            this.textSpineStart.Margin = new System.Windows.Forms.Padding(2);
            this.textSpineStart.Name = "textSpineStart";
            this.textSpineStart.Size = new System.Drawing.Size(43, 21);
            this.textSpineStart.TabIndex = 69;
            // 
            // timer
            // 
            this.timer.Tick += new System.EventHandler(this.timer_Tick);
            // 
            // labelTip1
            // 
            this.labelTip1.AutoSize = true;
            this.labelTip1.Font = new System.Drawing.Font("宋体", 27.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.labelTip1.ForeColor = System.Drawing.Color.OrangeRed;
            this.labelTip1.Location = new System.Drawing.Point(170, 212);
            this.labelTip1.Name = "labelTip1";
            this.labelTip1.Size = new System.Drawing.Size(0, 37);
            this.labelTip1.TabIndex = 72;
            // 
            // WinSeeSpine
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(884, 561);
            this.Controls.Add(this.labelTip1);
            this.Controls.Add(this.label10);
            this.Controls.Add(this.textSpineEnd);
            this.Controls.Add(this.textSpineStart);
            this.Controls.Add(this.label9);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.textBoxSpineName);
            this.Controls.Add(this.btnCopy);
            this.Controls.Add(this.textSpineName);
            this.Controls.Add(this.label17);
            this.Controls.Add(this.textScale);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.textHeight);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.textWidth);
            this.Controls.Add(this.btnShowSpine);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.richTextBox2);
            this.Controls.Add(this.label1);
            this.Name = "WinSeeSpine";
            this.Text = "WinSeeSpine";
            this.Load += new System.EventHandler(this.WinSeeSpine_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.RichTextBox richTextBox2;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button btnShowSpine;
        private System.Windows.Forms.TextBox textWidth;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox textHeight;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.TextBox textScale;
        private System.Windows.Forms.Label label17;
        private System.Windows.Forms.TextBox textSpineName;
        private System.Windows.Forms.Button btnCopy;
        private System.Windows.Forms.RichTextBox textBoxSpineName;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.TextBox textSpineEnd;
        private System.Windows.Forms.TextBox textSpineStart;
        private System.Windows.Forms.Timer timer;
        private System.Windows.Forms.Label labelTip1;
    }
}