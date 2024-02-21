--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-18 15:57:22
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-18 15:57:32
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/BaseSidekicksRuleLayer.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]

local BaseSidekicksRuleLayer = class("BaseSidekicksRuleLayer", BaseLayer)

function BaseSidekicksRuleLayer:initDatas(_seasonIdx, _pageIdx)
    self.m_seasonIdx = _seasonIdx
    self.m_showIdx = _pageIdx or 1
    self.m_page = {}
    self.m_pageNum = {}
    self._pageCount = self:getPageCount()
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName(string.format("Sidekicks_%s/csd/info/Sidekicks_Info.csb", _seasonIdx))
end

function BaseSidekicksRuleLayer:initCsbNodes()
    self.m_btn_left = self:findChild("btn_left")
    self.m_btn_right = self:findChild("btn_right")
    self.m_sp_page_other = self:findChild("sp_page_other")
    self.m_sp_page_now = self:findChild("sp_page_now")
    self.m_node_page = self:findChild("node_page_1")
end

function BaseSidekicksRuleLayer:initView()    
    self:initInfo()
    self:initPageNum()
    self:showPage(self.m_showIdx)
    self:runCsbAction("idle", true)
end

function BaseSidekicksRuleLayer:initInfo()
    -- 规则  list
    for i = 1, self._pageCount do
        local parent = self:findChild("node_info_" .. i)
        local page = util_createView("GameModule.Sidekicks.views.base.BaseSidekicksRuleNode", self.m_seasonIdx, i)
        page:addTo(parent)
        table.insert(self.m_page, page)
    end
end

function BaseSidekicksRuleLayer:initPageNum()
    table.insert(self.m_pageNum, {node = self.m_sp_page_other, alignX = 10})
    for i = 1, self._pageCount - 1 do
        local pagePoint = cc.Sprite:createWithTexture(self.m_sp_page_other:getTexture())
        self.m_node_page:addChild(pagePoint, -10)
        table.insert(self.m_pageNum, {node = pagePoint, alignX = 10})
    end
    
    util_alignCenter(self.m_pageNum)
end

-- 改变 page
function BaseSidekicksRuleLayer:changeCurPage(_changeValue)
    if not _changeValue then
        return
    end

    local idx = self.m_showIdx + _changeValue
    
    self:showPage(idx)
end

-- 显示某一页
function BaseSidekicksRuleLayer:showPage(_idx)
    self.m_showIdx = _idx
    
    for i,v in ipairs(self.m_page) do
        if i == _idx then
            v:setVisible(true)
            v:playStart()
        else
            v:setVisible(false)
        end
    end

    local pageInfo = self.m_pageNum[_idx]
    local node = pageInfo.node
    local x, y = node:getPosition()
    self.m_sp_page_now:setPosition(x, y)

    self.m_btn_left:setVisible(self.m_showIdx > 1)
    self.m_btn_right:setVisible(self.m_showIdx < self._pageCount)
end

function BaseSidekicksRuleLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changeCurPage(-1)
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changeCurPage(1)
    end
end

function BaseSidekicksRuleLayer:getPageCount()
    return 1
end

return BaseSidekicksRuleLayer