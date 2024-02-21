---
--xcyy
--2018年5月23日
--AChristmasCarolRespinGrandBar.lua
local AChristmasCarolRespinGrandBar = class("AChristmasCarolRespinGrandBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "AChristmasCarolPublicConfig"

function AChristmasCarolRespinGrandBar:initUI(params)
    self.m_machine = params.machine
    self.m_grandStarSpine = {}

    self:createCsbNode("AChristmasCarol_respinbar.csb")

    for index = 1, 5 do
        self.m_grandStarSpine[index] = util_spineCreate("AChristmasCarol_respinbar_star", true, true)
        self:findChild("star_"..index):addChild(self.m_grandStarSpine[index], 1)
        self.m_grandStarSpine[index]:setVisible(false)

        self.m_grandStarSpine[index].grandZiNode = util_createAnimation("AChristmasCarol_respinbar_star_zi.csb")
        util_spinePushBindNode(self.m_grandStarSpine[index], "zi", self.m_grandStarSpine[index].grandZiNode)
    end

    self.m_triggerSpine = util_spineCreate("AChristmasCarol_respinbar_chufa", true, true)
    self:findChild("Node_chufa_tx"):addChild(self.m_triggerSpine)
    self.m_triggerSpine:setVisible(false)
end

--[[
    刷新 grand 显示
]]
function AChristmasCarolRespinGrandBar:updateRespinGrand()
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    if rsExtraData.five and #rsExtraData.five > 0 then
        local fiveNum = 0
        for _col, _data in ipairs(rsExtraData.five) do
            if _data == 1 then
                fiveNum = fiveNum + 1
            end
        end
        if fiveNum >= 5 then
            rsExtraData.five = {0,0,0,0,0}
        end

        for _col, _data in ipairs(rsExtraData.five) do
            if _data == 1 then
                self.m_grandStarSpine[_col]:setVisible(true)
                util_spinePlay(self.m_grandStarSpine[_col], "idle", true)
                self.m_grandStarSpine[_col].grandZiNode:findChild("light_".._col):setVisible(true)
            else
                self.m_grandStarSpine[_col]:setVisible(false)
            end
        end
    end
    self:playJiManEffectByChaYiGe()
end

--[[
    grand待集满动画 
]]
function AChristmasCarolRespinGrandBar:playJiManEffectByChaYiGe( )
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
    local collectNum = 0
    local noCollectCol = 0
    if rsExtraData.five and #rsExtraData.five > 0 then
        for _col, _data in ipairs(rsExtraData.five) do
            if _data == 1 then
                collectNum = collectNum + 1
            else
                noCollectCol = _col
            end
        end
    end
    if collectNum == 4 then
        local nodeName = {"g_tx", "r_tx", "a_tx", "n_tx", "d_tx"}
        self:runCsbAction("idle1", true)
        for _col, _nodeName in ipairs(nodeName) do
            if noCollectCol == _col then
                self:findChild(_nodeName):setVisible(true)
            else
                self:findChild(_nodeName):setVisible(false)
            end
        end
    else
        self:runCsbAction("idle", false)
    end
end

--[[
    播放触发动画
]]
function AChristmasCarolRespinGrandBar:playTriggerEffect(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_respin_grand_trigger)

    self.m_triggerSpine:setVisible(true)
    util_spinePlay(self.m_triggerSpine, "actionframe", false)
    for index = 1, 5 do
        self.m_grandStarSpine[index]:setVisible(true)
        util_spinePlay(self.m_grandStarSpine[index], "actionframe", false)
        util_spineEndCallFunc(self.m_grandStarSpine[index], "actionframe", function ()
            self.m_grandStarSpine[index]:setVisible(false)
        end)
    end
    performWithDelay(self, function()
        self.m_triggerSpine:setVisible(false)
        if _func then
            _func()
        end
    end, 2)
end

--[[
    respin结算的时候 grand字停止动画
]]
function AChristmasCarolRespinGrandBar:playResetEffect( )
    self:runCsbAction("idle", false)
    for index = 1, 5 do
        if self.m_grandStarSpine[index]:isVisible() then 
            util_spinePlay(self.m_grandStarSpine[index], "idle1", false)
        end
    end
end

return AChristmasCarolRespinGrandBar