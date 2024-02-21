--[[
    组队打BOSS
]]
local DragonChallengeGuideMgr = require("activities.Activity_DragonChallenge.controller.DragonChallengeGuideMgr")
local DragonChallengeConfig = require("activities.Activity_DragonChallenge.config.DragonChallengeConfig")
local DragonChallengeNet = require("activities.Activity_DragonChallenge.net.DragonChallengeNet")
local DragonChallengeMgr = class("DragonChallengeMgr", BaseActivityControl)

function DragonChallengeMgr:ctor()
    DragonChallengeMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.DragonChallenge)

    self.m_netModel = DragonChallengeNet:getInstance() -- 网络模块
    self.m_guide = DragonChallengeGuideMgr:getInstance()

    -- 当前选中PASS的分页索引
    self.m_curPassPageIdx = 1
    -- pass购买提示数据
    self.p_display = nil
    -- 是否打开其他界面
    self.m_isShowOtherView = false
end

function DragonChallengeMgr:setIsShowOtherView(_isShow)
    self.m_isShowOtherView = _isShow
end

function DragonChallengeMgr:getIsShowOtherView()
    return self.m_isShowOtherView
end

-- 全部的龙都被杀死
function DragonChallengeMgr:isAllDragonsDefeated()
    local data = self:getRunningData()
    if data then
        local round = data:getRound()
        local bossCurrentHp = data:getBossCurrentHp()
        if round >= #DragonChallengeConfig.DRAGON_TYPE and bossCurrentHp <= 0 then
            return true
        end
        return false
    end
    return true
end

function DragonChallengeMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    -- 到最后一个轮次并且boss血量为0
    local isAllDragonsDefeated = self:isAllDragonsDefeated()
    if isAllDragonsDefeated then
        local rankView = self:showRankLayer()
        return rankView
    end

    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showRankLayer(_params)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeRankLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:closeMainLayer()
    local mainLayer = gLobalViewManager:getViewByExtendData("DragonChallengeMainLayer")
    if mainLayer then
        mainLayer:closeUI()
    end
end

function DragonChallengeMgr:showInfoLayer()
    if gLobalViewManager:getViewByExtendData("DragonChallengeInfoLayer") then
        return
    end
    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeInfoLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showProgressCollectLayer(_params)
    if gLobalViewManager:getViewByExtendData("DragonChallengeProgressCollect") then
        return
    end
    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeProgressCollect", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showMissionCollectLayer(_params)
    if gLobalViewManager:getViewByExtendData("DragonChallengeMissionCollect") then
        return
    end
    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeMissionCollect", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showMissionGiftLayer(_params)
    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeMissionGift", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showBuffSaleLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("DragonChallengeBuffSale") then
        return
    end

    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeBuffSale")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showWheelSaleLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("DragonChallengeWheelSale") then
        return
    end

    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeWheelSale")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function DragonChallengeMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function DragonChallengeMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function DragonChallengeMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. entryName .. "EntryNode"
end

function DragonChallengeMgr:sendAttack(_bet, _parts)
    local parts = {"head", "torso", "tail"}
    self.m_netModel:sendAttack(_bet, parts[_parts])
end

function DragonChallengeMgr:buyBuffSale()
    self.m_netModel:buyBuffSale()
end

function DragonChallengeMgr:buyWheelSale(_data, _index)
    self.m_netModel:buyWheelSale(_data, _index)
end

function DragonChallengeMgr:refreshData(_loading)
    self.m_netModel:refreshData(_loading)
end

function DragonChallengeMgr:parseSpinData(_data)
    self.m_spinData = _data

    local gameData = self:getRunningData()
    if gameData then
        gameData:parseSpinData(_data)
    end
end

function DragonChallengeMgr:checkIsGetWheel()
    if self.m_spinData then
        local newWheels = self.m_spinData.newWheels or 0
        if newWheels > 0 then
            return self:showGetWheels()
        end
    end
end

function DragonChallengeMgr:checkHasBoxReward()
    if self.m_spinData then
        local boxList = clone(self.m_spinData.teamTaskReward or {})
        self.m_spinData = nil
        if #boxList > 0 then
            return self:showProgressCollectLayer(boxList, true)
        end
    end
end

function DragonChallengeMgr:showGetWheels()
    local activityData = self:getRunningData()
    if activityData then
        if not self:isCanShowLayer() then
            return false
        end

        -- 获取要飞到的坐标
        local _node = gLobalActivityManager:getEntryNode(ACTIVITY_REF.DragonChallenge)
        if not _node then
            return false
        end

        local flyDesPos = _node:getFlyPos()
        local _isVisible = gLobalActivityManager:getEntryNodeVisible(ACTIVITY_REF.DragonChallenge)
        if not _isVisible then
            -- 隐藏图标的时候使用箭头坐标
            flyDesPos = gLobalActivityManager:getEntryArrowWorldPos()
        end

        if not flyDesPos then
            return false
        end

        local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeWheelCollect")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_GUIDE, false)
        view:playFlyAction(flyDesPos)

        return true
    else
        return false
    end
end

function DragonChallengeMgr:getGuide()
    return self.m_guide
end

function DragonChallengeMgr:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    return self.m_guide:triggerGuide(view, name, ACTIVITY_REF.DragonChallenge)
end

function DragonChallengeMgr:isCanTriggerGuide(guideName)
    return self.m_guide:isCanTriggerGuide(guideName, ACTIVITY_REF.DragonChallenge)
end
-- ============================================== 深度优化内容 S ============================================== --
-- 设置选中区域id（1-头 2-躯干 3-尾巴）
function DragonChallengeMgr:setSelectAreaId(_id)
    self.m_selectAreaId = _id
end

-- 获得选中区域id（1-头 2-躯干 3-尾巴）
function DragonChallengeMgr:getSelectAreaId()
    return self.m_selectAreaId or self:getDefaultAreaId()
end

-- 获得选中区域id（1-头 2-躯干 3-尾巴）
function DragonChallengeMgr:getDefaultAreaId()
    local data = self:getRunningData()
    if data then
        local minAreaId = data:getOriginAreaId()
        return minAreaId
    end
    return 0
end

-- 设置转盘bet
function DragonChallengeMgr:setSelectBetIndex(_inx)
    self.m_selectBetIndex = _inx
end

-- 设置转盘bet
function DragonChallengeMgr:getSelectBetIndex()
    return self.m_selectBetIndex or 1
end

-- 尾刀奖励弹板
function DragonChallengeMgr:showKillRewardLayer(_params)
    if gLobalViewManager:getViewByExtendData("DragonChallengeKillReward") then
        return
    end
    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeKillReward", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 攻击区域击破奖励
function DragonChallengeMgr:showAreaRewardLayer(_params)
    if gLobalViewManager:getViewByExtendData("DragonChallengeAreaRewardLayer") then
        return
    end
    local view = util_createView("Activity_DragonChallenge.Activity.DragonChallengeAreaRewardLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end
-- ============================================== 深度优化内容 E ============================================== --

--- pass ---
-- 获取PASS数据
function DragonChallengeMgr:getPassData()
    local actData = self:getRunningData()
    if not actData then
        return {}
    end
    return actData:getPassData()
end

--[[
    @desc: 获取PASS分页数据
    --@idxPage: 分页索引
    @return:
]]
function DragonChallengeMgr:getPassPageData(idxPage)
    local passData = self:getPassData()
    if passData:getPageNum() == 0 then
        return nil
    end
    -- idx 默认为当前选中的
    idxPage = idxPage or self.m_curPassPageIdx
    return passData:getPassPageData(idxPage)
end

function DragonChallengeMgr:getDragonPassCurIndex()
    return self.m_curPassPageIdx
end

function DragonChallengeMgr:setDragonPassCurIndex(_index)
    local _passData = self:getPassData()
    local num = _passData:getPageNum()
    if _index > 0 and _index <= num then
        self.m_curPassPageIdx = _index
    end
end

function DragonChallengeMgr:showPassLayer()
    if not self:isCanShowLayer() then
        return
    end

    local actData = self:getRunningData()
    if not actData then
        return false
    end
    local data = actData:getPassData()
    if nil == data then
        return false
    end

    -- 更新pass当前页签
    self:updataCurPassPageIdx()
    local view = util_createView("Activity_DragonChallenge.Activity.pass.DragonPassLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:showPassRuleLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity_DragonChallenge.Activity.pass.DragonPassRuleView")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DragonChallengeMgr:sendPassCollect(_data)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        local rewardCallback = function()
            if CardSysManager:needDropCards("Dragon Challenge Pass") == true then
                CardSysManager:doDropCards("Dragon Challenge Pass")
            end
            gLobalNoticManager:postNotification(DragonChallengeConfig.notify_pass_get_reward, {success = true, data = _data ,res = _result})
        end
        G_GetMgr(ACTIVITY_REF.DragonChallenge):showPassRewardLayer(_result,rewardCallback)
        --gLobalNoticManager:postNotification(DragonChallengeConfig.notify_pass_get_reward, {success = true, data = _data ,res = _result})
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(DragonChallengeConfig.notify_pass_get_reward, {success = false, _data = _data})
    end
    self.m_netModel:sendPassCollect(_data,successCallback,failedCallback)
end

function DragonChallengeMgr:showPassBuyTicketLayer()
    if not self:isCanShowLayer() then
        return false
    end
    local data = self:getPassPageData()
    -- 是否只剩一个
    local price = data:getPayValue(1):getPrice()
    local name = "DragonPassBuyTicket"
    if  nil == price or "" == price then
        name = "DragonPassBuyTicket_Single"
    else
    
    end
    local buyTicketLayer = util_createView("Activity_DragonChallenge.Activity.pass."..name)
    if buyTicketLayer then
        self:showLayer(buyTicketLayer, ViewZorder.ZORDER_UI)
    end
end
-- 购买促销解锁付费PASS
function DragonChallengeMgr:buyPassUnlock(_type,_indexAppoint)
    local _index = self.m_curPassPageIdx
    if _indexAppoint then 
        _index = _indexAppoint
    end
    -- 获得PASS分页数据
    local passData = self:getPassPageData(_index)
    local data = passData:getPayValue(_type)
    --local buyPassExtra = {index = _index, pack = _type}
    --参数多个 用p_activityId 补一个参数
    globalData.iapRunData.p_activityId = _index
    globalData.iapRunData.p_contentId = _type

    self.m_netModel:buyPassUnlock(data)
end

function DragonChallengeMgr:showPassRewardLayer(_data,_rewardCallback)
    if not self:isCanShowLayer() then
        return false
    end

    local passRewardLayer = util_createView("Activity_DragonChallenge.Activity.pass.DragonPassRewardLayer", _data,_rewardCallback)
    if passRewardLayer then
        self:showLayer(passRewardLayer, ViewZorder.ZORDER_UI)
    end
end

-- 需付费提示pass是否付费（是否可显示付费提示弹窗）
function DragonChallengeMgr:IsCanShowBuyTips()
    if self.p_display == nil then
        return false
    end
    local index = self.p_display.p_passSeq
    local data = self:getPassPageData(index)
    if data then
        local isPay = data:getPayUnlocked()
        if isPay then
            return false
        end
    end
    return true
end

function DragonChallengeMgr:showBuyTipsLayer()
    if not self:isCanShowLayer() then
        return false
    end
    local actData = self:getRunningData()
    if not actData then
        return false
    end
    local isCanShow = self:IsCanShowBuyTips()
    if not isCanShow then
        return false
    end
    local buyTipsLayer = util_createView("Activity_DragonChallenge.Activity.pass.DragonPassBuyTips")
    if buyTipsLayer then
        self:showLayer(buyTipsLayer, ViewZorder.ZORDER_UI)
    end
end

-- 更新pass当前页签
function DragonChallengeMgr:updataCurPassPageIdx()
    local actData = self:getRunningData()
    if not actData then
        return {}
    end
    self.m_curPassPageIdx = actData:getRound()
end

-- 获取未付费pass数据
function DragonChallengeMgr:getUnpaidPass()
    local passData = self:getPassData()
    return passData:getUnpaidPass()
end

function DragonChallengeMgr:createBubble()
    local view = util_createView("Activity_DragonChallenge.Activity.pass.DragonPassBubbleNode")
    return view
end

-- 付费提示
-- 获取数据
function DragonChallengeMgr:getPassDisplay()
    return self.p_display
end 
-- 设置数据
function DragonChallengeMgr:setPassDisplay(val)
    self.p_display = val
end 
-- 清空数据
function DragonChallengeMgr:clearPassDisplay()
    self.p_display = nil
end 
-- 判空
function DragonChallengeMgr:isEmptyPassDisplay()
    if nil == self.p_display then
        return false
    else
        return true
    end
end 

return DragonChallengeMgr
