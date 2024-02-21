local GamePusherManager = class("GamePusherManager",util_require("baseActivity.BaseActivityManager"))
local Config            = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")

local SendDataManager   = require "network.SendDataManager"
----------------------------------------------------------------------------------------
-- 框架(ctor, getInstance)
----------------------------------------------------------------------------------------
function GamePusherManager:ctor()
    GamePusherManager.super.ctor(self)
    self:initData()
end

function GamePusherManager:getInstance()
    if not self._instance then
		self._instance = GamePusherManager.new()
	end
	return self._instance
end

function GamePusherManager:initData()
    self.m_bAutoDrop = false
    self.m_JackpotScore = {}
    self:registerObserver()
end
----------------------------------------------------------------------------------------
-- 注册事件
----------------------------------------------------------------------------------------
function GamePusherManager:registerObserver()    

end

----------------------------------------------------------------------------------------
-- 生成金币和推下信息
----------------------------------------------------------------------------------------
function GamePusherManager:touchDropCoins(_vTouchPos)               -- 点击推币机申请掉落道具
    -- 金币个数 -1 save

    local playingData = self:getPusherUseData( ) or {}
    local pusherMaxUseNum = playingData.pusherMaxUseNum
    if pusherMaxUseNum > 0 then

        local netInitData = playingData.netInitData or {}

        -- 存储本地playingData pusherMaxUseNum
        local data = {}
        data.pusherMaxUseNum = pusherMaxUseNum  - 1
        self:updatePlayingData( data )

        --点击掉落金币  
        local weight = netInitData.slotCoinWeight
        local coinPileMaxUseNum = netInitData.coinPileMaxUseNum or 0
        if data.pusherMaxUseNum < coinPileMaxUseNum then
            weight = netInitData.slotCoinPileWeight or weight
        end
        local tDropData = self:getSpinEntityDataForCalculation(weight, 1 ) 
        
        
        local tActionData = {tDropData, {entityPos = _vTouchPos}}
        local playData = self:createPlayData("DROP", tActionData)  
        self.m_pusherMain:playDropCoinsEffect( playData.m_tRunningData.ActionData )   

        
        -- 存储到本地
        -- self:saveRunningData()

        self:updataLeftCoinsTimes(data.pusherMaxUseNum )
    end
    
end

function GamePusherManager:dropFromTable(_sType)
    -- 进度++  轮盘个数++  save

    local playingData = self:getPusherUseData( ) or {}
    local collectCurrNum = playingData.collectCurrNum
    if collectCurrNum == nil then
        release_print(" collectCurrNum == nil ---playingData 数据 --"..json.encode(playingData))
    end

    -- 存储本地playingData pusherMaxUseNum
    
    local addCoinsNum = 0
    if _sType == Config.CoinModelRefer.NORMAL then -- "NORMAL"
        -- 目前普通金币掉落时不加入playList的
        addCoinsNum = Config.CollectCoinsProgress.NORMAL  
    elseif _sType == Config.CoinModelRefer.BIG then  -- "BIG"
        -- 目前大金币金币掉落时不加入playList的
        addCoinsNum = Config.CollectCoinsProgress.BIG  
    elseif _sType == Config.CoinModelRefer.SLOTS then  -- "SLOTS"
        addCoinsNum = Config.CollectCoinsProgress.SLOTS    
        self:updatePlayList("PushOut",_sType) 

    end

    -- 存储到本地
    local data = {}
    data.collectCurrNum = collectCurrNum  + addCoinsNum -- 目前收集的总金币数据
    self:updatePlayingData( data )
    -- self:saveRunningData()

    local params = {}
    params.coinNum = data.collectCurrNum
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_updateTotaleCoins,params) 

   
end


function GamePusherManager:addSlotsEffect(_sType,_sData)
    -- 进度++  轮盘个数++  save



    
    local index = self:getSlotsGameEffetInsertIndex()
    local actionData = {}
    actionData.SEType = _sType
    actionData.SEData = _sData
    self:updatePlayList("SlotsGame",actionData,index) 


    -- 存储到本地
    self:saveRunningData()

   
end

----------------------------------------------------------------------------------------
-- 数据初始化
----------------------------------------------------------------------------------------
--初始化游戏配置
function GamePusherManager:initGamePusher()
    self:loadGamePusherData()
end

function GamePusherManager:initSaveKey( )
    self.m_sEntitySaveKey = "GamePusherEntity" .. tostring(self:getBonusID())                --实体存档key
    self.m_sDataSaveKey   = "GamePusherData" .. tostring(self:getBonusID())                  --游戏数据存档key
end



-- 本地存档bonusID
function GamePusherManager:getBonusID()                                   
    return self.m_nBonusID
end

function GamePusherManager:setBonusID(_nID)                                   
    self.m_nBonusID = _nID
end

-- 初始化存档数据
function GamePusherManager:loadGamePusherData()
    self.m_tEntityData = self:loadEntityData()                                 --实体存档
    if self.m_tEntityData == nil or table_nums(self.m_tEntityData) == 0 then
        self.m_tEntityData = self:getDiskEntityData(self:getDiskEntityDataID())
    end
    self.m_tPlayList = {}
end

----------------------------------------------------------------------------------------
-- 存档和数据加载
----------------------------------------------------------------------------------------
--存储实体数据
function GamePusherManager:saveEntityData(_EntityInfo, _isFlush)
    local attJson = cjson.encode(_EntityInfo)

    gLobalDataManager:setStringByField(self.m_sEntitySaveKey, attJson, true)
end

--存储游戏数据
function GamePusherManager:saveRunningData(_isFlush)
    local tSaveRunningData = {}

    --退出时,有可能界面没加载完导致数据没有初始化,所以要做数据安全判定
    if not self.m_tPlayList then
        return
    end

    -- 本地存储的推币机需要使用的数据
    tSaveRunningData.playingData = self:getPusherUseData() --字段名称不要轻易修改会影响本地数据存储逻辑
    local PlayList = {}
    local index = 1
    for i = 1, #self.m_tPlayList do
        local aniData = self.m_tPlayList[i]
        if not aniData:checkAllStateDone() then
            PlayList[tostring(index)] = aniData.m_tRunningData
            index = index + 1
        end
    end
    tSaveRunningData.PlayList = PlayList

    local attJson = cjson.encode(tSaveRunningData)
    -- print("-------" .. attJson)

    gLobalDataManager:setStringByField(self.m_sDataSaveKey, attJson, true)
end

--load实体数据
function GamePusherManager:loadEntityData()
    local attJson = gLobalDataManager:getStringByField(self.m_sEntitySaveKey, "{}")
    local entityAttList = cjson.decode(attJson)
    return entityAttList
end

--load游戏数据
function GamePusherManager:loadRunningData()
    local attJson = gLobalDataManager:getStringByField(self.m_sDataSaveKey, "{}")
    local attJson = cjson.decode(attJson)
    return attJson
end

-- 清除金币信息数据
function GamePusherManager:clearPusherEntityData()
    gLobalDataManager:delValueByField(self.m_sEntitySaveKey)
end

--清除存盘数据
function GamePusherManager:clearRunningPusherData()
    self.m_tPlayList = {} -- 清理游戏事件列表
    self:setPusherUseData() -- 清除本地存储数据

    gLobalDataManager:delValueByField(self.m_sDataSaveKey)
end

----------------------------------------------------------------------------------------
-- 自定义盘面
----------------------------------------------------------------------------------------
--盘面初始数据
function GamePusherManager:saveCoinPusherDeskstopData(_tEntityData)
    local entityAttList = _tEntityData.Entity
    local attJson       = cjson.encode(entityAttList)
    local path = cc.FileUtils:getInstance():getWritablePath()
    local f = io.open(path .. "lilaoshi.lua", "w+")
    f:write(attJson)
    f:close()
end

function GamePusherManager:loadCoinPusherDeskstopData(  )
    local path = cc.FileUtils:getInstance():getWritablePath()
    local entityAttList = {}
    local f = io.open(path .. "lilaoshi.lua", "r")
    if f then
        entityAttList = f:read("*all")
        entityAttList = cjson.decode( entityAttList )
        f:close()
    end
    return entityAttList
end

--初始化盘面数据 GamePusherInitDiskConfig
function GamePusherManager:getDiskEntityData(_id)
    local sConfigPath = Config.ConfigPath
    if not cc.FileUtils:getInstance():isFileExist(sConfigPath) then
        assert(false, "没有盘面配置数据")
    end 
    local jsonDatas = cc.FileUtils:getInstance():getStringFromFile(sConfigPath)
    if jsonDatas and jsonDatas ~= "" then
        local decodeJsonDatas = cjson.decode(jsonDatas)
        local diskDatas =  decodeJsonDatas[tostring(_id)]  
        return  {Entity = diskDatas }
    end
    return {}
end
----------------------------------------------------------------------------------------
-- 逻辑
----------------------------------------------------------------------------------------

function GamePusherManager:setPusherUpWalls( _times,isSave )
    self.m_BuffUpWallsLT = _times

    local data = {}
    data.wallMaxUseTimes = _times
    self:updatePlayingData( data )
    
    if isSave then
        -- 存储到本地
        self:saveRunningData()
    end
end

function GamePusherManager:setMaxWallTime(_time )
    self.m_maxWallTime = _time
end

function GamePusherManager:getMaxWallTime( )
    return self.m_maxWallTime or 0
end

-- buff 城墙 > 0 有buff 
function GamePusherManager:getBuffUpWallsLT()
    return self.m_BuffUpWallsLT or 0
end

-- buff 推板 > 0 有buff 
function GamePusherManager:getBuffPusherLT()
    return 0
end

-- buff 双倍奖励 > 0 有buff 
function GamePusherManager:getBuffPrizeLT()
    return 0
end

-- 本地推币机台面金币堆类型配置
function GamePusherManager:getDiskEntityDataID()                                   
    return self.m_nDiskEntityDataID
end

function GamePusherManager:setDiskEntityDataID(_nID)                                   
    self.m_nDiskEntityDataID = _nID
end

function GamePusherManager:checkSlotsMiniGame(_slotsType )
    if  _slotsType == "SLOTS" then
        return true
    end
    return false
end

function GamePusherManager:getSlotsGameEffetInsertIndex( )
    if not(#self.m_tPlayList <= 1)  then
        for i=1,#self.m_tPlayList do
            local data = self.m_tPlayList[i]
            if self:checkSlotsMiniGame(data:getActionType())  then
                if data:getActionState() == Config.PlayState.PLAYING then
                    return i + 1
                end
            end
        end
    end
end


--更新动画列表 
function GamePusherManager:updatePlayList(_sType , _actionData , _insertIndex)    
    local playData       
    if _sType == "PushOut" then    
        -- 推下来的  
        playData = self:createPlayData(_actionData)
        self:setSpecialPlayInfo( _actionData,playData)
    elseif _sType == "SlotsGame" then    
        -- 小老虎机的  
        local runData = {}
        runData = _actionData.SEData
        playData = self:createPlayData(_actionData.SEType,runData)
        self:setSpecialPlayInfo( _actionData.SEType,playData)
    end

    
    if _insertIndex then
        table.insert(self.m_tPlayList,_insertIndex,playData)
    else
        self.m_tPlayList[table_nums(self.m_tPlayList) + 1] = playData
    end

    gLobalNoticManager:postNotification(Config.Event.GamePusherAddPlayList, {playData})
   
    return playData
end     

--断线重连
function GamePusherManager:initPlayListData()
    self.m_tPlayList = {}
    --load游戏数据
    local runningData = self:loadRunningData(  )
    local playList = runningData.PlayList or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if playList then
        for k,v in pairs(playList) do
            local index = tonumber(k)
            local info = v
            local playData = self:createPlayData(info.ActionType)
            playData.m_tRunningData = info
            self.m_tPlayList[index] = playData
            gLobalNoticManager:postNotification(Config.Event.GamePusherAddPlayList, {playData})
        end
    end
end

--断线重连
function GamePusherManager:reconnectionPlay()
    if table_nums(self.m_tPlayList) < 1 then
        return 
    end

    for i = #self.m_tPlayList,1, -1 do
        
        local data = self.m_tPlayList[i]
        if data:getActionState() == Config.PlayState.DONE  then
            self:checkPlayEffectEnd(data, i)
            return
        elseif data:getActionState() == Config.PlayState.PLAYING then
            self:triggerPlay(i)
            return
        end
    end 
end

function GamePusherManager:getOneEffectNum(_effect )
    local num = 0
    for i = #self.m_tPlayList,1, -1 do
        local data = self.m_tPlayList[i]
        local playState = data:getActionState()
        local actionType = data:getActionType() 

        if playState ~= Config.PlayState.DONE and _effect == actionType then
            num = num + 1
        end
    end

    return num
end

--刷帧监听动画
function GamePusherManager:playTick(_nDt)
    if table_nums(self.m_tPlayList) <  1 then
        return 
    end

    local hasPlaying = false

    for i = #self.m_tPlayList,1, -1 do
        local data = self.m_tPlayList[i]
        local playState = data:getActionState()

        if playState == Config.PlayState.DONE  then
            self:checkPlayEffectEnd(data, i)
        elseif playState == Config.PlayState.PLAYING then
            hasPlaying = true
            break
        end
    end

    --顺序播放 所以这里是从1开始
    if not hasPlaying and table_nums(self.m_tPlayList) >  0  then
        self:triggerPlay(1)
    end
end

--触发玩法
function GamePusherManager:triggerPlay(_index)
    local data = self:getPlayListData(_index)
    data:setActionState(Config.PlayState.PLAYING)
    self:saveRunningData() 

    local playType = data:getActionType()
    gLobalNoticManager:postNotification(Config.Event.GamePusherTriggerEffect, {playType, data})
end


--动画播完
function GamePusherManager:checkPlayEffectEnd(data, i)
    --更新UI
    gLobalNoticManager:postNotification(Config.Event.GamePusherUpdateMainUI)
    --移除完成的play
    table.remove( self.m_tPlayList,i)
end

function GamePusherManager:getPlayListData(index)
    return self.m_tPlayList[index]
end

function GamePusherManager:getPlayListCount()
    return table.nums(self.m_tPlayList) 
end

function GamePusherManager:setPlayEnd(data)
    data:setActionState(Config.PlayState.DONE)
    self:saveRunningData() 
end
    
---创建动画数据
function GamePusherManager:createPlayData(_sType, _data)
    local actionData = self:createActionData(_sType)
    --获取最新的数据
    actionData:setActionType(_sType)   -- 类型 
    actionData:setActionData(_data)   -- 数据

    return actionData               
end

function GamePusherManager:setSpecialPlayInfo( _sType,_actionData)

    if _sType == Config.CoinEffectRefer.SLOTS then
        
    elseif _sType == Config.CoinEffectRefer.COINSPILE then
        local coinPileNumlist =  self.m_pusherMain._SlotData.m_tRunningData.ActionData.coinPileNumlist or {}
        _actionData:setEffectData(coinPileNumlist)
    elseif _sType == Config.CoinEffectRefer.COINSRAIN then
        _actionData:setLastCoinsNum( Config.CoinsRainMaxDrop )
    elseif _sType == Config.CoinEffectRefer.CoinTower then
        _actionData:setAnimateStates( Config.CoinTowerAnimStates.TablePush)
    end


    
end


--各种动画数据
function GamePusherManager:createActionData(type)
    local actionData = nil
    if  type == Config.CoinEffectRefer.NORMAL  or 
            type == Config.CoinEffectRefer.SHAKE or 
                type == Config.CoinEffectRefer.BIGCOINS or 
                    type == Config.CoinEffectRefer.DROP then    
        actionData = util_createView(Config.ActionDataPathConfig.BaseActionData)
    elseif type == Config.CoinEffectRefer.COINSPILE  then
        actionData = util_createView(Config.ActionDataPathConfig.CoinsPileData)
    elseif type == Config.CoinEffectRefer.SLOTS then
        actionData = util_createView(Config.ActionDataPathConfig.SlotData)
    elseif type == Config.CoinEffectRefer.WALL then
        actionData = util_createView(Config.ActionDataPathConfig.WallData)
    elseif type == Config.CoinEffectRefer.COINSRAIN then
        actionData = util_createView(Config.ActionDataPathConfig.CoinsRainData)
    elseif type == Config.CoinEffectRefer.JACKPOT then
        actionData = util_createView(Config.ActionDataPathConfig.JackData)
    elseif type == Config.CoinEffectRefer.COINSTOWER then
        actionData = util_createView(Config.ActionDataPathConfig.CoinsTowerData)   
    end

    if not actionData then
        assert(false, "Cant find this Type Data! Please check your data!")
    end
    return actionData
end

function GamePusherManager:setAutoDrop(_bAuto)
    self.m_bAutoDrop = _bAuto
end

function GamePusherManager:checkAutoDrop()
    return self.m_bAutoDrop
end
----------------------------------------------------------------------------------------
-- 弹窗
----------------------------------------------------------------------------------------

--获奖弹窗
function GamePusherManager:showRewardView()

end

----------------------------------------------------------------------------------------
-- 外部接口(pubXXXXX)
----------------------------------------------------------------------------------------
-- 保存实体信息到文件
function GamePusherManager:pubSaveCoinPusherDeskstopData(_tEntityData)
    self:saveCoinPusherDeskstopData(_tEntityData)
end

-- 奖励弹窗
function GamePusherManager:pubShowRewardView()                                  
    self:showRewardView()
end

-- 获取存档数据
function GamePusherManager:pubGetEntityData()                                   
    return self.m_tEntityData
end


function GamePusherManager:pubSetAutoDrop(_bAuto)
    self:setAutoDrop(_bAuto)
end

function GamePusherManager:pubCheckAutoDrop()
    return self:checkAutoDrop()
end

-- 台子上币个数
function GamePusherManager:pubGetGamePusherCoins()                                   
    return {}
end

function GamePusherManager:pubCreatePusher()
    self:initGamePusher()
    self.m_pusherMain = util_createView(Config.ViewPathConfig.Main, true)
    return self.m_pusherMain 
end


function GamePusherManager:getFrontEffectNode( )
    return self.m_pusherMain.m_pEffectRoot._frontEffect
end

function GamePusherManager:pubStopPusherAllAnim( )
    self.m_pusherMain:stopPushing()
end

-- bonusEffect触发推币机玩法开始
function GamePusherManager:pubBeginPlayPuhsher( )
    self.m_pusherMain:startPushing()
end

function GamePusherManager:saveSendOverStates()
    local str = "send"

    gLobalDataManager:setStringByField(self.m_sEntitySaveKey .. Config.PusherRequestSaveId, str, true)
end

function GamePusherManager:clearSendOverStates()
    gLobalDataManager:delValueByField(self.m_sEntitySaveKey .. Config.PusherRequestSaveId)
end

--load实体数据
function GamePusherManager:loadSendOverStates()
    local str = gLobalDataManager:getStringByField(self.m_sEntitySaveKey .. Config.PusherRequestSaveId, "")
    return str
end

function GamePusherManager:requestBonusPusherOverNetData( )
    
    self:saveSendOverStates( )

    self:pubStopPusherAllAnim( )                -- 停止推币机动作
    self:setAllEntityNodeKinematic( true ,true )    -- 设置所有金币关闭碰撞检测

    self.m_pusherMain:hideLifter( ) -- 台子降下来

    local totalCoins = 0
    local jpCoins = nil

     --load游戏数据
     local pushersData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
     if pushersData and table_length(pushersData) ~= 0 then

        local netInitData = pushersData.netInitData or {}

        local jpTriggerd = netInitData.jpTriggerd  
        if jpTriggerd and jpTriggerd == 1 then 
             -- 如果本轮触发过jackpot，更新jackpot钱数
            local jackpotSignal = tonumber(netInitData.jackpotSignal)  
            local jpWinCoins = self.m_JackpotScore[self:getJpTypeIndex( jackpotSignal )] --本地存储的jackpot赢钱
            if jpWinCoins then
                jpCoins = jpWinCoins
            end
        end
       
        -- ** 更新收集的金币进度ui显示 
        local collectCurrNum = pushersData.collectCurrNum or 0  -- 当前收集的金币的个数
        totalCoins = collectCurrNum * self:getPusherTotalBet( )

        
     end

     
    self:requestBonusPusherNetData( totalCoins,jpCoins )

end

function GamePusherManager:setJpCoins(_index,_coins )
    self.m_JackpotScore[_index] = _coins
end

function GamePusherManager:getJpTypeIndex(_jpType )
    local index = 4
    if _jpType == Config.slotsSymbolType.Grand then
        index = 1
    elseif _jpType == Config.slotsSymbolType.Major then 
        index = 2
    elseif _jpType == Config.slotsSymbolType.Minor then 
        index = 3
    elseif _jpType == Config.slotsSymbolType.Mini then  
        index = 4
    end
    return index
end

-- 请求bonus消息
function GamePusherManager:requestBonusPusherNetData( _totalCoins,_jpCoins,_erroOver )
    
    local sendData   = {}
    local extraData  = nil

    if _totalCoins  then
        -- 最后结束的时候需要向服务器发送金币钱数
        sendData[1] = _totalCoins
    end

    if  _jpCoins then
        -- 最后结束的时候需要向服务器发送中圆盘玩法的jp钱数
        sendData[2] = _jpCoins
    end

    if #sendData == 0  then
        sendData = nil
    else
        if not  _erroOver then
            extraData = {}
            local pushersData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
            if pushersData and table_length(pushersData) ~= 0 then
                -- 当前收集的金币的个数
                extraData.coinNum  = pushersData.collectCurrNum or 0  
                extraData.itemsNum = pushersData.collectItemsNum or self:getInitItemList( )
                extraData.leftCoinNum  = self:getTableCoinsNum() -- 桌子遗留金币总数
                extraData.dropCoinNum  = pushersData.dropCoinNum or 0 -- 无效区域金币总数
            end
        end
        
    end

    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , coins = sendData,extra = extraData }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

end

function GamePusherManager:setAllEntityNodeKinematic( _bool ,_toDo )

    local pushersData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if not _toDo and (pushersData and table_length(pushersData) > 0)  then
        print("---- 推币机进行时不处理")
        local childs = self.m_pusherMain.m_tEntityList -- 所有的金币3dSpr
        for k,v in pairs(childs) do
            local node = v.Node
            if node then
                local rigidBody = node:getPhysicsObj()
                if rigidBody then
                    if _bool then
                        rigidBody:setRestitution(Config.CoinsRestitutionInit ) 
                    else
                        rigidBody:setRestitution(Config.CoinsRestitution )
                    end

                end
            end
            
        end 
    else
        performWithDelay(self.m_pusherMain,function(  )
            local childs = self.m_pusherMain.m_tEntityList -- 所有的金币3dSpr
            for k,v in pairs(childs) do
                local node = v.Node
                if node then
                    local rigidBody = node:getPhysicsObj()
                    if rigidBody then

                        rigidBody:setKinematic(_bool) 
                        if _bool then
                            rigidBody:setRestitution(Config.CoinsRestitutionInit ) 
                        else
                            rigidBody:setRestitution(Config.CoinsRestitution )
                        end

                    end
                end
                
            end 
        end,0)
        
    end
   
    

end
--[[
    main ui 更新    
--]]

function GamePusherManager:getMainUiNode( )
    return self.m_pusherMain.m_pMainUI
    
end


--更新剩余点击次数
function GamePusherManager:updataLeftCoinsTimes(_ntimes )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateLeftFreeCoinsTimes, {ntimes = _ntimes})
end


-- 作为更新本netInitData的地方
function GamePusherManager:updateNetInitData(_data )
    
    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    -- 更新需要的信息
    if _data.bet then
        netInitData.bet = _data.bet
    end
    
    if _data.coinCoe then
        netInitData.coinCoe = _data.coinCoe
    end

    if _data.jpTriggerd then -- 本地存储的本轮推币机玩法是否中过jp
        netInitData.jpTriggerd = _data.jpTriggerd
    end

    if _data.jpPlayed then -- 中了jackpot并且播完了动画，断线重连显示jackpot用
        netInitData.jpPlayed = _data.jpPlayed
    end

    if _data.jpWinCoins then -- 本地存储的本轮推币机玩法中jack的钱
        netInitData.jpWinCoins = _data.jpWinCoins
    end

    self:updatePlayingData( playingData )
end



-- 本地推币机需要处理的数据变量，会直接存储到本地
function GamePusherManager:setPusherUseData(_data )
    self.m_playingData = _data or {}
end

function GamePusherManager:getPusherUseData( )
    return self.m_playingData or {}
end

-- 存储本地playingData 
function GamePusherManager:updatePlayingData( _data )
    
    local playingData = self:getPusherUseData( ) or {}

    if _data.netInitData then
        playingData.netInitData = _data.netInitData -- 更新最新的服务器返回数据
    end

    if _data.pusherMaxUseNum then
        playingData.pusherMaxUseNum = _data.pusherMaxUseNum -- 赠送的金币的可使用的最大次数
    end


    if _data.wallMaxUseTimes then
        playingData.wallMaxUseTimes = _data.wallMaxUseTimes -- 墙道具可使用的倒计时
    end

    if _data.wallMaxUseNum then
        playingData.wallMaxUseNum = _data.wallMaxUseNum
    end
    if _data.collectCurrNum then
        playingData.collectCurrNum = _data.collectCurrNum -- 当前收集的金币的个数
    end

    if _data.collectItemsNum then
        playingData.collectItemsNum = _data.collectItemsNum -- 本次Bonus中奖的统计
    end



    if _data.dropCoinNum then
        playingData.dropCoinNum = _data.dropCoinNum -- 掉落的无效金币个数
    end

    if _data.isShoInitSlotReel then
        playingData.isShoInitSlotReel = _data.isShoInitSlotReel -- 是否显示初始3个grand的老虎机棋盘
    end

    if _data.diskEntityDataJackpotHave then
        playingData.diskEntityDataJackpotHave = _data.diskEntityDataJackpotHave -- 本次Bonus是否已经创建过jackpot金币
    end

    --通知同步脏数据
    gLobalNoticManager:postNotification(Config.Event.GamePusher_Sync_Dirty_Data)

end


--[[
    获得掉落金币的类型
--]]
function GamePusherManager:getSpinEntityDataForCalculation(_weight , _coinsCount)
    
    -- "slots金币概率 = 数组第一位 / 数组第二位   0.05"

    local slotCoinWeight = _weight or {5,100}

    local coinsTypeList = {}
    for i=1,_coinsCount do
        local coinsType = Config.CoinModelRefer.NORMAL
        local rodIndex = math.random(1,slotCoinWeight[1] + slotCoinWeight[2])
        if rodIndex <= slotCoinWeight[1] then
            coinsType = Config.CoinModelRefer.SLOTS
        end
        table.insert(coinsTypeList,coinsType) 
    end

    -- 组装数据
    local DropCoinsList = {}
    for i=1,#coinsTypeList do
        if DropCoinsList[coinsTypeList[i]] then
            DropCoinsList[coinsTypeList[i]] = DropCoinsList[coinsTypeList[i]] + 1
        else
            DropCoinsList[coinsTypeList[i]] = 1
        end
        
    end

    return DropCoinsList
end



-- 判断是否所有免费金币使用完毕
function GamePusherManager:checkPusherDropTimesUseUp( )
    --load游戏数据
   local pushersData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
   if pushersData and table_length(pushersData) ~= 0 then

       -- ** 更新剩余可使用免费金币UI显示
       local pusherMaxUseNum = pushersData.pusherMaxUseNum  or 0 -- 赠送的金币的可使用的最大次数
       if pusherMaxUseNum > 0 then
           return false
       end

   end

   return true
end


-- 判断是否所有动画播完
function GamePusherManager:checkPlayEffectOver()

    for i=1,#self.m_tPlayList do
        local data = self.m_tPlayList[i]
        if data:getActionState() ~= Config.PlayState.DONE  then
            return false
        end
    end
        
    return true
end

-- 判断是否所有道具都使用完毕
function GamePusherManager:checkPusherPropUseUp( )
    
    --load游戏数据
    local pushersData = self:getPusherUseData() --字段名称不要轻易修改会影响本地数据存储逻辑
    if pushersData and table_length(pushersData) ~= 0 then

        -- ** 更新剩余可使用免费金币UI显示
        local pusherMaxUseNum = pushersData.pusherMaxUseNum or 0  -- 赠送的金币的可使用的最大次数
        if pusherMaxUseNum > 0 then
            return false
        end

    end

    
    return true
end



function GamePusherManager:clearAllEntityCoins( )

    self.m_pusherMain.m_sp3DEntityRoot:removeAllChildren()
    self.m_pusherMain.m_nEntityIndex = Config.EntityIndex
    self.m_pusherMain.m_tEntityList = {}
    
end

function GamePusherManager:createEntityFromDisk( )
    
    self.m_tEntityData = self:getDiskEntityData(self:getDiskEntityDataID())  -- 金币信息读取本地配置

    -- 初始化金币和道具 --
    if self.m_tEntityData.Entity then
        for k,v in pairs( self.m_tEntityData.Entity ) do
            local sType = v.Type
            local nID   = v.ID
            local vPos  = v.Pos
            local vRot  = v.Rot
            local bCollision  = v.Collision
            
            if sType == Config.EntityType.COIN then
                -- 创建金币或道具 必须在同一帧创建出来 --
                self.m_pusherMain:createCoins( nID , vPos , vRot , bCollision)
            end
            
        end
    else
        -- 不会出现这种情况 金币数据应该是一直存在的
        assert( false , "loadSceneEntityData  不应该随机创建 ")
        self:randomInitDisk()
    end

    self:setAllEntityNodeKinematic( true,true  ) -- 初始化金币时不碰撞检测
    self:saveEntityData() --初始化推币机需要存储数据

end

function GamePusherManager:setSlotMainRootScale( _scale)
    self.m_machineRootScale = _scale
end

function GamePusherManager:getSlotMainRootScale( )
   return self.m_machineRootScale or 1 
end

function GamePusherManager:restSendDt( )
    self.m_pusherMain:restSendDt()
end

function GamePusherManager:setPusherSpeed( _speed )
    self.m_pusherMain.m_nPusherSpeed  = _speed
end

function GamePusherManager:getPusherAvergeBet( )
    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local bet = netInitData.bet or 0.1
    return bet
end
-- 获得算钱的totalBet
function GamePusherManager:getPusherTotalBet( )
    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local coinCoe = netInitData.coinCoe or 0.1
    local bet = netInitData.bet or 0.1
    return coinCoe * bet
end

function GamePusherManager:checkJackPotSymbolType(_type )
    if _type == Config.slotsSymbolType.Jackpot or
        _type == Config.slotsSymbolType.Grand or
        _type == Config.slotsSymbolType.Major or
        _type == Config.slotsSymbolType.Minor or
        _type == Config.slotsSymbolType.Mini then
        return true
    end
     
    return false
end

function GamePusherManager:getInitItemList( )
    local data = {}
    data[tostring(Config.slotsSymbolType.Wall)] = 0
    data[tostring(Config.slotsSymbolType.Shake)] = 0
    data[tostring(Config.slotsSymbolType.BigCoin)] = 0
    data[tostring(Config.slotsSymbolType.CoinTower)] = 0
    data[tostring(Config.slotsSymbolType.CoinRain)] = 0
    data[tostring(Config.slotsSymbolType.CoinPile)] = 0
    data[tostring(Config.slotsSymbolType.Grand)] = 0
    data[tostring(Config.slotsSymbolType.Major)] = 0
    data[tostring(Config.slotsSymbolType.Minor)] = 0
    data[tostring(Config.slotsSymbolType.Mini)] = 0

    return data
end

function GamePusherManager:getTableCoinsNum( )
    local coinsNum = 0

    local childs = self.m_pusherMain.m_tEntityList -- 所有的金币3dSpr
    for k,v in pairs(childs) do
        local entityData = v
        if entityData then
           local coinsType = entityData.ID 
           local addNum = Config.CollectCoinsProgress[coinsType]
           coinsNum = coinsNum + addNum
        end
        
    end 

    return coinsNum
end

function GamePusherManager:getRainDropCoinsType( )
    local coinSymbolType = Config.CoinModelRefer.NORMAL

    --load游戏数据
    local pushersData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if pushersData and table_length(pushersData) ~= 0 then
        local slotCoinRainWeight = pushersData.slotCoinRainWeight or {1,300}
        local coinsType = nil
        local totalWeight = 0
        local typeList = {}
        local typeName = {Config.CoinModelRefer.SLOTS,Config.CoinModelRefer.NORMAL}
        for i=1,#slotCoinRainWeight do
            totalWeight = slotCoinRainWeight[i] + totalWeight
            if i == 1 then
                table.insert(typeList,{slotType = typeName[1],indexWeight = totalWeight}) 
            else
                table.insert(typeList,{slotType = typeName[2],indexWeight = totalWeight}) 
            end
        end

        local rodIndex = math.random(1,totalWeight)
        for i=1,#typeList do
            local indexWeight = typeList[i].indexWeight
            coinsType = tostring(typeList[i].slotType)
            if rodIndex <= indexWeight  then
                coinSymbolType = coinsType
                break
            end
        end
    end

    return coinSymbolType
end




return GamePusherManager
