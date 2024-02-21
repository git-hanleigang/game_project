--[[
Author: cxc
Date: 2022-03-24 10:35:09
LastEditTime: 2022-03-24 10:35:10
LastEditors: cxc
Description: 3日行为付费聚合活动  任务 气泡
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/phaseView/WildChallengeActBaseBubbleNode.lua
--]]
local WildChallengeActBaseBubbleNode = class("WildChallengeActBaseBubbleNode", BaseView)
local Config = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

function WildChallengeActBaseBubbleNode:initDatas(_phaseData, _bEnd)
    self.m_phaseData = _phaseData
    self.m_bEnd = _bEnd 
end

function WildChallengeActBaseBubbleNode:initCsbNodes()
    self.m_nodeFree = self:findChild("node_free")
    self.m_nodeFree:setVisible(false)
    self.m_nodeWord = self:findChild("node_word")
    self.m_nodeWord:setVisible(false)
    self.m_nodeFreeEnd = self:findChild("node_free_end")
    self.m_nodeFreeEnd:setVisible(false)

    self.m_lbTip = self:findChild("lb_Tip")
end

function WildChallengeActBaseBubbleNode:numberTextColor()
    return cc.c3b(255, 252, 34)
end

function WildChallengeActBaseBubbleNode:initUI()
    WildChallengeActBaseBubbleNode.super.initUI(self)

    -- 提示文本
    self:updateTipUI()
end

-- 提示文本
function WildChallengeActBaseBubbleNode:updateTipUI()
    local tipStr = self.m_phaseData:getTipStr() or ""
    if string.len(tipStr) == 0 then
        return
    end

    -- free类型
    if string.lower(tipStr) == "free" then
        self.m_nodeFree:setVisible(not self.m_bEnd)
        self.m_nodeFreeEnd:setVisible(self.m_bEnd)
        return
    end

    self.m_nodeWord:setVisible(true)
    -- 文本类型
    tipStr = string.gsub(tipStr, "%%S", "%%s")
    local strList = string.split(tipStr, "%s") or {}
    if #strList < 2 then
        -- 无数字 简单的描述
        self.m_lbTip:setString(tipStr)
        return
    end

    local progLimit = self.m_phaseData:getProgressLimit()
    local isCollectCoins = self.m_phaseData:isCollectCoins()
    local alignList = {} 
    local width = 0
    for i=1, #strList do
        local str = strList[i]
        if string.len(str) > 0 then
            local text = self:createLb(str, false, isCollectCoins)
            self.m_nodeWord:addChild(text)
            table.insert(alignList, {node = text})
            width = width + text:getContentSize().width
        end

        if i == #strList then
            break
        end

        local text = self:createLb(progLimit , true, isCollectCoins)
        self.m_nodeWord:addChild(text)
        table.insert(alignList, {node = text})
        width = width + text:getContentSize().width
    end
    self.m_lbTip:setVisible(false)
    util_alignCenter(alignList)
    if width > 380 then
        self.m_nodeWord:setScale(380 / width)
    end
end

function WildChallengeActBaseBubbleNode:isUnit(_unit)
    local units = {"K", "M", "B", "T"}
    for i=1,#units do
        if units[i] == _unit then
            return true
        end
    end
    return false
end

function WildChallengeActBaseBubbleNode:ceilNum(_str)
    local newStr = _str
    local unit = string.sub(_str, -1)
    if not self:isUnit(unit) then
        return newStr
    end
    local oriNum = string.sub(_str, 1, -2)
    local oriPointList = util_string_split(oriNum, ".")
    if oriPointList then
        if #oriPointList == 1 then
            local oriDouList = util_string_split(oriPointList[1], ",")
            oriDouList[#oriDouList] = tonumber(oriDouList[#oriDouList]) + 1
            local newNum = table.concat(oriDouList, ",")
            newStr = newNum..unit
        elseif #oriPointList > 1 then
            oriPointList[#oriPointList] = tonumber(oriPointList[#oriPointList]) + 1
            local newNum = table.concat(oriPointList, ".")
            newStr = newNum..unit
        end    
    end    
    return newStr
end

function WildChallengeActBaseBubbleNode:createLb(_content, _bNumber, _isCollectCoins)
    local textStr = _content
    if type(_content) == "number" then
        if _isCollectCoins then
            -- 目标值最后一个数加1
            _content = self:ceilNum(util_formatCoins(_content, 3, nil, nil, nil, true))
        else
            _content = util_formatCoins(_content, 3)
        end
        local progCur = self.m_phaseData:getProgressCur()
        local progStr = util_formatCoins(progCur, 3)
        textStr = "(" .. progStr .. "/" .. _content .. ")"        
    end
    local text = ccui.Text:create(textStr, self.m_lbTip:getFontName(), self.m_lbTip:getFontSize())
    if _bNumber then 
        text:setTextColor(self:numberTextColor())
    else
        text:setTextColor(self.m_lbTip:getTextColor())
    end
    text:enableOutline(self.m_lbTip:getEffectColor(), self.m_lbTip:getOutlineSize())
    return text
end

function WildChallengeActBaseBubbleNode:switchVisible()
    self:setVisible(not self:isVisible())
end

return WildChallengeActBaseBubbleNode