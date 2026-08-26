namespace Tutorial
{
    partial class Form1
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.ScriptBox = new FastColoredTextBoxNS.FastColoredTextBox();
            this.Execute = new System.Windows.Forms.Button();
            this.Clear = new System.Windows.Forms.Button();
            this.Open = new System.Windows.Forms.Button();
            this.Save = new System.Windows.Forms.Button();
            this.Attach = new System.Windows.Forms.Button();
            this.panel1 = new System.Windows.Forms.Panel();
            this.bunifuDragControl1 = new ns1.BunifuDragControl(this.components);
            this.bunifuElipse1 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse2 = new ns1.BunifuElipse(this.components);
            this.button1 = new System.Windows.Forms.Button();
            this.button2 = new System.Windows.Forms.Button();
            this.bunifuElipse3 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse4 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse5 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse6 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse7 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse8 = new ns1.BunifuElipse(this.components);
            this.bunifuElipse9 = new ns1.BunifuElipse(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.ScriptBox)).BeginInit();
            this.panel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // ScriptBox
            // 
            this.ScriptBox.AutoCompleteBracketsList = new char[] {
        '(',
        ')',
        '{',
        '}',
        '[',
        ']',
        '\"',
        '\"',
        '\'',
        '\''};
            this.ScriptBox.AutoIndentCharsPatterns = "\r\n^\\s*[\\w\\.]+(\\s\\w+)?\\s*(?<range>=)\\s*(?<range>.+)\r\n";
            this.ScriptBox.AutoScrollMinSize = new System.Drawing.Size(163, 14);
            this.ScriptBox.BackBrush = null;
            this.ScriptBox.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(25)))), ((int)(((byte)(25)))), ((int)(((byte)(25)))));
            this.ScriptBox.BracketsHighlightStrategy = FastColoredTextBoxNS.BracketsHighlightStrategy.Strategy2;
            this.ScriptBox.CharHeight = 14;
            this.ScriptBox.CharWidth = 8;
            this.ScriptBox.CommentPrefix = "--";
            this.ScriptBox.Cursor = System.Windows.Forms.Cursors.IBeam;
            this.ScriptBox.DisabledColor = System.Drawing.Color.FromArgb(((int)(((byte)(100)))), ((int)(((byte)(180)))), ((int)(((byte)(180)))), ((int)(((byte)(180)))));
            this.ScriptBox.Font = new System.Drawing.Font("Courier New", 9.75F);
            this.ScriptBox.ForeColor = System.Drawing.SystemColors.Control;
            this.ScriptBox.IndentBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(25)))), ((int)(((byte)(25)))), ((int)(((byte)(25)))));
            this.ScriptBox.IsReplaceMode = false;
            this.ScriptBox.Language = FastColoredTextBoxNS.Language.Lua;
            this.ScriptBox.LeftBracket = '(';
            this.ScriptBox.LeftBracket2 = '{';
            this.ScriptBox.LineNumberColor = System.Drawing.SystemColors.Control;
            this.ScriptBox.Location = new System.Drawing.Point(3, 31);
            this.ScriptBox.Name = "ScriptBox";
            this.ScriptBox.Paddings = new System.Windows.Forms.Padding(0);
            this.ScriptBox.RightBracket = ')';
            this.ScriptBox.RightBracket2 = '}';
            this.ScriptBox.SelectionColor = System.Drawing.Color.FromArgb(((int)(((byte)(60)))), ((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(255)))));
            this.ScriptBox.ServiceColors = ((FastColoredTextBoxNS.ServiceColors)(resources.GetObject("ScriptBox.ServiceColors")));
            this.ScriptBox.Size = new System.Drawing.Size(318, 209);
            this.ScriptBox.TabIndex = 0;
            this.ScriptBox.Text = "print(\"Tutorial\")";
            this.ScriptBox.Zoom = 100;
            // 
            // Execute
            // 
            this.Execute.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(30)))), ((int)(((byte)(30)))), ((int)(((byte)(30)))));
            this.Execute.FlatAppearance.BorderSize = 0;
            this.Execute.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.Execute.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Execute.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Execute.ForeColor = System.Drawing.SystemColors.Control;
            this.Execute.Location = new System.Drawing.Point(4, 246);
            this.Execute.Name = "Execute";
            this.Execute.Size = new System.Drawing.Size(75, 23);
            this.Execute.TabIndex = 1;
            this.Execute.Text = "Execute";
            this.Execute.UseVisualStyleBackColor = false;
            // 
            // Clear
            // 
            this.Clear.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(30)))), ((int)(((byte)(30)))), ((int)(((byte)(30)))));
            this.Clear.FlatAppearance.BorderSize = 0;
            this.Clear.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.Clear.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Clear.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Clear.ForeColor = System.Drawing.SystemColors.Control;
            this.Clear.Location = new System.Drawing.Point(78, 246);
            this.Clear.Name = "Clear";
            this.Clear.Size = new System.Drawing.Size(75, 23);
            this.Clear.TabIndex = 2;
            this.Clear.Text = "Clear";
            this.Clear.UseVisualStyleBackColor = false;
            // 
            // Open
            // 
            this.Open.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(30)))), ((int)(((byte)(30)))), ((int)(((byte)(30)))));
            this.Open.FlatAppearance.BorderSize = 0;
            this.Open.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.Open.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Open.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Open.ForeColor = System.Drawing.SystemColors.Control;
            this.Open.Location = new System.Drawing.Point(145, 246);
            this.Open.Name = "Open";
            this.Open.Size = new System.Drawing.Size(75, 23);
            this.Open.TabIndex = 3;
            this.Open.Text = "Open";
            this.Open.UseVisualStyleBackColor = false;
            // 
            // Save
            // 
            this.Save.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(30)))), ((int)(((byte)(30)))), ((int)(((byte)(30)))));
            this.Save.FlatAppearance.BorderSize = 0;
            this.Save.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.Save.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Save.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Save.ForeColor = System.Drawing.SystemColors.Control;
            this.Save.Location = new System.Drawing.Point(215, 246);
            this.Save.Name = "Save";
            this.Save.Size = new System.Drawing.Size(75, 23);
            this.Save.TabIndex = 4;
            this.Save.Text = "Save";
            this.Save.UseVisualStyleBackColor = false;
            // 
            // Attach
            // 
            this.Attach.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(30)))), ((int)(((byte)(30)))), ((int)(((byte)(30)))));
            this.Attach.FlatAppearance.BorderSize = 0;
            this.Attach.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.Attach.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Attach.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Attach.ForeColor = System.Drawing.SystemColors.Control;
            this.Attach.Location = new System.Drawing.Point(432, 246);
            this.Attach.Name = "Attach";
            this.Attach.Size = new System.Drawing.Size(75, 23);
            this.Attach.TabIndex = 5;
            this.Attach.Text = "Attach";
            this.Attach.UseVisualStyleBackColor = false;
            // 
            // panel1
            // 
            this.panel1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(25)))), ((int)(((byte)(25)))), ((int)(((byte)(25)))));
            this.panel1.Controls.Add(this.button2);
            this.panel1.Controls.Add(this.button1);
            this.panel1.Location = new System.Drawing.Point(-10, -2);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(531, 27);
            this.panel1.TabIndex = 6;
            // 
            // bunifuDragControl1
            // 
            this.bunifuDragControl1.Fixed = true;
            this.bunifuDragControl1.Horizontal = true;
            this.bunifuDragControl1.TargetControl = this.panel1;
            this.bunifuDragControl1.Vertical = true;
            // 
            // bunifuElipse1
            // 
            this.bunifuElipse1.ElipseRadius = 15;
            this.bunifuElipse1.TargetControl = this;
            // 
            // bunifuElipse2
            // 
            this.bunifuElipse2.ElipseRadius = 5;
            this.bunifuElipse2.TargetControl = this.ScriptBox;
            // 
            // button1
            // 
            this.button1.FlatAppearance.BorderSize = 0;
            this.button1.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.button1.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.button1.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.button1.ForeColor = System.Drawing.SystemColors.Control;
            this.button1.Location = new System.Drawing.Point(496, 4);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(21, 20);
            this.button1.TabIndex = 7;
            this.button1.Text = "X";
            this.button1.UseVisualStyleBackColor = true;
            // 
            // button2
            // 
            this.button2.FlatAppearance.BorderSize = 0;
            this.button2.FlatAppearance.MouseOverBackColor = System.Drawing.Color.Maroon;
            this.button2.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.button2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.button2.ForeColor = System.Drawing.SystemColors.Control;
            this.button2.Location = new System.Drawing.Point(476, 1);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(21, 23);
            this.button2.TabIndex = 8;
            this.button2.Text = "_";
            this.button2.UseVisualStyleBackColor = true;
            // 
            // bunifuElipse3
            // 
            this.bunifuElipse3.ElipseRadius = 10;
            this.bunifuElipse3.TargetControl = this.Execute;
            // 
            // bunifuElipse4
            // 
            this.bunifuElipse4.ElipseRadius = 10;
            this.bunifuElipse4.TargetControl = this.Clear;
            // 
            // bunifuElipse5
            // 
            this.bunifuElipse5.ElipseRadius = 10;
            this.bunifuElipse5.TargetControl = this.Open;
            // 
            // bunifuElipse6
            // 
            this.bunifuElipse6.ElipseRadius = 10;
            this.bunifuElipse6.TargetControl = this.Save;
            // 
            // bunifuElipse7
            // 
            this.bunifuElipse7.ElipseRadius = 10;
            this.bunifuElipse7.TargetControl = this.Attach;
            // 
            // bunifuElipse8
            // 
            this.bunifuElipse8.ElipseRadius = 25;
            this.bunifuElipse8.TargetControl = this.button1;
            // 
            // bunifuElipse9
            // 
            this.bunifuElipse9.ElipseRadius = 25;
            this.bunifuElipse9.TargetControl = this.button2;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(30)))), ((int)(((byte)(30)))), ((int)(((byte)(30)))));
            this.ClientSize = new System.Drawing.Size(510, 273);
            this.Controls.Add(this.panel1);
            this.Controls.Add(this.Attach);
            this.Controls.Add(this.Save);
            this.Controls.Add(this.Open);
            this.Controls.Add(this.Clear);
            this.Controls.Add(this.Execute);
            this.Controls.Add(this.ScriptBox);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "Form1";
            this.Text = "Sentinel UI (ColinRBLX)";
            ((System.ComponentModel.ISupportInitialize)(this.ScriptBox)).EndInit();
            this.panel1.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private FastColoredTextBoxNS.FastColoredTextBox ScriptBox;
        private System.Windows.Forms.Button Execute;
        private System.Windows.Forms.Button Clear;
        private System.Windows.Forms.Button Open;
        private System.Windows.Forms.Button Save;
        private System.Windows.Forms.Button Attach;
        private System.Windows.Forms.Panel panel1;
        private ns1.BunifuDragControl bunifuDragControl1;
        private ns1.BunifuElipse bunifuElipse1;
        private ns1.BunifuElipse bunifuElipse2;
        private System.Windows.Forms.Button button2;
        private System.Windows.Forms.Button button1;
        private ns1.BunifuElipse bunifuElipse3;
        private ns1.BunifuElipse bunifuElipse4;
        private ns1.BunifuElipse bunifuElipse5;
        private ns1.BunifuElipse bunifuElipse6;
        private ns1.BunifuElipse bunifuElipse7;
        private ns1.BunifuElipse bunifuElipse8;
        private ns1.BunifuElipse bunifuElipse9;
    }
}

