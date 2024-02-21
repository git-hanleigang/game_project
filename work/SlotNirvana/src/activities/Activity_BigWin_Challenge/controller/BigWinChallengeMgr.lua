--[[
]]
local BigWinChallengeMgrNet = require("activities.Activity_BigWin_Challenge.net.BigWinChallengeNet")
local BigWinChallengeMgr = class("BigWinChallengeMgr", BaseActivityControl)
local ShopItem = util_require("data.baseDatas.ShopItem")

function BigWinChallengeMgr:ctor()
    BigWinChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigWin_Challenge)
    self.m_bigwinNet = BigWinChallengeMgrNet:getInstance()
    self:registerObserver()
end

function BigWinChallengeMgr:requestCollect(_index)
    local function successCallFun(result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BIGWIN_COLLECT,result)
    end

    local function failedCallFun(errorCode, errorData)
        dump(errorCode)
    end
    self.m_bigwinNet:requestCollect(successCallFun, failedCallFun, _index)
end

function BigWinChallengeMgr:canShowBigWinTip()
    local data = self:getRunningData()
    if not data then
        return false
    else
        return self:getIsReward()
    end

end

function BigWinChallengeMgr:showBigWinTip(_params)
    if not self:isCanShowLayer() then
        return
    end
    local rewardLayer = util_createView("Activity.BigWinReward", _params)
    gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
    return rewardLayer
end

function BigWinChallengeMgr:getCurrentPross(_id)
    local flag = 0 -- 未达到
    local data = self:getRunningData()
    if data then
        local pro_data = data:getProgressData()[_id]
        if pro_data.isGet then
            flag = 2  --领取完
        else
            if tonumber(data:getBigWinNums()) >= tonumber(pro_data.id) then
                flag = 1 --达到目标但是未领取
            end
        end
    end
    return flag
end

function BigWinChallengeMgr:getIsReward()
    local flag = false
    local index = 0
    for i=1,4 do
        local a = self:getCurrentPross(i)
        if a == 1 then
            flag = true
            index = i
        end
    end
    return flag
end

function BigWinChallengeMgr:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params[1] == true then
                -- spine 成功了数据
                local spinData = params[2]
                if not spinData or not spinData.extend or not spinData.extend.bigWinChallenge then
                    return
                end
                local item = spinData.extend.bigWinChallenge
                local actData = self:getRunningData()
                if actData then
                    actData:setBigWinNums(item.bigWinTimes)
                    actData:setIsActive(item.isActive)
                    actData:setLowBetLimit(item.lowBetLimit)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BIGWIN_ANIMATE)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

-- 是否可显示展示页
function BigWinChallengeMgr:isCanShowHall()
    local isCanShow = BigWinChallengeMgr.super.isCanShowHall(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
        if not act_data.m_notLock then
            isCanShow = false
        end
    end
    return isCanShow
end

-- 是否可显示轮播页
function BigWinChallengeMgr:isCanShowSlide()
    local isCanShow = BigWinChallengeMgr.super.isCanShowSlide(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
        if not act_data.m_notLock then
            isCanShow = false
        end
    end
    return isCanShow
end

function BigWinChallengeMgr:isCanShowPop()
    return self:isCan()
end

function BigWinChallengeMgr:isCan()
    local isCanShow = true
    local act_data = self:getRunningData()
    if not act_data then
        isCanShow = false
    end
    if not act_data.m_notLock then
        isCanShow = false
    end
    return isCanShow
end

function BigWinChallengeMgr:getRightFrameRunningData()
    local data = self:getRunningData()
    if not data then
        return false
    end

    if data:getLeftTime() <= 0 then
        return false
    end

    if not data.m_notLock then
        return false
    end
    return data
end

function BigWinChallengeMgr:getEntryPath(entryName)
    return "Activity/BigWinCNode"
end

-- function BigWinChallengeMgr:getHallPath(hallName)
--     return "" .. hallName .. "/" .. hallName ..  "HallNode"
-- end

-- function BigWinChallengeMgr:getSlidePath(slideName)
--     return "" .. slideName .. "/" .. slideName ..  "SlideNode"
-- end

-- function BigWinChallengeMgr:getPopPath(popName)
--     return "" .. popName .. "/" .. popName
-- end

return BigWinChallengeMgr
