
local BeastlyBeautyEnterGameView = class("BeastlyBeautyEnterGameView", util_require("Levels.BaseLevelDialog"))

--fixios0223
function BeastlyBeautyEnterGameView:initUI(data)
    self.m_click = true
    self.m_machine = data

    local resourceFilename = "BeastlyBeauty/BaseStart.csb"
    self:createCsbNode(resourceFilename)

    self:addClick(self:findChild("Panel_1"))

    self:findChild("root"):setScale(self.m_machine.m_machineRootScale)

    -- 弹板上的光
    local tanbanShine = util_createAnimation("BeastlyBeauty/BeastlyBeauty_freetb_shine.csb")
    self:findChild("Node_shine"):addChild(tanbanShine)
    tanbanShine:runCsbAction("idle",true)

    local guangSpine = util_spineCreate("BeastlyBeauty_tanban_guang", true, true)
    self:findChild("Node_guang1"):addChild(guangSpine)
    util_spinePlay(guangSpine,"idle",true)

    self:runCsbAction("start", false, function()
        self.m_click = false
        self:runCsbAction("idle", false, function()
            self.m_isCanClick = true
            if self.m_click then
                return 
            end
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_enter_tanban_over)
            self:runCsbAction("over", false, function()
                self:removeFromParent()
            end)
        end)
    end)
end

function BeastlyBeautyEnterGameView:onEnter()
    BeastlyBeautyEnterGameView.super.onEnter(self)
end

function BeastlyBeautyEnterGameView:onExit()
    BeastlyBeautyEnterGameView.super.onExit(self)
end

function BeastlyBeautyEnterGameView:clickFunc(sender)
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

function BeastlyBeautyEnterGameView:removeSelf()
    self.m_click = true
    
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BeastlyBeauty_enter_tanban_over)
    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end)
end

return BeastlyBeautyEnterGameView