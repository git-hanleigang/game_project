local FairyDragonAddLineTips = class("FairyDragonAddLineTips", util_require("base.BaseView"))

function FairyDragonAddLineTips:initUI()
    self:createCsbNode("FairyDragon_shuzi.csb")
    self.m_labNum = self:findChild("BitmapFontLabel_0")
    self.m_bUpdate = false
end

function FairyDragonAddLineTips:setNum(_num)
    self.m_bUpdate = true
    self.m_startNum = 1
    self.m_num = _num
    self.m_labNum:setString(self.m_startNum)

end

function FairyDragonAddLineTips:onEnter()
    schedule(
        self,
        function()
            if self.m_bUpdate then
                self:updataNum()
            end
        end,
        0.1
    )
end

function FairyDragonAddLineTips:onExit()
end

function FairyDragonAddLineTips:updataNum()
    if self.m_startNum >= self.m_num then
        if self.m_bUpdate then
            self.m_bUpdate = false
        end
        return
    end
    if self.m_startNum < self.m_num then
        self.m_startNum = self.m_startNum + 1
    end
    self.m_labNum:setString(self.m_startNum)
end

return FairyDragonAddLineTips
