--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-04-07 14:15:45
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-04-07 14:36:42
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/ExpandGuideLevelRuleLayer.lua
Description: 扩圈系统  扩圈玩家进入关卡 先引导 关卡规则 然后引导 noobTaskStart1
--]]
local ExpandGuideLevelRuleLayer = class("ExpandGuideLevelRuleLayer", BaseLayer)

function ExpandGuideLevelRuleLayer:initDatas()
    ExpandGuideLevelRuleLayer.super.initDatas(self)

    self.m_page = 1

    self:setLandscapeCsbName("NewUser_Expend/Activity/csd/Guide/Newuser_Slots.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("ExpandGuideLevelRuleLayer")
    self:setName("ExpandGuideLevelRuleLayer")
end

function ExpandGuideLevelRuleLayer:initView()
    -- 按钮状态
    self:updateBtnState()
    -- page页显隐
    self:updatePageUIVisible()

    self:runCsbAction("idle", true) 
end

-- 按钮状态
function ExpandGuideLevelRuleLayer:updateBtnState()
    local btnLeft = self:findChild("btn_left")
    local btnRight = self:findChild("btn_right")

    btnLeft:setVisible(self.m_page ~= 1)
    btnRight:setVisible(self.m_page ~= 2)
end

-- page页显隐
function ExpandGuideLevelRuleLayer:updatePageUIVisible()
    for i=1, 2 do
        local nodePage = self:findChild("node_rule" .. i)
        nodePage:setVisible(i == self.m_page)
    end
end

function ExpandGuideLevelRuleLayer:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_start" then
        self:closeUI()
    elseif name == "btn_left" then
        self.m_page = 1
        self:updateBtnState()
        self:updatePageUIVisible()
    elseif name == "btn_right" then
        self.m_page = 2
        self:updateBtnState()
        self:updatePageUIVisible()
    end
end

function ExpandGuideLevelRuleLayer:closeUI()
    if self.m_bCloseing then
        return
    end
    self.m_bCloseing = true

    local cb = function()
        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
    end
    ExpandGuideLevelRuleLayer.super.closeUI(self, cb)
end

return ExpandGuideLevelRuleLayer