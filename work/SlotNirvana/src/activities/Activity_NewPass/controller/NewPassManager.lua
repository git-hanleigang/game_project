--[[
    NewPass活动管理类
    author: 徐袁
    time: 2021-09-14 11:27:26
]]
local NewPassManager = class("NewPassManager", BaseActivityControl)

function NewPassManager:ctor()
    NewPassManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewPass)

    self:addExtendResList("Activity_NewPassCode") 
end

-- function NewPassManager:getThemeName(refName)
--     local _themeName = NewPassManager.super.getThemeName(self, refName)
--     if _themeName == ACTIVITY_REF.NewPass then
--         return "baseDailyPass"
--     else
--         return _themeName
--     end
-- end

-- function NewPassManager:isDownloadRes(refName)
--     local baseRes = ACTIVITY_REF.NewPass
--     if self:getThemeName() ~= baseRes then
--         -- 判断基础资源
--         local isBaseDownloaded = self:checkDownloaded(baseRes) and self:checkDownloaded(baseRes .. "Code")
--         if not isBaseDownloaded then
--             return false
--         end
--     end

--     return NewPassManager.super.isDownloadRes(self, refName)
-- end

function NewPassManager:isDownloadLobbyRes()
    -- 轮播页、展示页、弹板
    return self:isDownloadLoadingRes()
end

-- 获取当前season 活动是否开始
function NewPassManager:getSeasonActivityOpen()
    local activityData = self:getRunningData()
    if not activityData then
        return false
    end

    local openLevel = globalData.constantData.NEWPASS_OPEN_LEVEL
    if globalData.constantData.NEWUSERPASS_OPEN_SWITCH and globalData.constantData.NEWUSERPASS_OPEN_SWITCH > 0 then
        if activityData:isNewUserPass() then
            openLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
        else
            if globalData.userRunData.levelNum >= globalData.constantData.NEWUSERPASS_OPEN_LEVEL then
                openLevel = globalData.constantData.NEWPASS_OPEN_LEVEL
            else
                openLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
            end
        end
    end
    
    if globalData.userRunData.levelNum >= openLevel then
        return true
    end

    return false
end

function NewPassManager:getSeasonMission()
    local activityData = self:getRunningData()
    if activityData then
        return activityData:getPassTask()
    end
    return nil
end

-- 获取当前有多少个没有领取的箱子数量
function NewPassManager:getCanClaimNum(isAll)
    local actData = self:getRunningData()
    if not actData then
        return 0
    end
    local startLevel = actData:getLevel()
    local function checkState(info, pay)
        if info == nil then
            return false
        end
        local pState = false
        if not info:getCollected() then --当前没有被领取过 或者 付费已经解锁了并且有未领取的
            pState = true
            if pay and actData:isUnlocked() == false then
                pState = false
            end
        end
        return pState
    end

    local function checkState_threeLine(info, pay)
        if info == nil then
            return false
        end
        local pState = false
        if not info:getCollected() then --当前没有被领取过 或者 付费已经解锁了并且有未领取的
            pState = true
            if pay and actData:getCurrIsPayHigh() == false then
                pState = false
            end
        end
        return pState
    end

    local sumNoClaim = 0
    for i = 1, startLevel do
        local freeInfo = actData:getFressPointsInfo()[i]
        local payInfo = actData:getPayPointsInfo()[i]
        if checkState(freeInfo) then
            sumNoClaim = sumNoClaim + 1
        end
        if checkState(payInfo, true) then
            sumNoClaim = sumNoClaim + 1
        end
        if actData:isThreeLinePass() then
            local tripleInfo = actData:getTriplePointsInfo()[i]
            if checkState_threeLine(tripleInfo, true) then
                sumNoClaim = sumNoClaim + 1
            end
        end
    end
    -- printf("------ 当前未领取的个数为 sumNoClaim "..sumNoClaim)
    return sumNoClaim
end

-- 当前是否完成pass进度
function NewPassManager:getIsMaxPoints()
    local actData = self:getRunningData()
    if not actData then
        return false
    end
    local levelExpList = actData:getLevelExpList()
    local curExp = actData:getCurExp()
    if curExp >= levelExpList[#levelExpList] then
        return true
    end
    return false
end

function NewPassManager:getInBuffTime()
    local actData = self:getRunningData()
    if not actData then
        return false
    end
    local buffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BATTLEPASS_BOOSTER)
    if buffTimeLeft <= 0 then
        return false
    else
        return true
    end
    return false
end

-- 需要计算当前活动开启的情况下对任务经验的加成
function NewPassManager:getPassExpMultipByActivity()
    local multip = 1
    local actData = self:getRunningData()
    local actDoubleData = self:getMgr(ACTIVITY_REF.NewPassDoubleMedal):getRunningData()
    if actDoubleData then
        if actData.getDoubleActMultiple and actData:getDoubleActMultiple() > 0 then
            multip = multip + actData:getDoubleActMultiple()
        end
    end

    if self:getInBuffTime() then
        multip = multip + 1
    end
    return multip
end

function NewPassManager:getInSafeBoxStatus()
    local actData = self:getRunningData()
    if not actData then
        return false
    end
    local curLevel = actData:getLevel()
    if curLevel >= actData:getMaxLevel() then
        return true
    end
    return false
end

function NewPassManager:getSafeBoxIsCompleted()
    -- 获取当前保险箱是否能收集
    local actData = self:getRunningData()
    if not actData then
        return false
    end
    if self:getIsMaxPoints() == false then
        return false
    end

    local boxData = actData:getSafeBoxConfig()
    if boxData:getCurPickNum() == boxData:getTotalNum() then
        return true
    end
    return false
end

-- 服务器返回刷新 pass 任务
function NewPassManager:refreshPassTaskData(_passTask)
    if _passTask and self:getSeasonActivityOpen() then
        local data = self:getRunningData()
        if data then
            data:parsePassTask(_passTask)
        end
    end
end

function NewPassManager:getInGuide()
    local actData = self:getRunningData()
    if not actData then
        return false
    end

    if actData:getGuideIndex() == -1 then
        -- 当前引导已经结束了
        return false
    end
    return true
end

-- 获取解锁门票之后道具或者金币的加成系数
function NewPassManager:getRewardCellMultiple(_type,_itemData)
    local actData = self:getRunningData()
    if not actData then
        return 1
    end
    if self:isThreeLinePass() then
        return 1
    end
    -- 如果当前解锁了门票
    -- if actData:isUnlocked() then
    -- 获取当前应该返回高价值还是低价值
    local result = 1
    if actData:getCurrIsPayHigh() then
        if _type == "coin" then
            result = actData:getHighPayCoinMul()
        else
            if _itemData then
                if DAILYPASS_EXTRA_CONFIG.DailyMissionPass_SpecialItemIcon and string.find(_itemData.p_icon, DAILYPASS_EXTRA_CONFIG.DailyMissionPass_SpecialItemIcon) then
                    result = actData:getHighPayMiniGameMul()
                else
                    if string.find(_itemData.p_icon, "PropFrame") then
                        result = 1
                    else
                        result = actData:getHighPayItemMul()
                    end
                end
            else
                result = actData:getHighPayItemMul()
            end
        end
        return result
    else
        if _type == "coin" then
            result = actData:getLowPayCoinMul()
        else
            if _itemData then
                if DAILYPASS_EXTRA_CONFIG.DailyMissionPass_SpecialItemIcon and string.find(_itemData.p_icon, DAILYPASS_EXTRA_CONFIG.DailyMissionPass_SpecialItemIcon) then
                    result = actData:getLowPayMiniGameMul()
                else
                    if string.find(_itemData.p_icon, "PropFrame") then
                        result = 1
                    else
                        result = actData:getHighPayItemMul()
                    end
                end
            else
                result = actData:getLowPayItemMul()
            end
        end
        return result
    end
end

------------------------------------   csc 2022-01-25 新pass优化接口 ----------------------------------
function NewPassManager:isCanShow()
end

--  显示购买促销界面
function NewPassManager:showSaleLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local buyLayer = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleLayer)
    gLobalViewManager:showUI(buyLayer, ViewZorder.ZORDER_UI)
    return buyLayer
end

-- 显示购买门票界面
function NewPassManager:showBuyTicketLayer(fromPop,isSpecial)
    if not self:isCanShowLayer() then
        --return nil
    end

    local buyLayer = nil

    if not gLobalViewManager:getViewLayer():getChildByName("PassticketBuyLayer") then
        local code_path = DAILYPASS_CODE_PATH.DailyMissionPass_BuyTicketLayer_ThreeLine
        buyLayer = util_createView(code_path,{fromPop = not not fromPop})
        buyLayer:setName("PassticketBuyLayer")
        self:showLayer(buyLayer, ViewZorder.ZORDER_UI)
    end

    return buyLayer
end

-- 显示购买门票获取奖励界面
function NewPassManager:showBuyTicketRewardLayer(isSpecial)
    if not self:isCanShowLayer() then
        --return nil
    end

    local buyLayer = nil
    if not gLobalViewManager:getViewLayer():getChildByName("PassticketRewardBuyLayer") then
        local code_path = DAILYPASS_CODE_PATH.DailyMissionPass_BuyTicketRewardLayer_ThreeLine
        buyLayer = util_createView(code_path)
        buyLayer:setName("PassticketRewardBuyLayer")
        gLobalViewManager:showUI(buyLayer, ViewZorder.ZORDER_UI)
    end

    return buyLayer
end

-- 检测当前pass 活动是否开启，刷新配置
function NewPassManager:checkToUpdatePassConfig()
    local isShow = false
    local activityData = self:getRunningData()
    local unLockLevel = globalData.constantData.NEWPASS_OPEN_LEVEL or 20
    if globalData.constantData.NEWUSERPASS_OPEN_SWITCH and globalData.constantData.NEWUSERPASS_OPEN_SWITCH > 0 then
        if activityData and activityData:isNewUserPass() then
            unLockLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
        else
            if globalData.userRunData.levelNum >= globalData.constantData.NEWUSERPASS_OPEN_LEVEL then
                unLockLevel = globalData.constantData.NEWPASS_OPEN_LEVEL
            else
                unLockLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
            end
        end
    end

    local curLevel = globalData.userRunData.levelNum
    --级别不够
    if curLevel < unLockLevel then
        return isShow
    end
    if curLevel == unLockLevel then
        local pass_key = "NewpassFirstLevelUp_" .. unLockLevel
        local saveStatus = gLobalDataManager:getBoolByField(pass_key, false)
        if saveStatus then
            isShow = false
        else
            isShow = true
            gLobalDataManager:setBoolByField(pass_key, true)
        end
    end
    return isShow
end

function NewPassManager:isNewUserPass()
    local data = self:getRunningData()
    if data and data:isNewUserPass() then
        return true
    end
    return false
end

function NewPassManager:showLoadingView()
    if self:isDownloadLobbyRes() then
        local view = self:showPopLayer()
        return true
    end
    return false
end

function NewPassManager:showPopLayer(popInfo, callback)
    if self:getMgr(ACTIVITY_REF.NewPassThreeLineLoading):isCanShowLayer() then
        return self:getMgr(ACTIVITY_REF.NewPassThreeLineLoading):showPopLayer(popInfo, callback)
    else
        return NewPassManager.super.showPopLayer(self,popInfo, callback)
    end
end

function NewPassManager:isThreeLinePass()
    local data = self:getRunningData()
    if data and data:isThreeLinePass() then
        return true
    end
    return false
end


function NewPassManager:checkDoUnlockGuide()
    self.m_doUnlockGuide = not self:getRunningData():isUnlocked() and not self:getRunningData():getCurrIsPayHigh()
end

function NewPassManager:canDoUnlockGuide()
    if self:isThreeLinePass() then
        return not not self.m_doUnlockGuide
    end
    return true
end

function NewPassManager:getPopPath(popName)
    if popName == "Activity_NewPass_New" then
        -- 新手期Pass暂时特殊处理
        return "Activity/Activity_NewPassVegasNew"
    else
        return NewPassManager.super.getPopPath(self, popName)
    end
end

-- function NewPassManager:getHallPath(hallName)
--     if hallName == "Activity_NewPass_New" then
--         -- 新手期Pass暂时特殊处理
--         return "Icons/Activity_NewPasslHallNode"
--     else
--         return NewPassManager.super.getHallPath(self, hallName)
--     end
-- end

-- function NewPassManager:getSlidePath(slideName)
--     if slideName == "Activity_NewPass_New" then
--         -- 新手期Pass暂时特殊处理
--         return "Icons/Activity_NewPasslSlidNode"
--     else
--         return NewPassManager.super.getSlidePath(self, slideName)
--     end
-- end

function NewPassManager:addDefExtendResList(_themeName)
    if _themeName == "Activity_NewPass_New" then
        -- 新手期Pass暂时特殊处理
        NewPassManager.super.addDefExtendResList(self, "Activity_NewPassVegasNew")
    else
        NewPassManager.super.addDefExtendResList(self, _themeName)
    end
end

return NewPassManager
