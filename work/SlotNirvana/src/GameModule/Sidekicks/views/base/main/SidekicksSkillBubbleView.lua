--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-19 18:52:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-19 19:46:49
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/main/SidekicksSkillBubbleView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksSkillBubbleView = class("SidekicksSkillBubbleView", BaseView)

function SidekicksSkillBubbleView:initDatas(_seasonIdx, _idx)
    SidekicksSkillBubbleView.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self._idx = _idx
end

function SidekicksSkillBubbleView:getCsbName()
    return string.format("Sidekicks_%s/csd/main/Sidekicks_Main_skill_bubble.csb", self._seasonIdx)
end

function SidekicksSkillBubbleView:initCsbNodes()
    SidekicksSkillBubbleView.super.initCsbNodes(self)
end

function SidekicksSkillBubbleView:initUI()
    SidekicksSkillBubbleView.super.initUI(self)
    
    -- 加成标题显隐
    self:updateTitleVisible()
    self:setVisible(false)
end

function SidekicksSkillBubbleView:updateUI(_petInfoList)
    self._petInfoList = _petInfoList

    self:updateAddExListUI()
end

-- 加成标题显隐
function SidekicksSkillBubbleView:updateTitleVisible()
    self:findChild("node_title_skill_1"):setVisible(self._idx == 1)
    self:findChild("node_title_skill_2"):setVisible(self._idx == 2)
end

-- 加成列表
function SidekicksSkillBubbleView:updateAddExListUI()
    local listView = self:findChild("ListView_1")
    listView:setScrollBarEnabled(false)
    for i=1, #self._petInfoList do
        local petInfo = self._petInfoList[i]
        self:updateCellUI(listView, petInfo)
    end
end
function SidekicksSkillBubbleView:updateCellUI(_listView, _petInfo)
    if not _petInfo then
        return
    end

    local petId = _petInfo:getPetId()
    local layout = _listView:getChildByName("SidekicksSkillCell_layout_" .. petId)
    if layout then
        local cell = layout:getChildByName("SidekicksSkillCell")
        cell:updateUI(_petInfo)
    else
        local layout = ccui.Layout:create()
        layout:setName("SidekicksSkillCell_layout_" .. petId)
        local cell = util_createView("GameModule.Sidekicks.views.base.main.SidekicksSkillCell", self._seasonIdx, self._idx, _petInfo)
        cell:setName("SidekicksSkillCell")
        local cellSize = cc.size(290, 100)
        cell:move(cellSize.width * 0.5, cellSize.height * 0.5)
        layout:setContentSize(cellSize)
        cell:addTo(layout)
        _listView:pushBackCustomItem(layout)
    end

end

function SidekicksSkillBubbleView:switchShowState()
    if self:isVisible() then
        self:playHideAct()
    else
        self:playShowAct()
    end
end

function SidekicksSkillBubbleView:playShowAct()
    if self._bActing then
        return
    end
    self._bActing = true

    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self._bActing = false
        self:runCsbAction("idle")
        performWithDelay(self, util_node_handler(self, self.playHideAct), 2)
    end, 60)
end

function SidekicksSkillBubbleView:playHideAct()
    if self._bActing or not self:isVisible() then
        return
    end
    self._bActing = true
    self:stopAllActions()

    self:setVisible(true)
    self:runCsbAction("over", false, function()
        self._bActing = false
        self:setVisible(false)
    end, 60)
end

function SidekicksSkillBubbleView:forceHide()
    if self:isVisible() then
        self:playHideAct()
    end
end

return SidekicksSkillBubbleView