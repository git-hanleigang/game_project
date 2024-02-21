
local BlackFridayReSpinExplainView = class("BlackFridayReSpinExplainView", util_require("Levels.BaseLevelDialog"))

--fixios0223
function BlackFridayReSpinExplainView:initUI(data)
    self.m_click = false
    self.m_isCanClick = true
    self.m_machine = data.machine
    self.m_callBackFunc = data.callBackFunc

    local resourceFilename = "BlackFriday_respin_tanban.csb"
    self:createCsbNode(resourceFilename)

    self:addClick(self:findChild("Panel_1"))

    self:findChild("Node_1"):setScale(self.m_machine.m_machineRootScale)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_respin_explain_chuxian)

    self:runCsbAction("start", false, function()
        
        self.m_isCanClick = false
        self:runCsbAction("idle", false, function()
            
            self.m_isCanClick = true
            if self.m_click then
                return 
            end

            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_respin_explain_xiaoshi)
            self:runCsbAction("over", false, function()
                self.m_callBackFunc()

                self:removeFromParent()
            end)
        end)
    end)
end

function BlackFridayReSpinExplainView:onEnter()
    BlackFridayReSpinExplainView.super.onEnter(self)
end

function BlackFridayReSpinExplainView:onExit()
    BlackFridayReSpinExplainView.super.onExit(self)
end

function BlackFridayReSpinExplainView:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        if self.m_click == true then
            return
        end

        if self.m_isCanClick then
            return
        end

        self:removeSelf()
    end
end

function BlackFridayReSpinExplainView:removeSelf()
    self.m_click = true
    
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_respin_explain_xiaoshi)
    self:runCsbAction("over", false, function()
        self.m_callBackFunc()
        
        self:removeFromParent()
    end)
end

return BlackFridayReSpinExplainView