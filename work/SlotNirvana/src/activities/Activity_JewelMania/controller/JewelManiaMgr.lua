--[[
]]
util_require("activities.Activity_JewelMania.config.JewelManiaCfg")
--local JewelManiaNet = require("activities.Activity_JewelMania.net.JewelManiaNet")
local JewelManiaGuideMgr = util_require("activities.Activity_JewelMania.controller.JewelManiaGuideMgr")
local JewelManiaMgr = class("JewelManiaMgr", BaseActivityControl)

function JewelManiaMgr:ctor()
    JewelManiaMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.JewelMania)

    self.m_isCanClick = true  -- 设置是否可以点击状态，在每关结束后用的

    self.m_guideMgr = JewelManiaGuideMgr:getInstance()
    -- self.m_netModel = JewelManiaNet:getInstance()

    --购买特殊章节付费额外参数
    self.m_buyChapterPayExtra = nil

    self.m_logMsg = {}

    self.multiple = 1

    self:registerObserver()
end

function JewelManiaMgr:onEnter()
    JewelManiaMgr.super.onEnter(self)

    local data = self:getRunningData()
    local pickaxe = 0
    if data then
        pickaxe = data:getShovels()
    end
    self.clonePickaxe = clone(pickaxe)
    if self.clonePickaxe < 60 then
        self.multiple = 1
    else
        self.multiple = math.floor(self.clonePickaxe / 60)
    end
end

function JewelManiaMgr:registerObserver()

    -- SPIN后数据解析
    -- 关卡spin消息回调
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData and spinData.action == "SPIN" then -- and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                    if globalData.slotRunData.machineData ~= nil then
                        local data = self:getRunningData()
                        local popNums = 0
                        if data then
                            if data:getCurrentSpecialChapter() > 1 then
                                return
                            end
                            local pickaxe = data:getShovels()
                            self.clonePickaxe = self.clonePickaxe or pickaxe
                            
                            -- 超过60的倍数就弹一次
                            if self.clonePickaxe > 60 * self.multiple then
                                popNums = popNums + 1
                            end
                            
                            if popNums > 0 then
                                self:showGoToPlayLayer(pickaxe)
                                popNums = 0
                                self.clonePickaxe = pickaxe
                                self.multiple = self.multiple + 1
                            else
                                self.clonePickaxe = pickaxe
                            end
                        end
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

end

-- function JewelManiaMgr:onRegister()
--     JewelManiaMgr.super.onRegister(self)
--     self.m_guideMgr:onRegist()
-- end

-- 报错日志
function JewelManiaMgr:setErrorLog(_key, _msg)
    if _key == nil or _msg == nil or msg == "" then
        return
    end
    if not self.m_logMsg[_key] then
        self.m_logMsg[_key] = ""
    end
    self.m_logMsg[_key] = self.m_logMsg[_key] .. "\n" .. _msg
end

function JewelManiaMgr:getErrorLog(_key)
    if _key ~= nil then
        return self.m_logMsg[_key] or "null"
    end
    return "null"
end

function JewelManiaMgr:setCanClick(status) -- 动画开始调用（true） 动画结束调用（false） 
    self.m_isCanClick = status     
end

function JewelManiaMgr:isCanClick()
    return self.m_isCanClick       
end


function JewelManiaMgr:getGuideMgr()
    return self.m_guideMgr
end

function JewelManiaMgr:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    local data = self:getRunningData()
    if not data then
        return false
    end
    if not (data:getCurrentChapter() == 1) then
        return false
    end
    local jewelData = data:getJewelByType(JewelManiaCfg.GuideJewelType)
    if not jewelData then
        return false
    end
    if name == "enterJewelMain" or name == "clickJewelChapter" then
        -- 主页只判断是否点击过石板
        local slateIndexs = jewelData:getPositionList()
        if slateIndexs and #slateIndexs > 0 then
            for i=1,#slateIndexs do
                local slateData = data:getSlateByIndex(slateIndexs[i])
                if slateData:isMined() then
                    return false
                end
            end
        end
    elseif name == "enterJewelChapter" then
        -- 石板判断是全部挖出
        if jewelData:isMined() then
            return false
        end
    end
    local themeName = self:getThemeName()
    return self.m_guideMgr:triggerGuide(view, name, themeName)
end

-- 大厅展示资源判断
function JewelManiaMgr:isDownloadLobbyRes()
    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

function JewelManiaMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function JewelManiaMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function JewelManiaMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function JewelManiaMgr:isCanShowPop(...)
    local isCanShow = JewelManiaMgr.super.isCanShowPop(self, ...)
    if isCanShow then
        if gLobalViewManager:getViewByExtendData("Activity_JewelMania") ~= nil then
            isCanShow = false
        end
    end
    return isCanShow
end

-- -- 转场CG
-- -- 一天只播放一次， 只有点击宣传入的按钮后才播放
-- function JewelManiaMgr:showCGLayer()
--     if not self:isCanShowLayer() then
--         return
--     end
--     if gLobalViewManager:getViewByExtendData("JMCGLayer") then
--         return
--     end
--     local themeName = self:getThemeName()
--     local view = util_createView(themeName..".Code.main.JMCGLayer")
--     self:showLayer(view, ViewZorder.ZORDER_UI+1)
--     return view
-- end

-- 显示主弹板
function JewelManiaMgr:showMainLayer(_srcName)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("JMMainLayer") then
        return
    end

    self.m_guideMgr:onRegist()

    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.main.JMMainLayer", _srcName)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 获取 JMCMainLayer
function JewelManiaMgr:getJMCMainLayer()
    if gLobalViewManager:getViewByExtendData("JMCMainLayer") then
        return gLobalViewManager:getViewByExtendData("JMCMainLayer")
    end
end

-- -- 领奖界面 （暂无）
-- function JewelManiaMgr:showRewardLayer(_rewardData, _over)
-- end

-- 付费弹板
function JewelManiaMgr:showPurchaseLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    local data = self:getRunningData()
    if not data or not data:isRunning() then
        return
    end

    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.main.JMPayLayer", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 说明界面
function JewelManiaMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.main.JMInfoLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- BreakAll 提示界面
function JewelManiaMgr:showBreakAllLayer()
    if not self:isCanShowLayer() then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.chapter.JMCBreakAllLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 关卡spin跳转界面
function JewelManiaMgr:showGoToPlayLayer(pickaxe)
    if not self:isShowGoTo() then
        return
    end

    if not self:isCanShowLayer() then
        return 
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.main.JMSpinGoToPlayLayer", pickaxe)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function JewelManiaMgr:saveShowGoToTime()
    local themeName = self:getThemeName()
    local lastTime = math.floor(util_getCurrnetTime())
    gLobalDataManager:setNumberByField("JewelManiaGoTo_" .. themeName , lastTime)
end

function JewelManiaMgr:isShowGoTo()
    local themeName = self:getThemeName()
    local oldSecs = math.floor(tonumber(gLobalDataManager:getNumberByField("JewelManiaGoTo_" .. themeName, 0)))

    if oldSecs == 0 then
        return true
    end

    local newSecs = util_getCurrnetTime()
    -- 服务器时间戳转本地时间
    local oldTM = util_UTC2TZ(oldSecs, -8)
    local newTM = util_UTC2TZ(newSecs, -8)
    if oldTM.day ~= newTM.day then
        return true
    end
    return false
end

-- 任务界面
function JewelManiaMgr:showTaskLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("JMTaskLayer") then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.task.JMTaskLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 章节小游戏: 主界面
function JewelManiaMgr:showLevelMainLayer(_over, chapterIndex)
    if not self:isCanShowLayer() then
        return
    end

    local data = self:getRunningData()
    if not data then
        return false
    end
    if (data:getCurrentChapter() ~= chapterIndex) then
        -- 进入的不是当前章节
        return false
    end

    if gLobalViewManager:getViewByExtendData("JMCMainLayer") then
        return
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    if chapterIndex ~= data:getCurrentChapter() then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Code.chapter.JMCMainLayer", _over, chapterIndex)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function JewelManiaMgr:showRewardLayer(_rewardDatas, _cardDropSource, _over)
    local function callFunc()
        if _over then
            _over()
        end
    end
    if not self:isCanShowLayer() then
        return
    end
    if not (_rewardDatas and #_rewardDatas > 0) then
        return
    end

    local coinNum = 0
    for i = 1, #_rewardDatas do
        local itemData = _rewardDatas[i]
        if itemData.p_icon == "Coins" then
            coinNum = coinNum + itemData.p_num
        end
    end

    local m_catFoodList = {}
    local m_propsBagist = {}
    -- 不弹合成福袋的弹板，弹板太多了
    if #_rewardDatas > 0 then
        for i, tempData in ipairs(_rewardDatas) do
            -- 高倍场小游戏猫粮会有单独 弹板并且弹板顺序有逻辑
            if string.find(tempData.p_icon, "CatFood") then
                -- table.insert(m_catFoodList, tempData)
            end
            if string.find(tempData.p_icon, "Pouch") then
                -- table.insert(m_propsBagist, tempData)
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                mergeManager:refreshBagsNum(tempData.p_icon, tempData.p_num)                
            end
        end
    end
    -- 队列
    local _funcList = {}
    _funcList[#_funcList + 1] = function()
        self:triggerDropCards(_cardDropSource)
    end
    _funcList[#_funcList + 1] = function()
        self:triggerCatFoodView(m_catFoodList)
    end
    _funcList[#_funcList + 1] = handler(self, self.triggerDeluxeCard)
    _funcList[#_funcList + 1] = function()
        self:triggerPropsBagView(m_propsBagist)
    end
    _funcList[#_funcList + 1] = function()
        callFunc()
    end
    self.m_dropFuncList = _funcList

    local function closeReward()
        self:triggerDropFuncNext()
    end
    local view = gLobalItemManager:createRewardLayer(_rewardDatas, closeReward, coinNum, nil, nil, cc.size(210, 200))
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 检测 list 调用方法
function JewelManiaMgr:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        return
    end
    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉卡
function JewelManiaMgr:triggerDropCards(_source)
    if CardSysManager:needDropCards(_source) == true then
        CardSysManager:doDropCards(
            _source,
            function()
                self:triggerDropFuncNext()
            end,
            true
        )
    else
        self:triggerDropFuncNext()
    end
end

-- 检测掉落猫粮
function JewelManiaMgr:triggerCatFoodView(_catFoodList)
    G_GetMgr(ACTIVITY_REF.DeluxeClubCat):popCatFoodRewardPanel(
        _catFoodList,
        function()
            self:triggerDropFuncNext()
        end
    )
end

-- 检测高倍场体验卡
function JewelManiaMgr:triggerDeluxeCard()
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM,
        function()
            self:triggerDropFuncNext()
        end
    )
end

-- 检测掉落 合成福袋
function JewelManiaMgr:triggerPropsBagView(_propsBagist)
    G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):popMergePropsBagRewardPanel(
        _propsBagist,
        function()
            self:triggerDropFuncNext()
        end
    )
end

-- -- 特殊玩法付费弹板
-- function JewelManiaMgr:showSlatePurchaseLayer(_over)
--     if not self:isCanShowLayer() then
--         return
--     end
--     local data = self:getRunningData()
--     if not data or not data:isRunning() then
--         return
--     end

--     local themeName = self:getThemeName()
--     local view = util_createView(themeName .. ".Code.chapter.JMCPurchaseLayer", _over)
--     self:showLayer(view, ViewZorder.ZORDER_UI)
--     return view
-- end

-- function JewelManiaMgr:showPopLayer(popInfo, callback)
--     if not self:isCanShowPop() then
--         return nil
--     end

--     if popInfo and popInfo.clickFlag then
--         self:showLevelMainLayer()  --小游戏测试用，这个不用了，在hallnode里用按钮
--     end
--     return nil
-- end

function JewelManiaMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function JewelManiaMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function JewelManiaMgr:getSlidePath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "SlideNode"
end

-- -- 章节小游戏: 付费弹板 （暂无）
-- function JewelManiaMgr:showLevelPurchaseLayer(_over)
-- end

-- -- 章节小游戏: 说明界面（暂无）
-- function JewelManiaMgr:showLevelInfoLayer()
--     if not self:isCanShowLayer() then
--         return
--     end
--     if gLobalViewManager:getViewByExtendData("JMCInfoLayer") then
--         return
--     end
--     local themeName = self:getThemeName()
--     local view = util_createView(themeName..".Code.chapter.JMCInfoLayer")
--     self:showLayer(view, ViewZorder.ZORDER_UI)
--     return view
-- end

function JewelManiaMgr:sendClickSlateReq(type, slateIndex, jewelIndex) -- type 特殊章节还是普通章节  slateIndex
    local data = self:getRunningData()

    local slateList = data:getSlateList()
    local jewelList = data:getJewelList()
    self.cloneSlateList = clone(slateList)
    self.cloneJewelList = clone(jewelList)

    local successFunc = function(_resData)
        if data then
            if slateIndex == 0 then -- 全碎
                data:parseClickSlateResultData(_resData, slateIndex)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JMC_PLAYALL_SUCC, {result = _resData, slateList = self.cloneSlateList, jewelList = self.cloneJewelList})
            else -- 点哪个碎哪个
                data:parseClickSlateResultData(_resData, slateIndex)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JMC_PLAYSUCC, {result = _resData, slateIndex = slateIndex, jewelIndex = jewelIndex, type = type})
            end
        end
    end
    local failFunc = function()
    end
    G_GetNetModel(NetType.JewelMania):sendClickSlateReq(type, slateIndex, successFunc, failFunc)
end

function JewelManiaMgr:getEntryPath()
    return self:getThemeName() .. "/Code/entry/JMEntryNode"
end

-- 存本地
function JewelManiaMgr:saveCGTime()
    -- local curTime = util_getCurrnetTime()
    local data = self:getData()
    local timeExpireAt = 0
    if data then
        timeExpireAt = data:getExpireAt()
    end
    gLobalDataManager:setNumberByField("JewelManiaCGTime_" .. timeExpireAt , 1)
end

-- 是否显示CG
function JewelManiaMgr:isShowCG()
    local data = self:getData()
    local timeExpireAt = 0
    if data then
        timeExpireAt = data:getExpireAt()
    end
    local lastTime = gLobalDataManager:getNumberByField("JewelManiaCGTime_" .. timeExpireAt, 0)
    if lastTime == 0 then
        return true
    end
    -- -- 是否跨天
    -- local oldSecs = lastTime
    -- local newSecs = util_getCurrnetTime()
    -- -- 服务器时间戳转本地时间
    -- local oldTM = util_UTC2TZ(oldSecs, -8)
    -- local newTM = util_UTC2TZ(newSecs, -8)
    -- if oldTM.day ~= newTM.day then
    --     return true
    -- end
    return false
end

function JewelManiaMgr:isFirstChapterUnlock()
    local data = self:getRunningData()
    if not data then
        return false
    end
    local themeName = self:getThemeName()
    if data:getCurrentChapter() == 1 then
        local isOver, stepId = self.m_guideMgr:getGuideRecordStepId("enterJewelMain", themeName)
        if isOver == false and stepId == "1001" then
            return false
        end
    end
    return true
end

-- 是否是免费特殊章节
function JewelManiaMgr:isFreeSpecialChapter()
    local _data = self:getRunningData()
    if not _data then
        return false
    end

    if _data:getCurrentSpecialChapter() == 1 then
        return true
    end

    return false
end

local JewelManiaLastBuyType = "JewelManiaLastBuyType"
function JewelManiaMgr:setLastBuyType(payType)
    gLobalDataManager:setStringByField(JewelManiaLastBuyType, payType, true)
end

function JewelManiaMgr:getLastBuyType()
    local default = "specialChapter"
    local res = gLobalDataManager:getStringByField(JewelManiaLastBuyType, default, true)
    return res
end

-- 购买解锁活动Pass、特殊玩法
function JewelManiaMgr:buyChapterPay(_payData)
    self.m_buyChapterPayExtra = _payData:getPayType()

    self:setLastBuyType(self.m_buyChapterPayExtra)
    
    local succCallFunc = function()
        gLobalViewManager:checkBuyTipList(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JEWELMANIA_PAY_COMPLETE, {success = true, payType = _payData:getPayType()})
            end
        )
        self.m_buyChapterPayExtra = nil
    end
    local failedCallFunc = function(_errorInfo)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JEWELMANIA_PAY_COMPLETE, {success = false, payType = _payData:getPayType(), errorInfo = _errorInfo})
        self.m_buyChapterPayExtra = nil
    end
    G_GetNetModel(NetType.JewelMania):buyChapterPay(_payData, succCallFunc, failedCallFunc)
end

function JewelManiaMgr:getbuyChapterPayExtra()
    return self.m_buyChapterPayExtra
end

function JewelManiaMgr:sendCollectChapterReward(_chapterIndex, _type, _successFunc, _failFunc)
    local function _succ(_result)
        -- local data = G_GetMgr(ACTIVITY_REF.JewelMania):getRunningData()
        -- if data then
        --     data:parsePassData(_result)
        -- end
        if _successFunc then
            _successFunc(_result)
        end
    end
    local function _fail()
        if _failFunc then
            _failFunc()
        end
    end
    G_GetNetModel(NetType.JewelMania):sendCollectChapterReward(_chapterIndex, _type, _succ, _fail)
end

return JewelManiaMgr
