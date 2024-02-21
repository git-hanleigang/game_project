---
--smy
--2018年5月24日
--FortuneTreeFSChooseView.lua
local FortuneTreeFSChooseView = class("FortuneTreeFSChooseView", util_require("base.BaseView"))
FortuneTreeFSChooseView.m_choseFsCallFun = nil
FortuneTreeFSChooseView.m_choseRespinCallFun = nil
FortuneTreeFSChooseView.m_touchFlag = nil

function FortuneTreeFSChooseView:initUI()
    self.m_featureChooseIdx = 0
    self:createCsbNode("FortuneTree/FreeSpinChoose.csb")
    local touch1 = self:findChild("touch1")
    self:addClick(touch1)
    local touch2 = self:findChild("touch2")
    self:addClick(touch2)
    local touch3 = self:findChild("touch3")
    self:addClick(touch3)
    self.m_touchFlag = false
end

function FortuneTreeFSChooseView:appear()
    self:runCsbAction("start", false, function()
        self.m_touchFlag = true
        self:runCsbAction("idle", true)
    end)
end

function FortuneTreeFSChooseView:onEnter()
    
end

function FortuneTreeFSChooseView:onExit(  )
   
end

function FortuneTreeFSChooseView:clickFunc(sender)
    if self.m_touchFlag == false then
        return 
    end
    gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_btn_choose.mp3")

    self.m_touchFlag = false
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end
function FortuneTreeFSChooseView:clickButton_CallFun(name)
    local tag = 1
    if name == "touch2" then
        tag = 2
    elseif name == "touch3" then
        tag = 3
    end
    self.m_featureChooseIdx = tag 
    self:choseOver( )
    gLobalSoundManager:playSound("LightCherrySounds/music_lightcherry_click_choose.mp3")
end


function FortuneTreeFSChooseView:choseOver()
   
    -- gLobalSoundManager:playSound("LightCherrySounds/music_lightcherry_choose_reward.mp3")
   
    self:runCsbAction("show"..self.m_featureChooseIdx, false, function()
        if self.m_callFunc then
            self.m_callFunc(self.m_featureChooseIdx)
        end
    end) 
    
end

function FortuneTreeFSChooseView:initViewData(func)
    self.m_callFunc = func
end

return FortuneTreeFSChooseView