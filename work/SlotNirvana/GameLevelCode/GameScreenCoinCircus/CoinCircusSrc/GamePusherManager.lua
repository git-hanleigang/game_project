local GamePusherManager = class("GamePusherManager",util_require("baseActivity.BaseActivityManager"))
local Config            = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")

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
        
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_QuickClosePropTip)
        
        -- 存储本地playingData pusherMaxUseNum
        local data = {}
        data.pusherMaxUseNum = pusherMaxUseNum  - 1
       
        local tDropData = self:getSpinEntityDataForCalculation( 1 ) 

        local tActionData = {tDropData, {entityPos = _vTouchPos}}
        self:updatePlayList("Drop" ,tActionData)   -- 加入动画列表

        self:updatePlayingData( data )
        -- 存储到本地
        -- self:saveRunningData()

        self:updataLeftCoinsTimes(data.pusherMaxUseNum )
    end
    
end

function GamePusherManager:dropFromTable(_sType)
    -- 进度++  轮盘个数++  save

    local playingData = self:getPusherUseData( ) or {}
    local collectCurrNum = playingData.collectCurrNum
    local jpCollectCurrNum = playingData.jpCollectCurrNum
    if collectCurrNum == nil then
        release_print(" collectCurrNum == nil ---playingData 数据 --"..json.encode(playingData))
    end

    -- 存储本地playingData pusherMaxUseNum
    local data = {}
    if _sType == Config.CoinModelRefer.NORMAL then -- "NORMAL"
        data.collectCurrNum = collectCurrNum  + Config.CollectCoinsProgress.NORMAL  -- 当前收集的金币的个数
        self:upDataEnergyProgress( data.collectCurrNum )
    elseif _sType == Config.CoinModelRefer.JACKPOT then -- "JACKPOT"
        data.jpCollectCurrNum = jpCollectCurrNum  + 1 -- 当前收集的jackpot金币的个数 
        self:upDataPropJPCollectTimes(data.jpCollectCurrNum )
    elseif _sType == Config.CoinModelRefer.RANDOM then -- "RANDOM"
        print("随机掉落金币")
    elseif _sType == Config.CoinModelRefer.BIG then  -- "BIG"
        data.collectCurrNum = collectCurrNum  + Config.CollectCoinsProgress.BIG  -- 当前收集的金币的个数
        self:upDataEnergyProgress( data.collectCurrNum )
    end


    local tActionData = {}
    self:updatePlayList("PushOut",_sType, tActionData) 


    self:updatePlayingData( data )
    -- 存储到本地
    -- self:saveRunningData()

   
end

----------------------------------------------------------------------------------------
-- 数据初始化
----------------------------------------------------------------------------------------
--初始化游戏配置
function GamePusherManager:initGamePusher()
    
    self:initSaveKey( )
    self:loadGamePusherData()
end

function GamePusherManager:initSaveKey( )
    self.m_sEntitySaveKey = "GamePusherEntity" .. tostring(self:getBonusID())                --实体存档key
    self.m_sDataSaveKey   = "GamePusherData" .. tostring(self:getBonusID())                  --游戏数据存档key
end

-- function GamePusherManager:loadGamePusherData()

--     self.m_tPlayList    = {}

--     local tloadEntityData = self:loadEntityData()

--     if not tloadEntityData or table_length(tloadEntityData) == 0  then
        
--         self.m_tEntityData = self:getDiskEntityData()   -- 金币信息读取配置
--     else
--         self.m_tEntityData = self:loadEntityData()  -- 金币信息读取本地存储
--     end
--     -- self:saveRunningData() -- 一创建推币机时不需要存储数据
-- end

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
        self.m_tEntityData = self:getDiskEntityData()
    end
    self.m_tPlayList = {}
end

----------------------------------------------------------------------------------------
-- 存档和数据加载
----------------------------------------------------------------------------------------
--存储实体数据
function GamePusherManager:saveEntityData(_EntityInfo, _isFlush)
    local attJson = cjson.encode(_EntityInfo)

    gLobalDataManager:setStringByField(self.m_sEntitySaveKey, attJson, _isFlush)
end

--存储游戏数据
function GamePusherManager:saveRunningData(_isFlush)
    --退出时,有可能界面没加载完导致数据没有初始化,所以要做数据安全判定
    if not self.m_tPlayList then
        return
    end

    local tSaveRunningData = {}

    -- 本地存储的推币机需要使用的数据
    tSaveRunningData.playingData = self:getPusherUseData() --字段名称不要轻易修改会影响本地数据存储逻辑
    local PlayList = {}

    for i = 1, #self.m_tPlayList do
        local aniData = self.m_tPlayList[i]
        local aniRunningData = aniData.m_tRunningData
        table.insert(PlayList, aniRunningData)
    end
    tSaveRunningData.PlayList = PlayList

    local attJson = cjson.encode(tSaveRunningData)

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
function GamePusherManager:getDiskEntityData()

    local sConfigPath = Config.ConfigPath
    if not cc.FileUtils:getInstance():isFileExist(sConfigPath) then
        assert(false, "没有盘面配置数据")
    end 
    local jsonDatas = cc.FileUtils:getInstance():getStringFromFile(sConfigPath)
    --[[
        1、金字塔
        2、螺旋
        3、五个柱子每个10层高
        4、6个柱子，1-12，2-15，3-10，4-6，5-8，6-3
        5、5个柱子，1-10，2-15，3-12，4-8.5-5    
    --]]

    if jsonDatas and jsonDatas ~= "" then

        local decodeJsonDatas = cjson.decode(jsonDatas)
        local diskDatas = self:changeEntityDataForCalculation( decodeJsonDatas[ tostring(self:getDiskEntityDataID()) ]  ) 
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

-- 本地推币机初始化台面金币变随机金币概率
function GamePusherManager:getDiskEntityDataCoinOdd()  
    
    local rodNum = self.m_nDiskEntityDataCoinOdd[1]
    local rodPool = self.m_nDiskEntityDataCoinOdd[2]

    return rodNum,rodPool
end

function GamePusherManager:setDiskEntityDataCoinOdd(_OddList )                                   
    self.m_nDiskEntityDataCoinOdd = _OddList 
end

-- 本地推币机初始化台面金币里是否有jackpot金币
function GamePusherManager:getDiskEntityDataJackpotHave()   
    
    if self.m_diskEntityDataJackpotHave then
        if self.m_diskEntityDataJackpotHave == 0 then

            local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
        
            if PuserPropData and table_length(PuserPropData) ~= 0 then
                    -- ** 更新收集的金币进度ui显示 
                    local diskEntityDataJackpotHave = PuserPropData.diskEntityDataJackpotHave   -- 本次Bonus是否已经创建过jackpot金币
                    if diskEntityDataJackpotHave and tonumber(diskEntityDataJackpotHave) == 1 then
                        return true
                    else
                        return false
                    end

            end

            return false

        end
    end
    
    return true
end
  
function GamePusherManager:setDiskEntityDataJackpotHave(_haveId)                                   
    self.m_diskEntityDataJackpotHave = _haveId
    
end


--更新动画列表 _playData玩法数据  _coinData游戏数据
function GamePusherManager:updatePlayList(_sType , _actionData)          
    if _sType == "PushOut" then      
        local playData = self:createPlayData(_actionData, {})
        self.m_tPlayList[table_nums(self.m_tPlayList) + 1] = playData
    elseif _sType == "Drop" then 
        if _actionData then    
            local playData = self:createPlayData("DROP", _actionData)
            self.m_tPlayList[table_nums(self.m_tPlayList) + 1] = playData
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
end
    
---创建动画数据
function GamePusherManager:createPlayData(_sType, _data)
    local actionData = self:createActionData(_sType)
    --获取最新的数据
    actionData:setActionType(_sType)   -- 类型 
    actionData:setActionData(_data)   -- 数据
    -- actionData:updateUserData()      -- 更新用户数据
    return actionData               
end

--各种动画数据
function GamePusherManager:createActionData(type)
    local actionData = nil
    if  type == Config.CoinEffectRefer.NORMAL  or 
    type == Config.CoinEffectRefer.BIG then          
        actionData = util_createView(Config.ActionDataPathConfig.BaseActionData)
    elseif type == Config.CoinEffectRefer.DROP then
        actionData = util_createView(Config.ActionDataPathConfig.DropCoinData)
    elseif type == Config.CoinEffectRefer.JACKPOT  then
        actionData = util_createView(Config.ActionDataPathConfig.PopCoinViewData)
    elseif type == Config.CoinEffectRefer.RANDOM  then
        actionData = util_createView(Config.ActionDataPathConfig.RandomData)
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
    self.m_pMain = util_createView(Config.ViewPathConfig.Main, true)
    self.m_pMain.m_machine = self.m_machine
    
    self:initGamePusher()
    return self.m_pMain

    
end


function GamePusherManager:getFrontEffectNode( )
    return self.m_pMain.m_pEffectRoot._frontEffect
end

function GamePusherManager:pubStopPusherAllAnim( )
    self.m_pMain:stopPusherAllAnim()
end

function GamePusherManager:pubStartPusherAllAnim( )
    self.m_pMain:startPushing()
end

-- bonusEffect触发推币机玩法开始
function GamePusherManager:pubBeginPlayPuhsher( )

    self:upDataPropSpecTouchEnabled( true ) -- 设置道具可点击状态
    self:pubStartPusherAllAnim( )

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
    
    self:upDataPropSpecTouchEnabled( false )        -- 设置道具可点击状态
    self:pubStopPusherAllAnim( )                -- 停止推币机动作
    self:setAllEntityNodeKinematic( true ,true )    -- 设置所有金币关闭碰撞检测

    local _progress = 0
    local _jpNum = 0

     --load游戏数据
     local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
     if PuserPropData and table_length(PuserPropData) ~= 0 then

        -- ** 更新收集的金币进度ui显示 
        local collectCurrNum = PuserPropData.collectCurrNum or 0  -- 当前收集的金币的个数
        -- ** 更新收集的jp金币进度ui显示 
        local jpCollectCurrNum = PuserPropData.jpCollectCurrNum or 0  -- 当前收集的jackpot金币的个数

        _progress = collectCurrNum
        _jpNum = jpCollectCurrNum

     end

     
    self:requestBonusPusherNetData( _progress,_jpNum )

end
-- 请求bonus消息
function GamePusherManager:requestBonusPusherNetData( _progress,_jpNum )
    
    local sendData = nil
    if _progress and _jpNum then
        -- 最后结束的时候需要向服务器发送进度个数和中圆盘玩法的jp个数
        sendData = {_progress,_jpNum}
    end

    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , coins = sendData }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

end

-- 请求购买道具 select ： 0：震动 ，1墙， 2大金币 3 再来一轮
function GamePusherManager:requestBonusBuyProp(_select )

    self:pubStopPusherAllAnim()
    gLobalViewManager:addLoadingAnima()

    local sendData = {}
    sendData.pageCellIndex = _select

    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = sendData}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

end

function GamePusherManager:setAllEntityNodeKinematic( _bool ,_toDo )

    local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if not _toDo and (PuserPropData and table_length(PuserPropData) > 0)  then
        print("---- 推币机进行时不处理")
        local childs = self.m_pMain.m_tEntityList -- 所有的金币3dSpr
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
        performWithDelay(self.m_pMain,function(  )
            local childs = self.m_pMain.m_tEntityList -- 所有的金币3dSpr
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
    return self.m_pMain.m_pMainUI
    
end

-- 更新进度条
function GamePusherManager:upDataEnergyProgress(_nCount,_nInit )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateProgressCount, {nCount = _nCount,nInit = _nInit})
end
--更新剩余点击次数
function GamePusherManager:updataLeftCoinsTimes(_ntimes )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateLeftFreeCoinsTimes, {ntimes = _ntimes})
end

-- 更新大金币道具剩余次数
function GamePusherManager:upDataPropBigCoinsTimes(_ntimes )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateProp_BigCoins, {ntimes = _ntimes})
end
-- 初始化更新新墙道具个数
function GamePusherManager:upDataPropWallTimes(_ntimes )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateProp_Wall, {ntimes = _ntimes})


end
-- 更新震动道具剩余次数
function GamePusherManager:upDataPropShakeTimes(_ntimes )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateProp_Shake, {ntimes = _ntimes})
end

-- 更新道具特殊逻辑是否能点击
function GamePusherManager:upDataPropSpecTouchEnabled(_nEnabled )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PropSpecTouchEnabled, {TouchEnabled = _nEnabled})
end
-- 更新道具是否能点击
function GamePusherManager:upDataPropTouchEnabled(_nEnabled )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PropTouchEnabled, {TouchEnabled = _nEnabled})
end

-- 更新jackpot收集个数
function GamePusherManager:upDataPropJPCollectTimes(_ntimes,_nisInit )
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateJPCollect, {ntimes = _ntimes,nisInit = _nisInit})
end

-- 获取第二币值的钱数 
function GamePusherManager:getGemsData( )
    
    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local gems  = netInitData.gems or {} -- 道具需要的钱数
    return gems
end

-- 获取道具是否免费 
function GamePusherManager:getFreeItemsData( )
    
    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local freeItems  = netInitData.freeItems or {} -- 道具免费的信息
    return freeItems
end

-- 作为更新本地存储selfdata的地方
function GamePusherManager:updateNetInitData(_selfdata )
    
    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    -- 更新需要的信息
    local freeItems = _selfdata.freeItems or {}

    netInitData.freeItems = freeItems
    

    self:updatePlayingData( playingData )
end

-- 获得当前收集进度挡位
function GamePusherManager:getCurrEnergyProgressBoxLevel( _collectCurrNum )

    local level = self.m_pMain.m_pMainUI:getBoxIndex(_collectCurrNum)
    return level

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

    if _data.bigCoinMaxUseNum then
        playingData.bigCoinMaxUseNum = _data.bigCoinMaxUseNum --大金币掉落道具可使用的最大次数
    end

    if _data.wallMaxUseNum then
        playingData.wallMaxUseNum = _data.wallMaxUseNum
    end

    if _data.shakeMaxUseNum then
        playingData.shakeMaxUseNum = _data.shakeMaxUseNum -- 震动道具可使用的最大次数
    end

    if _data.collectCurrNum then
        playingData.collectCurrNum = _data.collectCurrNum -- 当前收集的金币的个数
    end

    if _data.jpCollectCurrNum then
        playingData.jpCollectCurrNum = _data.jpCollectCurrNum -- 当前收集的jackpot金币的个数
    end
    
    if _data.diskEntityDataJackpotHave then
        playingData.diskEntityDataJackpotHave = _data.diskEntityDataJackpotHave -- 本次Bonus是否已经创建过jackpot金币
    end

    --通知同步脏数据
    gLobalNoticManager:postNotification(Config.Event.GamePusher_Sync_Dirty_Data)
end

-- 一进入关卡读本地配置初始化金币数据时出特殊金币的算法
--[[
    初始的所有金币中，有50%的概率随机一个变为jackpot转盘金币
    其余的金币每个4%的概率为额外金币的金币    
--]]
function GamePusherManager:changeEntityDataForCalculation(_entityDatas )


    local entityDatas = clone(_entityDatas)
    local changeEntityDatas = {}

    local isAddJp = self:getDiskEntityDataJackpotHave( )

    if isAddJp then

        local randomPos = {}
        for index=1,#entityDatas do
            local entityData = entityDatas[index]
            if entityData.ID == Config.CoinModelRefer.RANDOM  then
                table.insert(randomPos,index)
            end
        end
       
        local jpPos = math.random(1,#randomPos)
        local entityData = entityDatas[randomPos[jpPos]]
        entityData.ID = Config.CoinModelRefer.JACKPOT
        table.insert(changeEntityDatas,entityData)
        table.remove(entityDatas,randomPos[jpPos])  

    end
    

    for i=1,#entityDatas do
        local entityData = entityDatas[i]
        
        -- local rodNum,rodPool = self:getDiskEntityDataCoinOdd()

        -- local rod = math.random(1,rodPool)
        -- if rod <= rodNum then
        --     if entityData.ID == Config.CoinModelRefer.RANDOM  then

        --     else
        --         entityData.ID = Config.CoinModelRefer.NORMAL 
        --     end
        -- else
        --     if entityData.ID == Config.CoinModelRefer.RANDOM  then
        --         entityData.ID = Config.CoinModelRefer.NORMAL 
        --     end
        -- end
        table.insert(changeEntityDatas,entityData)
    end

    local jpNum = 0
    for index=1,#changeEntityDatas do
        local entityData = changeEntityDatas[index]
        if entityData.ID == Config.CoinModelRefer.JACKPOT  then
            jpNum = jpNum + 1
            if jpNum>= 2 then
                entityData.ID = Config.CoinModelRefer.NORMAL 
            end
            
        end
    end

    return changeEntityDatas
end

function GamePusherManager:getSpinRandomCoinsCountForCalculation( )

    local count = math.random(3,5)

    return count

end
-- 获取随机掉落金币的数据
function GamePusherManager:getRandomEffectData( )
    
    local addCount = self:getSpinRandomCoinsCountForCalculation( )

    local DropCoinsList = self:getSpinEntityDataForCalculation( addCount)

    local tDropCoins = {}
    for k,v in pairs(DropCoinsList) do
        local dropType = k
        if tDropCoins[dropType] then
            tDropCoins[dropType] = tDropCoins[dropType] + 1
        else
            tDropCoins[dropType] = v
        end
    end

    return tDropCoins
end

--[[
    玩家点击掉落和额外掉落的金币中，如果初始金币没有jackpot转盘，每个金币有10%的概率为jackpot转盘的金币，如果已经出现了一个jackpot转盘金币，概率重置为0。
    点击掉落和额外掉落的金币如果不为jackpot金币，每个金币有10%的概率变为额外金币的金币    
--]]
function GamePusherManager:getSpinEntityDataForCalculation( _coinsCount)
    
    local coinsTypeList = {}

    local playingData = self:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}

    local jackpotCoinOdd = netInitData.jackpotCoinOdd -- 随机一个初始金币为jackpot金币
    local randomCoinOdd = netInitData.randomCoinOdd -- 每个金币都有概率变为随机金币

    for i=1,_coinsCount do

        local isHaveJp = self:getDiskEntityDataJackpotHave( ) -- 是否已经有jackpot

        if isHaveJp then

            local rod_2 = math.random(1,randomCoinOdd[2])
            if rod_2 <= randomCoinOdd[1] then
                table.insert(coinsTypeList,Config.CoinModelRefer.RANDOM) -- "RANDOM"

            else
                table.insert(coinsTypeList,Config.CoinModelRefer.NORMAL) -- "NORMAL"
            end

        else
    
            local rod = math.random(1,jackpotCoinOdd[2])
            if rod <= jackpotCoinOdd[1] then

                table.insert(coinsTypeList,Config.CoinModelRefer.JACKPOT) -- "JACKPOT"

                local data = {}
                data.diskEntityDataJackpotHave = 1
                -- 标记本地数据已经创建过 "JACKPOT" 金币
                self:updatePlayingData( data )
                -- 存储到本地
                -- self:saveRunningData()

            else

                local rod_1 = math.random(1,randomCoinOdd[2])
                if rod_1 <= randomCoinOdd[1] then
                    table.insert(coinsTypeList,Config.CoinModelRefer.RANDOM) -- "RANDOM"

                else
                    table.insert(coinsTypeList,Config.CoinModelRefer.NORMAL) -- "NORMAL"
                end

            end
            
        end

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

--[[
    播放道具     
--]]
-- 道具 震动
function GamePusherManager:playShakeProp(  )
    local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    local shakeMaxUseNum = PuserPropData.shakeMaxUseNum or 1
    if shakeMaxUseNum > 0 then
        
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_hammerHit.mp3")  

        -- 存储本地playingData 
        local data = {}
        data.shakeMaxUseNum = shakeMaxUseNum  - 1
        self:updatePlayingData( data )
        -- 存储到本地
        -- self:saveRunningData()

        local hammerFunction = function (  )
            self.m_pMain:itemsQuake( 30 )
            self.m_pMain:CameraQuake()
        end
        self.m_pMain:PlayEffect( Config.Effect.Hammer.ID , hammerFunction )

        self:upDataPropShakeTimes( data.shakeMaxUseNum )
    end


end

-- 道具 大金币
function GamePusherManager:playBigCoinsProp(_func )

    local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    local bigCoinMaxUseNum = PuserPropData.bigCoinMaxUseNum or 1
    if bigCoinMaxUseNum > 0 then
        
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_BigCoinsDrop.mp3")  

        -- 存储本地playingData 
        local data = {}
        data.bigCoinMaxUseNum = bigCoinMaxUseNum  - 1
        self:updatePlayingData( data )
        -- 存储到本地
        -- self:saveRunningData()

        local bigCoinsFunction = function (  )
            if _func then
                _func()
            end
        end

        self.m_pMain:dropBigCoins(1,bigCoinsFunction)
        
        self:upDataPropBigCoinsTimes( data.bigCoinMaxUseNum )

    else
        if _func then
            _func()
        end
    end


    
    
    
end

-- 道具 墙
function GamePusherManager:updateWallUpTimes(_func,wallTime )
    local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    local wallMaxUseNum = PuserPropData.wallMaxUseNum or 1
    local data = {}
    data.wallMaxUseNum = wallMaxUseNum  - 1
    self:updatePlayingData( data )
    -- 存储到本地
    -- self:saveRunningData()
    self:upDataPropWallTimes( data.wallMaxUseNum )
    
    Config.PropWallMaxCount = wallTime

    local time = wallTime
    self:setPusherUpWalls( time,true )

    if _func then
        _func()
    end

 
end


-- 判断是否所有免费金币使用完毕
function GamePusherManager:checkPusherDropTimesUseUp( )
    --load游戏数据
   local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
   if PuserPropData and table_length(PuserPropData) ~= 0 then

       -- ** 更新剩余可使用免费金币UI显示
       local pusherMaxUseNum = PuserPropData.pusherMaxUseNum  or 0 -- 赠送的金币的可使用的最大次数
       if pusherMaxUseNum > 0 then
           return false
       end

   end

   return true
end

-- 判断是否所有道具都使用完毕
function GamePusherManager:checkPusherPropUseUp( )
    
    --load游戏数据
    local PuserPropData = self:getPusherUseData() --字段名称不要轻易修改会影响本地数据存储逻辑
    if PuserPropData and table_length(PuserPropData) ~= 0 then

        -- ** 更新剩余可使用免费金币UI显示
        local pusherMaxUseNum = PuserPropData.pusherMaxUseNum or 0  -- 赠送的金币的可使用的最大次数
        if pusherMaxUseNum > 0 then
            return false
        end

        -- ** 更新大金币道具ui显示 
        local bigCoinMaxUseNum = PuserPropData.bigCoinMaxUseNum or 0  --大金币掉落道具可使用的最大次数
        if bigCoinMaxUseNum > 0 then
            return false
        end

        -- ** 更新震动道具道具ui显示 
        local shakeMaxUseNum = PuserPropData.shakeMaxUseNum or 0  -- 震动道具可使用的最大次数
        if shakeMaxUseNum > 0 then
            return false
        end

    end

    
    return true
end

function GamePusherManager:getPropNum(_type)
    local PuserPropData = self:getPusherUseData() --字段名称不要轻易修改会影响本地数据存储逻辑
    local propNum = 0
    if PuserPropData and table_length(PuserPropData) ~= 0 then
        propNum = PuserPropData[_type] or 0
    end
    return propNum
end

function GamePusherManager:clearAllEntityCoins( )

    self.m_pMain.m_sp3DEntityRoot:removeAllChildren()
    self.m_pMain.m_nEntityIndex = 0
    self.m_pMain.m_tEntityList = {}
    
end

function GamePusherManager:createEntityFromDisk( )
    
    self.m_tEntityData = self:getDiskEntityData()  -- 金币信息读取本地配置

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
                self.m_pMain:createCoins( nID , vPos , vRot , bCollision)
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
    self.m_pMain:restSendDt()
end

function GamePusherManager:setPusherSpeed( _isbase )
    if _isbase then
        self.m_pMain.m_nPusherSpeed    = Config.PusherSpeed
    else
        self.m_pMain.m_nPusherSpeed    = Config.BonusPusherSpeed
    end
end



return GamePusherManager
