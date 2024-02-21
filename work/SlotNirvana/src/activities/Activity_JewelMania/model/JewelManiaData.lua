--[[
]]
local JewelManiaChapterData = require("activities.Activity_JewelMania.model.JewelManiaChapterData")
local JewelManiaPayData = require("activities.Activity_JewelMania.model.JewelManiaPayData")
local JewelManiaSlateData = require("activities.Activity_JewelMania.model.JewelManiaSlateData")
local JewelManiaJewelData = require("activities.Activity_JewelMania.model.JewelManiaJewelData")
local JewelManiaSpecialChapterData = require("activities.Activity_JewelMania.model.JewelManiaSpecialChapterData")
local JewelManiaTaskData = require("activities.Activity_JewelMania.model.JewelManiaTaskData")
local JewelManiaClickSlateResultData = require("activities.Activity_JewelMania.model.JewelManiaClickSlateResultData")

local JewelManiaData = class("JewelManiaData", require("baseActivity.BaseActivityData"))

function JewelManiaData:ctor()
    JewelManiaData.super.ctor(self)
    self.m_clickSlateResultDatas = {}
end

-- function JewelManiaData:checkCompleteCondition()
--     return self.m_bComplete
-- end

--获取入口位置 1：左边，0：右边
function JewelManiaData:getPositionBar()
    return 1
end

-- message JewelMania {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated JewelManiaChapter chapterList = 4;//章节信息
--     optional int32 currentChapter = 5;//当前章节
--     optional int32 shovels = 6;//拥有铲子数
--     optional bool payUnlock = 7;//是否解锁付费
--     optional JewelManiaPay passPay = 8;//章节pass奖励付费
--     optional JewelManiaPay specialChapterPay = 9;//特殊章节付费
--     repeated JewelManiaSlate slateList = 10;//石盘信息
--     repeated JewelManiaJewel jewelList = 11;//宝石位置信息
--     optional JewelManiaSpecialChapter specialChapter = 12;//特殊章节信息
--     repeated JewelManiaTask taskList = 13;//任务
--     optional int32 currentSpecialChapter = 14;//特殊章节index
--     repeated int32 letters = 15;//字母列表 0-未获取 1-已获取
--   }
function JewelManiaData:parseData(_netData)
    JewelManiaData.super.parseData(self, _netData)

    self.p_chapterList = {}
    if _netData.chapterList and #_netData.chapterList > 0 then
        for i=1,#_netData.chapterList do
            local data = JewelManiaChapterData:create()
            data:parseData(_netData.chapterList[i])
            table.insert(self.p_chapterList, data)
        end
    end
    self.m_chapterMax = #self.p_chapterList + 1
    
    self.p_currentChapter = _netData.currentChapter
    self.p_shovels = _netData.shovels
    self.p_payUnlock = _netData.payUnlock

    self.p_passPay = nil
    if _netData:HasField("passPay") then
        local pData = JewelManiaPayData:create()
        pData:parseData(_netData.passPay)
        pData:setPayType("pass")
        self.p_passPay = pData
    end
    self.p_specialChapterPay = nil
    if _netData:HasField("specialChapterPay") then
        local pData = JewelManiaPayData:create()
        pData:parseData(_netData.specialChapterPay)
        pData:setPayType("specialChapter")
        self.p_specialChapterPay = pData
    end
    self.p_slateList = {}
    local _isMined = false
    if _netData.slateList and #_netData.slateList > 0 then
        for i=1,#_netData.slateList do
            local data = JewelManiaSlateData:create()
            data:parseData(_netData.slateList[i])
            table.insert(self.p_slateList, data)
            _isMined = _isMined or data:isMined()
        end
    end
    -- 游戏状态
    self.m_playState = "INIT"
    if _isMined then
        self.m_playState = "PLAYING"
    end

    self.p_jewelList = {}
    if _netData.jewelList and #_netData.jewelList > 0 then
        for i=1,#_netData.jewelList do
            local data = JewelManiaJewelData:create()
            data:parseData(_netData.jewelList[i])
            table.insert(self.p_jewelList, data)
        end
    end
    table.sort(self.p_jewelList, function(a, b)
        return a:getIndex() < b:getIndex()
    end)

    self.p_currentSpecialChapter = _netData.currentSpecialChapter or 0

    self.p_specialChapter = nil
    if _netData:HasField("specialChapter") then
        local sChapterData = JewelManiaSpecialChapterData:create()
        sChapterData:parseData(_netData.specialChapter)
        self.p_specialChapter = sChapterData
    end
    self.p_taskList = {}
    if _netData.taskList and #_netData.taskList > 0 then
        for i=1,#_netData.taskList do
            local data = JewelManiaTaskData:create()
            data:parseData(_netData.taskList[i])
            table.insert(self.p_taskList, data)
        end
    end

    -- 优化GRAND
    self.p_letters = {}
    if _netData.letters and #_netData.letters > 0 then
        for i=1,#_netData.letters do
            local data = _netData.letters[i]
            table.insert(self.p_letters, data)
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.JewelMania})
end

function JewelManiaData:parseClickSlateResultData(resultData, idx)
    local data = self:getClickSlateResultData(idx)
    if not data then
        data = JewelManiaClickSlateResultData:create()
        self.m_clickSlateResultDatas["" .. idx] = data
    end
    data:parseData(resultData)
end

function JewelManiaData:getClickSlateResultData(idx)
    return self.m_clickSlateResultDatas["" .. idx]
end

function JewelManiaData:clearClickSlateResultData()
    self.m_clickSlateResultDatas = {}
end

function JewelManiaData:getChapterList()
    return self.p_chapterList
end

function JewelManiaData:getChapterMax()
    return self.m_chapterMax
end

function JewelManiaData:getCurrentChapter()
    if self.p_currentChapter == self.m_chapterMax - 1 then
        if self.p_currentSpecialChapter > 0 then
            return self.m_chapterMax
        end
    end
    return self.p_currentChapter
end

-- 当前第几次特殊章节
function JewelManiaData:getCurrentSpecialChapter()
    return self.p_currentSpecialChapter
end

function JewelManiaData:setShovels(num)
    self.p_shovels = num
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.JewelMania})
end

function JewelManiaData:getShovels()
    return self.p_shovels
end

function JewelManiaData:isPayUnlock()
    return self.p_payUnlock
end

function JewelManiaData:getPassPay()
    return self.p_passPay
end

function JewelManiaData:getSpecialChapterPay()
    return self.p_specialChapterPay
end

function JewelManiaData:getSpecialChapter()
    return self.p_specialChapter
end

function JewelManiaData:getSlateList()
    return self.p_slateList
end

function JewelManiaData:getJewelList()
    return self.p_jewelList
end

function JewelManiaData:getTaskList()
    return self.p_taskList
end

function JewelManiaData:getLetters()
    return self.p_letters
end
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
function JewelManiaData:getChapterByIndex(_index)
    if self.p_chapterList and #self.p_chapterList > 0 then
        for i=1,#self.p_chapterList do
            local chapterData = self.p_chapterList[i]
            if chapterData:getChapter() == _index then
                return chapterData
            end
        end
    end
    return nil
end

function JewelManiaData:getChapterPlayState()
    return self.m_playState
end

function JewelManiaData:isFinalChapter()
    if self:getCurrentChapter() == self.m_chapterMax then
        return true
    end
    return false
end

function JewelManiaData:getSlateByIndex(_index)
    if _index and self.p_slateList and #self.p_slateList > 0 then
        return self.p_slateList[_index]
    end
    return nil
end

function JewelManiaData:getJewelByType(_type)
    if self.p_jewelList and #self.p_jewelList > 0 then
        for i=1,#self.p_jewelList do
            local jewelData = self.p_jewelList[i]
            if jewelData:getType() == _type then
                return jewelData
            end
        end
    end
    return nil
end

function JewelManiaData:getJewelByIndex(_index)
    if self.p_jewelList and #self.p_jewelList > 0 then
        for i=1,#self.p_jewelList do
            local jewelData = self.p_jewelList[i]
            if jewelData:getIndex() == _index then
                return jewelData
            end
        end
    end
    return nil
end

function JewelManiaData:isJewelMined(_index)
    local isFinal = self:isFinalChapter()
    if self.p_jewelList and #self.p_jewelList > 0 then
        for i=1,#self.p_jewelList do
            local jewelData = self.p_jewelList[i]
            if jewelData and jewelData:getIndex() == _index then
                if isFinal then
                    if jewelData:isCollected() == true then
                        return true
                    end
                else
                    if jewelData:isMined() == true then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--是否存在可以领取的付费道具
function JewelManiaData:isCanCollected()
    local isExist = false
    if self.p_chapterList and #self.p_chapterList > 0 then
        for i=1,#self.p_chapterList do
            local  payReward = self.p_chapterList:getPayReward()
            if not payReward:isCollected() then
                isExist = true
                break
            end
        end
    end
    return isExist
end

return JewelManiaData
