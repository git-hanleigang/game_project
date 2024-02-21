-- blast 控制类
local BlastNet = require("activities.Activity_Blast.net.BlastNet")
local BlastManager = class("BlastManager", BaseActivityControl)

function BlastManager:ctor()
    BlastManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Blast)
    self.BlastConfig = util_require("activities.Activity_Blast.config.BlastConfig")
    self.bl_configInit = false
    self.stage_clear = false
    self.cell_enable = false
    self.bl_maxShow = false
    self.bl_CollectShow = false
    self.bl_picksCanShow = true
    self.bl_btnclose = true

    self.m_blastNet = BlastNet:getInstance()

    self:registEvents()
    self:addExtendResList("Activity_BlastCode", "Activity_Blast_loading")
end

function BlastManager:updataConfig()
    local blast_data = self:getRunningData()
    if not blast_data then
        return
    end
    local cur_theme = blast_data:getThemeName()
    local config_theme = self.BlastConfig.getThemeName()
    if not cur_theme or cur_theme ~= config_theme or not self.bl_configInit then
        self.bl_configInit = true
        self.BlastConfig.setThemeName(cur_theme)
    end
end

function BlastManager:getConfig()
    local blast_data = self:getRunningData()
    if not blast_data then
        return self.BlastConfig
    end
    local cur_theme = blast_data:getThemeName()
    local config_theme = self.BlastConfig.getThemeName()
    if not cur_theme or cur_theme ~= config_theme or not self.bl_configInit then
        self.bl_configInit = true
        self.BlastConfig.setThemeName(cur_theme)
    end
    return self.BlastConfig
end

function BlastManager:registEvents()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setStageClear(false)
            self:setCellIsEnable(true)
        end,
        ViewEventType.NOTIFY_BLAST_STAGE_START
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setCellIsEnable(true)
        end,
        ViewEventType.NOTIFY_BLAST_PICK_FINISHED
    )
end

-- 开始前的默认状态 做一些点击保护
function BlastManager:willStart()
    self:setCellIsEnable(false)
    self:setStageClear(false)
    self:setCanClose(true)
end

-- 正式开启 去掉点击保护
function BlastManager:start()
    self:setCellIsEnable(true)
    self:setStageClear(false)
end

function BlastManager:setCellIsEnable(enable)
    self.cell_enable = enable
end

function BlastManager:getCellIsEnable()
    return self.cell_enable
end

-- 发送获取排行榜消息
function BlastManager:getRank(loadingLayerFlag)
    -- 数据不全 不执行请求
    if not self:getRunningData() then
        return
    end

    local successCallFunc = function(rankData)
        -- if resultData.result ~= nil then
        --     local rankData = cjson.decode(resultData.result)
        if rankData ~= nil then
            local blastData = self:getRunningData()
            if blastData then
                blastData:parseBlastRankConfig(rankData)
            end
            if loadingLayerFlag and loadingLayerFlag == 99 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BLAST_RANK_CLOOECT)
            end
        end
    end

    local function failedCallFunc(target, code, errorMsg)
        gLobalViewManager:showReConnect()
    end
    self.m_blastNet:requestRankData(loadingLayerFlag, successCallFunc, failedCallFunc)
end

function BlastManager:getPicks()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getPicks()
    end
    return 0
end

function BlastManager:getPicksLimit()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getPicksLimit()
    end
    return 0
end

-- 关卡id列表
function BlastManager:getStageIds()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getStageIds()
    end
    return {}
end

function BlastManager:getStageDataById(_id)
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getStageDataById(_id)
    end
    return {}
end

function BlastManager:getStageBombDataById()
   return self:getStageDataById(self:getCurrentStageId())
end

function BlastManager:getCurrentStageId()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getCurrentStageId()
    end
end
--获取金票的数量
function BlastManager:getHits()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getHits()
    end
    return 1
end

-- 获取金票持有的最大值(商城和促销购买获得的)
function BlastManager:getHitsMax()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getHitsMax()
    end
    return 1
end

--获取第几轮
function BlastManager:getRound()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getRound()
    end
    return 0
end

-- 当前关卡数据
function BlastManager:getCurrentStageData()
    local _id = self:getCurrentStageId()
    return self:getStageDataById(_id)
end

-- 修改关卡数据
function BlastManager:setCurrentStageData(_index)
    local _id = self:getCurrentStageId()
    local data = self:getStageDataById(_id)
    if data then
        if _index == 1 then
            data.affairPick = false
        elseif _index == 2 then
            data.affairOpen = nil
        elseif _index == 3 then
            data.affairPick = nil
        end
    end
end

function BlastManager:getCurrentCellIndex()
    return self.curCellIdx
end

function BlastManager:getCellData(idx)
    local stage_data = self:getCurrentStageData()
    if stage_data and stage_data:getBoxs() then
        return stage_data:getBoxs()[idx]
    end
end

function BlastManager:setPickData()
    local gameData = self:getRunningData()
    if gameData then
        gameData:setPickData()
    end
end

function BlastManager:getBomsNum()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getBomsNum()
    end
    return 0
end

function BlastManager:getStageRewardById(_id)
    local gameData = self:getRunningData()
    if not gameData then
        return
    end
    local stage_data = self:getStageDataById(_id)
    return stage_data
end

function BlastManager:getJcCoins(_data)
    local newCoin = toLongNumber(0)
    local coins = _data:getCoins()
    local baseCoin = _data:getBaseCoins()
    local blastBuffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BLAST_TREASURE_BUFF) -- 宝箱
    if blastBuffTimeLeft > 0 then
        newCoin:setNum(coins + baseCoin)
    else
        newCoin:setNum(coins)
    end
    return newCoin
end

-- 当前关卡奖励
function BlastManager:getCurrentStageReward()
    local _id = self:getCurrentStageId()
    return self:getStageRewardById(_id)
end

function BlastManager:getJackpotDataByType(_type)
    local gameData = self:getRunningData()
    if not gameData then
        return
    end
    local jackpot_data = gameData:getJackpotDataById(_type)
    return jackpot_data
end

-- 发送翻牌消息
function BlastManager:pick(_idx)
    -- 等待消息结果
    local success_call_fun = function(resData)
        -- self.bl_waitting = false
        local blastData = self:getRunningData()
        if blastData then
            if resData ~= nil then
                blastData:parsePickData(resData,_idx)
            else
                local errorMsg = "parse blast play json error"
                printInfo(errorMsg)
                release_print(errorMsg)
                gLobalViewManager:showReConnect()
            end
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        -- self.bl_waitting = false
        gLobalViewManager:showReConnect()
        -- 放开格子点击
        self:setCellIsEnable(true)
    end

    local stage_data = self:getCurrentStageData()
    self.m_blastNet:requestPick(_idx, success_call_fun, faild_call_fun)
    -- self.bl_waitting = true
    -- 屏蔽格子点击
    self:setCellIsEnable(false)
    self.curCellIdx = _idx
end

-- 发送翻牌消息
function BlastManager:requestBomData(_idx)
    local success_call_fun = function(resData)
        self.m_bompos = _idx
        local blastData = self:getRunningData()
        blastData:parseBombData(resData,_idx)
        --self:parseBom(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BLAST_BOMB,_idx)
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:showReConnect()
        -- 放开格子点击
        self:setCellIsEnable(true)
    end
    self.m_blastNet:requestBomData(_idx, success_call_fun, faild_call_fun)
    self:setCellIsEnable(false)
    self.curCellIdx = _idx
end

function BlastManager:setBombStage(_flag)
    self.m_isBomb = _flag
end

function BlastManager:getBombStage()
    return self.m_isBomb
end

function BlastManager:getBomResult()
    return self.m_bomdata
end

--发送三选一消息
function BlastManager:requestSelectData(_index)
    local successCallback = function(resData)
        local data = {}
        data.index = _index
        data.result = resData.result
        data.cardDropInfoResults = resData.cardDropInfoResults
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BLAT_THING_REWARD, data)
    end
    local failedCallback = function()
        -- body
        print("error----")
    end
    self.m_blastNet:requestSelectData(successCallback, failedCallback)
end

function BlastManager:getPickData()
    local gameData = self:getRunningData()
    if gameData then
        return gameData:getPickData()
    end
end

-- 过关道具数量 累积几个道具过关
function BlastManager:getPassItemCounts()
    local stageData = self:getCurrentStageData()
    return stageData:getTotalClear()
end

-- 当前持有过关道具数量
function BlastManager:getCurrentPassItemCount()
    local stageData = self:getCurrentStageData()
    return stageData:getCurrentClear()
end

-- 游戏过关标记
function BlastManager:setStageClear(bl_clear)
    self.stage_clear = bl_clear
end

function BlastManager:getStageClear()
    local gameData = self:getRunningData()
    if gameData and gameData:isRunning() then
        return self.stage_clear
    end
    return false
end

---------------- 关卡弹框标记 ----------------
-- 获得新blast次数
function BlastManager:setCanShowCollectUI(bl_show)
    self.bl_CollectShow = bl_show
end

function BlastManager:getCanShowCollectUI()
    return self.bl_CollectShow and self.bl_picksCanShow
end

-- blast次数积满
function BlastManager:setCanShowMaxUI(bl_show)
    self.bl_maxShow = bl_show
end

function BlastManager:getCanShowMaxUI()
    return self.bl_maxShow
end

function BlastManager:getCanClose()
    return self.bl_btnclose
end

function BlastManager:setCanClose(_iscan)
    self.bl_btnclose = _iscan
end

function BlastManager:setNewUserOver(_flag)
    self.m_over = _flag
end

function BlastManager:getNewUserOver()
    return self.m_over or false
end

function BlastManager:setConfigData()
    if self:getRunningData() and self:getRunningData():getConfigData() then
        self:getRunningData():setCompleted(true)
        globalData.commonActivityData:parseActivityData(self:getRunningData():getConfigData(), ACTIVITY_REF.Blast)
    end
end

-- 大厅展示资源判断
function BlastManager:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

function BlastManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return
    end
    local blastMainUI = nil
    if gLobalViewManager:getViewByExtendData("BlastMainUI") == nil then
        local data = self:getRunningData()
        if not data then
            return
        end
        local main_ui = self.BlastConfig.getThemeFile(self:getRunningData():getThemeName())
        if data:getNewUser() then
            main_ui = "Activity/BlastGame/MainUI/Blossom/BlossomBlastMainUI"
        end
        blastMainUI = util_createFindView(main_ui, params)
        if blastMainUI ~= nil then
            self:showLayer(blastMainUI, ViewZorder.ZORDER_UI - 2)
        end
    end
    return blastMainUI
end

function BlastManager:showPopLayer()
    -- if not self:isCanShowLayer() then
    --     return nil
    -- end

    -- local pop_name = self:getPopModule()
    -- if not pop_name or pop_name == "" then
    --     return
    -- end
    -- local data = {}
    -- local uiView = util_createView(pop_name,data)
    -- gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    local data = {}
    local uiView = BlastManager.super.showPopLayer(self, data)
    return uiView
end

--下面是人鱼blast
function BlastManager:showThingLayer(params)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity.BlastGame.MainUI.Mermaid.MermaidThingLayer", params)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--下面是人鱼blast
function BlastManager:showThingReward(params)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity.BlastGame.MainUI.Mermaid.MermaiReward", params)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end
--炸弹规则界面
function BlastManager:showBombRule(_flag)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity.BlastGame.NewMainUI.Blossom.BlastBomRule", _flag)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--收集领奖界面
function BlastManager:showCollectLayer(params)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity.BlastGame.NewReward.BlastCollectReward", params)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function BlastManager:getEntryPath(entryName)
   return "Activity/Activity_BlastEntryNode" 
end

function BlastManager:checkCollect()
    local gameData = self:getRunningData()
    if not gameData then
        return
    end
    local num = self:getCollectNum()
    if num > 0 then
        self:requestCollectReward()
    end
end

function BlastManager:getCollectNum()
    local gameData = self:getRunningData()
    if not gameData then
        return 0
    end
    local num = #gameData:getBoxPackage()
    return num
end

function BlastManager:getAllList()
    local gameData = self:getRunningData()
    if not gameData then
        return {}
    end
    local allList = {}
    local pack = gameData:getBoxPackage()
    if #pack > 0 then
        for i,v in ipairs(pack) do
            local shopItem = nil
            if v.type == "COIN" then
                shopItem = gLobalItemManager:createLocalItemData("Coins", v.coins, {p_limit = 3})
            elseif v.type == "Gem" then
                shopItem = gLobalItemManager:createLocalItemData("Gem", v.gems, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
            elseif v.type == "Card" then
                shopItem = v.items[1]
            end
            table.insert(allList,shopItem)
        end
    end
    return allList
end

-- 收集奖励
function BlastManager:requestCollectReward()
    local success_call_fun = function(resData)
        local collect = false
        local coins = toLongNumber(0)
        if not resData then
            return
        end
        if resData.collectCoins then
            coins:setNum(resData.collectCoins)
        end
        if coins > toLongNumber(0) or (resData.collectGems and resData.collectGems > 0) or (resData.collectItems and #resData.collectItems > 0) then
            collect = true
        end
        if not collect then
            return
        end
        local result = {}
        result.coins = coins
        result.gems = resData.collectGems
        result.items = resData.collectItems
        self:showCollectLayer(result)
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    self.m_blastNet:requestCollectReward(success_call_fun, faild_call_fun)
end

function BlastManager:getItemBoxData(_items)
    local data = clone(_items)
    local enddata = {}
    for i,v in ipairs(data) do
        if #enddata > 0 then
            local pt = nil
            local pl = 0
            for k=1,#enddata do
                local item = enddata[k]
                if v.p_type == item.p_type then
                    if v.p_icon == "Coins" then
                        item.p_coins = toLongNumber(item.p_coins or 0) + toLongNumber(v.p_coins or 0)
                        pl = 1
                    else
                        if v.p_icon == item.p_icon then
                            if v.p_type == "Buff" then
                                item.p_buffInfo.buffDuration = item.p_buffInfo.buffDuration + v.p_buffInfo.buffDuration
                                item.p_buffInfo.buffExpire = item.p_buffInfo.buffExpire + v.p_buffInfo.buffExpire
                            else
                                item.p_num = tonumber(item.p_num) + tonumber(v.p_num)
                            end
                            pl = 1
                        else
                            pt = v
                        end
                    end
                else
                    pt = v
                end
            end
            if pt and pl == 0 then
                table.insert(enddata,pt)
            end
        else
            table.insert(enddata,v)
        end
    end
    return enddata
end

return BlastManager
