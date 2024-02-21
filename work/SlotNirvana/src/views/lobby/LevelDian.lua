--
--大厅关卡容器节点 用来放JACKPOT 或者一列多个关卡情况
--
local LevelDian = class("LevelDian", util_require("base.BaseView"))



function LevelDian:initUI()
    self:createCsbNode("newIcons/Level_Dian.csb")
    self.liangdian = self:findChild("liangdian")
    self.andian = self:findChild("andian")
end


function LevelDian:setState(isShow)
    if isShow == true then
        self.liangdian:setVisible(true)
        self.andian:setVisible(false)
    else
        self.liangdian:setVisible(false)
        self.andian:setVisible(true)
    end
end
return LevelDian
