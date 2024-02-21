-- 气球挑战管理器

local BalloonRushNet = require("activities.Activity_BalloonRush.net.BalloonRushNet")
local BalloonRushManager = class("BalloonRushManager", BaseActivityControl)

-- 存一些本地数据
function BalloonRushManager:ctor()
    BalloonRushManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BalloonRush)
    self.m_balloonRushNet = BalloonRushNet:getInstance()
end

function BalloonRushManager:getConfig()
    if not self:isCanShowLayer() then
        return
    end
    
    local themeName = self:getThemeName()

    if not self.m_config then

        if themeName == "Activity_RainbowRush" then
            self.m_config = util_require("Activity.RainbowRush.RainbowRushConfig")       -- 彩虹小马主题
        else
            self.m_config = util_require("Activity.BalloonRush.BalloonRushConfig")
        end

    end
    return self.m_config
end

function BalloonRushManager:isCanCollect()
    local act_data = self:getRunningData()
    if act_data then
        local cur_points = act_data:getCurPoints()
        local max_points = act_data:getMaxPoints()
        if cur_points and max_points and cur_points >= max_points then
            return true
        end
    end
    return false
end

-- 领取奖励消息
function BalloonRushManager:collectRewards(bl_collect)
    if bl_collect == nil then
        bl_collect = false
    end
    local bNovice = false
    local actData = self:getData()
    if actData and actData:isNovice() then
        bNovice = true
    end
    local function successCallFun(result)
        if result.code == "SUCCESS" then
            local ShopItem = require "data.baseDatas.ShopItem"

            local itemList = {}
            local rewardCoins = tonumber(result.coins) or 0
            if rewardCoins > 0 then
                local itemData = gLobalItemManager:createLocalItemData("Coins", rewardCoins)
                table.insert(itemList, itemData)
            end

            if result.items and table.nums(result.items) > 0 then
                for _, item_data in pairs(result.items) do
                    local shopItem = ShopItem:create()
                    shopItem:parseData(item_data, true)
                    table.insert(itemList, shopItem)
                end
            end
            -- 存储奖励物品
            local act_data = self:getRunningData()
            if act_data then
                act_data:saveRewards(itemList, rewardCoins)
            end

            -- 立即领取
            if bl_collect then
                self:showRewardLayer()
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.BalloonRush})
            end
        end
    end

    local function failedCallFun(errorCode, errorData)
        --gLobalViewManager:showReConnect()
        if errorCode then
            printError("balloonrush requestCollect error " .. errorCode)
        else
            printError("balloonrush requestCollect error ")
        end
    end

    self.m_balloonRushNet:requestCollect(successCallFun, failedCallFun, bNovice)
end

------------------------------ 活动中用到的一些标记位 ------------------------------
function BalloonRushManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local themeName = self:getThemeName()

    if gLobalViewManager:getViewByExtendData("Activity_BalloonRush") == nil then

        local mainUI = nil
        if themeName == "Activity_RainbowRush" then
            mainUI = util_createView("Activity.Activity_RainbowRush")              --    彩虹小马主题
        else
            mainUI = util_createView("Activity.Activity_BalloonRush")
        end


        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
    if self:isCanCollect() then
        self:collectRewards(false)
    end
end

function BalloonRushManager:getMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local themeName = self:getThemeName()
    
    if gLobalViewManager:getViewByExtendData("Activity_BalloonRush") == nil then

        local mainUI = nil
        if themeName == "Activity_RainbowRush" then
            mainUI = util_createView("Activity.Activity_RainbowRush")              --    彩虹小马主题
        else
            mainUI = util_createView("Activity.Activity_BalloonRush")
        end
        
        return mainUI
    end
end

-- function BalloonRushManager:createBetTipNode()
--     local betTipNode = nil
--     local themeName = self:getThemeName()
--     if themeName == "Activity_RainbowRush" then
--         betTipNode = util_createView("Activity.RainbowRush.RainbowRushBetTip")              --    彩虹小马主题
--     else
--         betTipNode = util_createView("Activity.BalloonRush.BalloonRushBetTip")
--     end     
--     return betTipNode
-- end

function BalloonRushManager:showRewardLayer()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    local itemList, coins = act_data:getRewards()
    if table.nums(itemList) <= 0 and coins <= 0 then
        -- 没有奖励
        return
    end

    -- 清空奖励
    act_data:saveRewards({}, 0)

    local themeName = self:getThemeName()

    local rewardLayer =
        gLobalItemManager:createRewardLayer(
        itemList,
        function()
            -- 高倍场点数
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
            -- 刷新钻石
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
            -- 掉落卡
            if CardSysManager:needDropCards("BALLOON RUSH") then
                gLobalNoticManager:addObserver(
                    self,
                    function(sender, func)
                        gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                        -- 高倍场
                        globalDeluxeManager:dropExperienceCardItemEvt(
                            function()
                                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                            end
                        )
                    end,
                    ViewEventType.NOTIFY_CARD_SYS_OVER
                )
                CardSysManager:doDropCards("BALLOON RUSH")
            else
                -- 高倍场
                globalDeluxeManager:dropExperienceCardItemEvt(
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    end
                )
            end
        end,
        coins,
        true,
        themeName                  --            -- theme 选填 根据不同主题 显示不同UI           
    )
    gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
end

-- 关卡logo
function BalloonRushManager:getLevelLogoRes()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end

    local config = self:getConfig()
    if not config then
        return
    end

    if globalData.slotRunData:isFramePortrait() then
        return config.logo_ver
    else
        return config.logo_hor
    end
end

function BalloonRushManager:setSlotData(play_data)
    self.slot_iconNum = play_data.iconNum or 0
    self.slot_point = play_data.point or 0

    local act_data = self:getRunningData()
    if act_data then
        act_data:setCurPoint(play_data.totalPoint)
    end
end

-- 获取本次spin产出logo个数
function BalloonRushManager:getSlotData()
    return self.slot_iconNum, self.slot_point
end

-- 清空本次spin数据
function BalloonRushManager:clearSlotData()
    self.slot_iconNum = 0
    self.slot_point = 0
end

function BalloonRushManager:getLogoAnim()
    local config = self:getConfig()
    if config then
        return config.logo_anim
    end
end

function BalloonRushManager:setIsActive(bl_active)
    self.bl_active = bl_active
end

function BalloonRushManager:getIsActive()
    return self.bl_active or false
end

function BalloonRushManager:getEntryPath(entryName)
    local themeName = self:getThemeName()
    --Dynamic/Activity_RainbowRushCode/Activity/Activity_RainbowRushEntryNode.lua
    return "Activity/" .. themeName .. "EntryNode" 
 end

-- 关卡内入口
function BalloonRushManager:getEntryModule()
    local act_data = self:getRunningData()
    if not act_data or act_data:isAllCollected() then
        return ""
    end
    local _module = BalloonRushManager.super.getEntryModule(self:getInstance())
    return _module
end

-- 切换bet是否显示气泡
function BalloonRushManager:isCanShowBetBubble()
    if not BalloonRushManager.super.isCanShowBetBubble(self) then
        return false
    end    
    -- 判断是否有数据
    local act_data = self:getRunningData()
    if not act_data then
        return false
    end

    if act_data:isAllCollected() then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    if not (globalData.slotRunData and globalData.slotRunData.machineData) then
        return false
    end
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    if not betList then
        return false
    end
    local curIndex = globalData.slotRunData:getCurBetIndex()
    local bet_data = betList[curIndex]
    if not bet_data then
        return false
    end
    if not bet_data.p_balloonRushScores or table.nums(bet_data.p_balloonRushScores) <= 0 then
        return false
    end
    return true
end

function BalloonRushManager:getBetBubblePath(_refName)
    local themeName = self:getThemeName()
    if themeName == "Activity_RainbowRush" then
        return "Activity/RainbowRush/RainbowRushBetTip" -- 彩虹小马主题
    end
    return "Activity/BalloonRush/BalloonRushBetTip"
end


return BalloonRushManager
