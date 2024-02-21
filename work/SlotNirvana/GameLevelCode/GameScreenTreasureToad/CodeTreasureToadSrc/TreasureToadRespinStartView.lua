---
--xcyy
--2018年5月23日
--TreasureToadRespinStartView.lua

local TreasureToadRespinStartView = class("TreasureToadRespinStartView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

function TreasureToadRespinStartView:initUI(params)
    self:createCsbNode("TreasureToad/RespinStart.csb")
    self.endFunc = params.endFunc
    self:addSpineForView()
    self:showAllAct()
end

function TreasureToadRespinStartView:addSpineForView()
    local ziSg = util_spineCreate("TreasureToad_zi_sg",true,true)
    util_spinePlay(ziSg, "idle3",true)
    self:findChild("Node_sg"):addChild(ziSg)
end

function TreasureToadRespinStartView:showAllAct()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_reSpin_start_show)
    self:runCsbAction("start")
    util_spinePlay(self.tanbanSpine, "start")
    self:delayCallBack(35/60,function ()
        self:runCsbAction("idle",true)
    end)
    self:delayCallBack(35/60 + 2.5,function ()
        self:hideAllAct()
    end)
end

function TreasureToadRespinStartView:hideAllAct()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_reSpin_start_hide)
    self:runCsbAction("over")
    self:delayCallBack(30/60,function ()
        if self.endFunc then
            self.endFunc()
        end
        self:removeFromParent()
    end)
end

--[[
    延迟回调
]]
function TreasureToadRespinStartView:delayCallBack(time, func)
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

return TreasureToadRespinStartView