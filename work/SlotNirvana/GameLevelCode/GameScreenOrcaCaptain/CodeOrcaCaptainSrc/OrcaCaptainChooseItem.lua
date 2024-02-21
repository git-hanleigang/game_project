---
--xcyy
--2018年5月23日
--OrcaCaptainChooseItem.lua
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainChooseItem = class("OrcaCaptainChooseItem",util_require("Levels.BaseLevelDialog"))

local page_num = {
    max = 15,
    mid = 10,
    min = 7
}

function OrcaCaptainChooseItem:initUI(params)

    self:createCsbNode("OrcaCaptain_Choose_0.csb")

    self.index = params.index
    self.m_machine = params.machine

    self:addClick(self:findChild("Panel_1")) -- 非按钮节点得手动绑定监听
    self:showZiForPage(self.index)

end

function OrcaCaptainChooseItem:initSpineUI()
    self.spineNode = util_spineCreate("OrcaCaptain_Choose_piao", true, true)
    self:findChild("Node_spine"):addChild(self.spineNode)
    self.spineNode:setVisible(false)
end

function OrcaCaptainChooseItem:showZiForPage(index)
    if index == 1 then
        self:findChild("Node_20"):setVisible(true)
        self:findChild("Node_15"):setVisible(false)
        self:findChild("Node_10"):setVisible(false)
        self:findChild("Node_7"):setVisible(false)
    elseif index == 2 then
        self:findChild("Node_20"):setVisible(false)
        self:findChild("Node_15"):setVisible(true)
        self:findChild("Node_10"):setVisible(false)
        self:findChild("Node_7"):setVisible(false)
    elseif index == 3 then
        self:findChild("Node_20"):setVisible(false)
        self:findChild("Node_15"):setVisible(false)
        self:findChild("Node_10"):setVisible(true)
        self:findChild("Node_7"):setVisible(false)
    else
        self:findChild("Node_20"):setVisible(false)
        self:findChild("Node_15"):setVisible(false)
        self:findChild("Node_10"):setVisible(false)
        self:findChild("Node_7"):setVisible(true)
    end
end

function OrcaCaptainChooseItem:setSpineVisible(isShow)
    self.spineNode:setVisible(isShow)
end

function OrcaCaptainChooseItem:showIdleAct()
    self.m_allowClick = true
    self:setSpineVisible(false)
    self:findChild("Node_yaan"):setVisible(false)
    self:runCsbAction("idle2",true) -- 播放时间线
end

function OrcaCaptainChooseItem:showIdleAct2()
    self.m_allowClick = true
    self:setSpineVisible(false)
    self:findChild("Node_yaan"):setVisible(true)
    self:runCsbAction("idle4",true) -- 播放时间线
end

function OrcaCaptainChooseItem:showDarkAct()
    self:setSpineVisible(true)
    self:runCsbAction("darkstart")
    util_spinePlay(self.spineNode, "idle2")
end

function OrcaCaptainChooseItem:showSelectAct()
    local actName = "actionframe"
    self:setSpineVisible(true)
    self:runCsbAction(actName,false,function ()
        self:runCsbAction("idle3",true)
    end)
    util_spinePlay(self.spineNode, "actionframe")
end

function OrcaCaptainChooseItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_allowClick then
        return
    end
    if self.m_machine.m_machine.m_betLevel <= 0 and self.index == 1 then
        self.m_allowClick = false
        self:runCsbAction("dianji",false,function ()
            -- self:showIdleAct()
            self:findChild("Node_yaan"):setVisible(false)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_ThreeToOne_click)
            self.m_machine:clickEndEveryPageState(self.index)
            -- self.m_allowClick = true
        end)
        --需要修改下方bet
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
        return
    end
    
    if name == "Panel_1" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_ThreeToOne_click)
        self.m_machine:clickEndEveryPageState(self.index)
    end
end

function OrcaCaptainChooseItem:setAllowClick(isClick)
    self.m_allowClick = isClick
end


return OrcaCaptainChooseItem