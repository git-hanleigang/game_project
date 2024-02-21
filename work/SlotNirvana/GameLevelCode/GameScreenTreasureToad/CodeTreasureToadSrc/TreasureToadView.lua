---
--xcyy
--2018年5月23日
--TreasureToadView.lua

local TreasureToadView = class("TreasureToadView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

local nameForPath = {
    "TreasureToad/FreeSpinStart.csb",
    "TreasureToad/RespinOver.csb",
}

function TreasureToadView:initUI(params)
    local path = params.path
    self:createCsbNode(nameForPath[path])
    self.endFunc = params.endFunc
    self.isAuto = params.isAuto
    if params.num then
        self:findChild("m_lb_num"):setString(params.num)
    end
    
    self.m_isClick = false
    self:addSpineForView()
    self:showAllAct()
end

function TreasureToadView:addSpineForView()
    self.tanbanSpine = util_spineCreate("TreasureToad_tanban", true, true)
    self:findChild("Node_spine"):addChild(self.tanbanSpine)
    self.buttonLighting = util_spineCreate("TreasureToad_anniu_sg", true, true)
    self:findChild("Node_sg2"):addChild(self.buttonLighting)
    self.lighting = util_createAnimation("Socre_TreasureToad_bg_guang.csb") 
    self:findChild("Node_guang"):addChild(self.lighting) 
    self.lighting:runCsbAction("idleframe",true)
end

function TreasureToadView:showAllAct()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_freeSpin_start_show)
    self:runCsbAction("start",false,function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_freeSpin_start_hideSymbol)
        self:runCsbAction("idle")
        util_spinePlay(self.tanbanSpine, "idle",true)
        util_spinePlay(self.buttonLighting, "idle1",true)
    end)
    util_spinePlay(self.tanbanSpine, "start")
    self:delayCallBack(1 + 80/60,function ()
        self.m_isClick = true
        self:runCsbAction("idle2")
    end)
    if self.isAuto then
        self:delayCallBack(2 + 80/60,function ()
            self:hideAllAct()
            self:delayCallBack(1,function ()
                if self.endFunc then
                    self.endFunc()
                end
                self:removeFromParent()
            end)
        end)
    end
end

function TreasureToadView:hideAllAct()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_freeSpin_start_hide)
    self:runCsbAction("over")
    util_spinePlay(self.tanbanSpine, "over")
end

--点击回调
function TreasureToadView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.isAuto then
        return
    end
    if not self.m_isClick then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_click)
    if name == "Button" then
        self.m_isClick = false
        self:findChild("Button"):setEnabled(false)
        self:hideAllAct()
        self:delayCallBack(1,function ()
            if self.endFunc then
                self.endFunc()
            end
            self:removeFromParent()
        end)
    end
    
end

--[[
    延迟回调
]]
function TreasureToadView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return TreasureToadView