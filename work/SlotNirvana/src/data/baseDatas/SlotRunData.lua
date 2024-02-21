--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 20:42:06
--

local MachineData = require "data.baseDatas.MachineData"
-- local RecommendBetData = require "data.baseDatas.RecommendBetData"
local SlotRunData = class("SlotRunData")

SlotRunData.iLastBetIdx = nil -- 最后设置的 bet 索引  LAST_BET_IDX
SlotRunData.m_chooseIndexs = nil -- 打点用的标记
SlotRunData.m_chooseBets = nil -- 打点用的标记

SlotRunData.runCsvData = nil -- 运行时关卡数据 RUN_CSV_DATA
SlotRunData.gameModuleName = nil -- 这是代表进入的关卡名字
SlotRunData.gameMachineConfigName = nil -- 这是代表进入时读取的config的名字
SlotRunData.gameNetWorkModuleName = nil -- 发送服务器消息时关卡名字
SlotRunData.machineData = nil -- 点击level 后进入关卡的数据
SlotRunData.createTime = nil -- 用户创建时间

SlotRunData.totalFreeSpinCount = nil -- 当前freesin 总次数  TOTAL_FREESPIN_COUNT
SlotRunData.freeSpinCount = nil -- 当前剩余freespin 次数    FREE_SPIN_COUNT
SlotRunData.currSpinMode = nil -- 当前spin mode           CURR_SPIN_MODE
SlotRunData.gameSpinStage = nil -- slots spin 状态         GAME_SPIN_STAGE
SlotRunData.gameRunPause = nil --   轮盘滚动暂停
SlotRunData.gameResumeFunc = nil --恢复时需要执行的方法
SlotRunData.lastWinCoin = nil -- 最后赢的钱
SlotRunData.iReSpinCount = nil -- RESPIN_SPIN_COUNT
SlotRunData.levelConfigData = nil
SlotRunData.levelGetAnimNodeCallFun = nil
SlotRunData.levelPushAnimNodeCallFun = nil
SlotRunData.currLevelEnter = nil --当前关卡模式  ---normal  quest
SlotRunData.lineCount = nil --关卡线数

SlotRunData.severGameJsonData = nil

SlotRunData.isPortrait = nil --是否竖屏
SlotRunData.isChangeScreenOrientation = nil --是否切换横竖屏
SlotRunData.isDeluexeClub = nil -- 是否高倍场

--- 关卡数据信息
SlotRunData.p_machineDatas = nil -- 关卡数据列表
SlotRunData.p_machineOriDatas = nil -- 关卡数据列表
SlotRunData.p_machineId_Idx = nil -- 关卡id-索引idx表
SlotRunData.p_machineName_Idx = nil -- 关卡名-索引表
SlotRunData.p_isLevelSort = nil

SlotRunData.gameEffStage = nil -- 状态
SlotRunData.spinNetState = nil -- spin网络状态
SlotRunData.m_spinDataValidCode = nil -- spin数据有效校验码

SlotRunData.isClickQucikStop = nil -- 是否点击了快停

SlotRunData.m_isAutoSpinAction = nil --autoSpin标识
SlotRunData.m_autoNum = nil --autospin数量

SlotRunData.m_isNewAutoSpin = true --新autospin开关

SlotRunData.m_lastEnterLevelInfo = nil --最后进入的关卡信息

SlotRunData.m_canPlayBigWinAdvertising = nil --关卡大赢后能否播放广告
SlotRunData.m_curBetMultiply        = 1     --当前bet值的倍率(处理一套bet列表内 相同betId 不同消耗 的逻辑)

SlotRunData.m_IsMasterStamp         = false --MinZbet值
SlotRunData.m_MasterStampBetCoins   = 0  --MinZbet值
SlotRunData.m_averageStates         = false -- 是否是平均bet状态

local SlotsLobbyEntryInfo = nil

function SlotRunData:ctor()
    self.currLevelEnter = nil

    self.totalFreeSpinCount = 0
    self.freeSpinCount = 0
    self.iReSpinCount = 0

    self.iLastBetIdx = 1

    self.severGameJsonData = nil

    self.isPortrait = nil
    self.p_isLevelSort = false

    self.m_chooseIndexs = {}
    -- 打点用的标记
    self.m_chooseBets = {} -- 打点用的标记

    self.m_autoNum = 0
    self.m_lastEnterLevelInfo = nil

    self.p_machineId_Idx = {}
    self.p_machineName_Idx = {}
    -- 大厅入口资源表
    self.m_slotsLobbyEntryInfos = {}

    self.p_machineDatas = {}
    self.m_normalMachineEntryDatas = {}
    self.m_highMachineEntryDatas = {}

    self.m_canPlayBigWinAdvertising = true
    self.m_averageStates         = false -- 是否是平均bet状态
end

--[[
    @desc:
    author:{author}
    time:2019-04-10 22:45:14
    @return:

    cxc 2020-12-04 17:28:31
    高倍场开启 所有关卡的都开
]]
function SlotRunData:parseLevelConfigs(levels, config)
    self.p_machineDatas = {}
    local machineOriDatas = {}
    self.m_normalMachineEntryDatas = {}
    self.m_highMachineEntryDatas = {}
    for i = 1, #levels do
        local levelData = levels[i]
        local machineData = MachineData:create()
        local higtMachineData = MachineData:create()
        if config then
            --解析新的levels表
            machineData:parseLevelConfigs(levelData, config)
            higtMachineData:parseLevelConfigs(levelData, config)
            higtMachineData:changeHighBet(higtMachineData.p_showOrder)
        end

        if globalData.GameConfig:checkLevelVisibleGroup(levelData.levelName) then
            self.p_machineDatas[#self.p_machineDatas + 1] = machineData
            self.p_machineDatas[#self.p_machineDatas + 1] = higtMachineData
            if not machineData.p_bHideLevel then
                -- 不放到入口数据里 cxc 2021-07-15 17:37:50
                self.m_normalMachineEntryDatas[#self.m_normalMachineEntryDatas + 1] = machineData
                self.m_highMachineEntryDatas[#self.m_highMachineEntryDatas + 1] = higtMachineData
            end
        end
    end
    self.p_machineOriDatas = self.p_machineDatas

    self:updateMachineId_IdxTable()
end

-- 添加 comingsoon data
function SlotRunData:addComminSoonData(_list)
    local listCount = #_list
    local commingSoonCount = 6 - (listCount % 6)
    for i = listCount, 1, -1 do
        local levelInfo = _list[i]
        if levelInfo.p_levelName == "CommingSoon" then
            for i = 1, commingSoonCount do
                local commingSoonInfo = clone(levelInfo)
                commingSoonInfo.p_commingSoonIndex = i
                table.insert(_list, commingSoonInfo)
            end
            break
        end
    end
end

-- 更新关卡id--索引 表
function SlotRunData:updateMachineId_IdxTable()
    self.p_machineId_Idx = {}

    for k, v in ipairs(self.p_machineDatas) do
        local _id = v.p_id
        self.p_machineId_Idx["" .. _id] = k
    end
end

-- 更新关卡名--索引 表
function SlotRunData:updateMachineName_IdxTable()
    self.p_machineName_Idx = {}

    for k, v in ipairs(self.p_machineDatas) do
        if v.p_name then
            local _name = self:translateLevelName("Level_" .. v.p_name)
            if self.p_machineName_Idx[_name] then
                assert(false, "machineName:" .. _name .. " have existed!!!")
            end
            self.p_machineName_Idx[_name] = k
        else
            if not v:isHightMachine() then
                printInfo("" .. v.p_levelName .. " machineName is nil!!!")
            end
        end
    end
end

--按照new hot关卡排序
function SlotRunData:sortMachineDatas()
    self:updateMachineId_IdxTable()
    self:updateMachineName_IdxTable()
end

-- 关卡排序
function SlotRunData:sortLevelDataList()
    table.sort(
        self.m_normalMachineEntryDatas,
        function(aData, bData)
            return aData.p_showOrder < bData.p_showOrder
        end
    )
    for i = 1, #self.m_normalMachineEntryDatas do
        local machineDataN = self.m_normalMachineEntryDatas[i]
        local strIdH = "2" .. string.sub(tostring(machineDataN.p_id), 2)
        local machineDataH = self:getLevelInfoById(strIdH)
        if machineDataH then
            machineDataH.p_showOrder = machineDataN.p_showOrder or 1
            machineDataH.p_openLevel = machineDataN.p_openLevel or 1
            machineDataH.p_Log = machineDataN.p_Log
        end
        -- 更新入口信息，普通和高倍场只需要处理一次
        self:updateLobbyEntryInfo(machineDataN.p_levelName)
    end
    table.sort(
        self.m_highMachineEntryDatas,
        function(aData, bData)
            return aData.p_showOrder < bData.p_showOrder
        end
    )
    self:addComminSoonData(self.m_normalMachineEntryDatas)
    self:addComminSoonData(self.m_highMachineEntryDatas)
end

-- 更新 登录前levels配置
function SlotRunData:updateGlobalConfigLevelInfo()
    if globalData.GameConfig and globalData.GameConfig.updateLevelInfo then
        globalData.GameConfig:updateLevelInfo()
    end
end

--[[
    @desc: 解析关卡基础数据信息
    time:2019-04-11 11:21:15
    --@machineBaseDatas:
    @return:
]]
function SlotRunData:parseMachineBaseData(machineBaseDatas, _bLogon)
    for i = 1, #machineBaseDatas do
        local baseData = machineBaseDatas[i]

        if baseData then
            local machineData = self:getLevelInfoById(baseData.gameId)
            if machineData then
                machineData:parseBaseData(baseData)
            end
        end
    end

    if _bLogon then
        self:sortLevelDataList()
        self:updateGlobalConfigLevelInfo()
    end
end

function SlotRunData:changeScreenOrientation(isPortrait)
    if self.isPortrait ~= isPortrait then
        self.changeFlag = true
        local function deviceChange()
            self.changeFlag = nil
            if isPortrait then
                xcyy.GameBridgeLua:changePortrait()
            else
                xcyy.GameBridgeLua:changeLandscape()
            end
        end

        if self.isPortrait ~= nil then
            -- if not globalPlatformManager:getScreenRotateAnimFlag() then
            local mastLayer = display.getRunningScene():getChildByName("rotateAnimMask")
            if not mastLayer then
                mastLayer = util_newMaskLayer()
                mastLayer:setName("rotateAnimMask")
                display.getRunningScene():addChild(mastLayer, ViewZorder.ZORDER_SPECIAL)
            end
        -- end
        end

        if isPortrait == true then
            self.isPortrait = isPortrait
            local view = cc.Director:getInstance():getOpenGLView()
            local framesize = view:getFrameSize()
            if framesize.height < framesize.width then
                view:setFrameSize(framesize.height, framesize.width)
            end
            CC_DESIGN_RESOLUTION.width = 768
            CC_DESIGN_RESOLUTION.height = 1370
            CC_DESIGN_RESOLUTION.autoscale = "FIXED_WIDTH"
            display = util_require("cocos.framework.display", true)
            DESIGN_SIZE = {width = 768, height = 1370}
        else
            self.isPortrait = false
            local view = cc.Director:getInstance():getOpenGLView()
            local framesize = view:getFrameSize()
            if framesize.height > framesize.width then
                view:setFrameSize(framesize.height, framesize.width)
            end
            CC_DESIGN_RESOLUTION.width = 1370
            CC_DESIGN_RESOLUTION.height = 768
            CC_DESIGN_RESOLUTION.autoscale = "FIXED_HEIGHT"
            display = util_require("cocos.framework.display", true)
            DESIGN_SIZE = {width = 1370, height = 768}
        end

        util_afterDrawCallBack(
            function()
                deviceChange()
                local scene = display.getRunningScene()
                if not scene then
                    return
                end
                local maskLayer = scene:getChildByName("rotateAnimMask")
                if maskLayer then
                    util_nodeFadeIn(
                        maskLayer,
                        0.3,
                        255 * 0.9,
                        0,
                        nil,
                        function()
                            if not tolua.isnull(maskLayer) then
                                maskLayer:removeFromParent()
                            end
                        end
                    )
                end
            end
        )
    end
end

--[[
    @desc: 检测当前的bet 是否是最大 bet
    time:2019-04-11 20:53:25
    @return:
]]
function SlotRunData:checkCurBetIsMaxbet()
    local machineCurBetList = self.machineData:getMachineCurBetList()

    if machineCurBetList == nil or #machineCurBetList == 0 then
        return true
    end

    local betData = machineCurBetList[#machineCurBetList]
    if betData.p_betId == self.iLastBetIdx then
        return true
    end
    return false
end
--[[
    @desc: 获取当前totalbet
    time:2019-04-11 21:10:41
    @return:
]]
function SlotRunData:getCurTotalBet()
    local machineCurBetList = self.machineData:getMachineCurBetList()
    local lastBetIdx = self.iLastBetIdx
    local totalBet = -1
    local firstBetInfo = machineCurBetList[1]
    if lastBetIdx == -1 then
        lastBetIdx = firstBetInfo.p_betId
        self.iLastBetIdx = lastBetIdx
    end
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == lastBetIdx then
            totalBet = betData.p_totalBetValue
            break
        end
    end
    if totalBet == -1 then
        lastBetIdx = firstBetInfo.p_betId
        self.iLastBetIdx = lastBetIdx
        totalBet = machineCurBetList[1].p_totalBetValue
    end
    -- MinZ
    if self:isMasterStamp() then
        totalBet = self:getMasterStampBetCoins()
    elseif self:isDIY() then
        totalBet = self:getDIYBet()
    end
    return totalBet * self.m_curBetMultiply
end
--[[
    当前bet值的倍率
        处理一套bet列表内 相同betId 不同消耗 的逻辑
]]
function SlotRunData:setCurBetMultiply(_betMultiply)
    self.m_curBetMultiply = _betMultiply
end
function SlotRunData:getCurBetMultiply()
    return self.m_curBetMultiply
end

--获取当前Bet序号
function SlotRunData:getCurBetIndex()
    local machineCurBetList = self.machineData:getMachineCurBetList()
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == self.iLastBetIdx then
            return i
        end
    end

    return 1
end

--获取当前序号 Bet Value
function SlotRunData:getCurBetValueByIndex(index)
    local machineCurBetList = self.machineData:getMachineCurBetList()
    if machineCurBetList ~= nil and #machineCurBetList >= index then
        return machineCurBetList[index].p_totalBetValue
    end
    return 1000000
end

--[[
    @desc: 检测bet id 是否在 bet 列表中
    time:2019-04-23 16:43:17
    --@betidx:
    @return:
]]
function SlotRunData:checkBetIdxInList(betidx)
    local machineCurBetList = self.machineData:getMachineCurBetList()
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == betidx then
            return true
        end
    end

    return false
end

--[[
    @desc: 获取制定 idx的 betdata
    time:2019-04-11 21:28:19
    --@betIdx: 制定 bet id
	--@offsetLen:  偏移量可以是正可以是负数
    @return:
]]
function SlotRunData:getBetDataByIdx(betIdx, offsetLen)
    if offsetLen == nil then
        offsetLen = 0
    end
    local machineCurBetList = self.machineData:getMachineCurBetList()
    local curIndex = -1
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == betIdx then
            curIndex = i
            break
        end
    end

    if curIndex == -1 then
        return nil
    end

    local offsetDis = curIndex + offsetLen
    if offsetDis < 1 then
        curIndex = #machineCurBetList + offsetDis
    elseif offsetDis > #machineCurBetList then
        curIndex = offsetDis - #machineCurBetList
    else
        curIndex = offsetDis
    end

    local betData = machineCurBetList[curIndex]
    return betData
end

function SlotRunData:getMaxBetData()
    local machineCurBetList = self.machineData:getMachineCurBetList()
    return machineCurBetList[#machineCurBetList]
end

function SlotRunData:getMaxBetIndex()
    local machineCurBetList = self.machineData:getMachineCurBetList()
    return #machineCurBetList
end

--[[
    @desc: 获取单线 bet value
    time:2019-04-11 22:41:26
    @return:
]]
function SlotRunData:getLineBet()
    local betData = self:getBetDataByIdx(self.iLastBetIdx)
    local betValue = betData.p_multiple * self.machineData.p_baseBet
    return betValue
end

--获取第一个带Jackpot的关卡
function SlotRunData:getFirstJackpotBet()
    if self.p_machineDatas ~= nil and #self.p_machineDatas > 0 then
        for i = 1, #self.p_machineDatas do
            local data = self.p_machineDatas[i]
            if data ~= nil and data.p_showJackpot == 1 then
                return data.p_levelName
            end
        end
    end

    return ""
end

--获取第一个可以玩的关卡id
function SlotRunData:getFirstGameID()
    local firstMachineData = self.m_normalMachineEntryDatas[1]
    local id = firstMachineData.p_id
    return id
end

--获取关卡名称
function SlotRunData:getLevelName(id)
    local levelInfo = self:getLevelInfoById(id)
    if not levelInfo then
        return ""
    end

    return levelInfo.p_levelName
end

-- 转换关卡名
function SlotRunData:translateLevelName(levelName)
    local st, en = nil, nil
    st, en = string.find(levelName, "^GameScreen")
    if st then
        levelName = string.sub(levelName, en + 1)
    end
    st, en = string.find(levelName, "^Level_")
    if st then
        levelName = string.sub(levelName, en + 1)
    end
    st, en = string.find(levelName, "V%d$")
    if st then
        levelName = string.sub(levelName, 1, st - 1)
    end
    return levelName
end

-- 转换关卡ID
function SlotRunData:translateLvId(lvId, isDeluexe)
    local prefix = "1"
    if isDeluexe then
        prefix = "2"
    end
    local lvId = prefix .. string.sub(tostring(lvId), 2)

    return tonumber(lvId)
end


-- AUTOSPIN自动关闭界面  view弹出的界面(必填) name按钮名称(默认"btn_close") delayTime自动点击时间(默认5秒)
function SlotRunData:checkViewAutoClick(view, name, delayTime)
    if not self.m_isNewAutoSpin then
        return
    end
    if not view then
        return
    end
    if not delayTime then
        delayTime = 8
    end
    if not name then
        name = "btn_close"
    end
    if self.m_isAutoSpinAction then
        performWithDelay(
            view,
            function()
                local sender = view:findChild(name)
                if sender and sender.isTouchEnabled and sender:isTouchEnabled() and view.clickFunc then
                    view:clickFunc(sender)
                end
            end,
            delayTime
        )
    end
end
--修改关卡维护状态
function SlotRunData:changeLevelsMaintain(id, value)
    if not id then
        return
    end
    for i = 1, #self.p_machineOriDatas do
        if self.p_machineOriDatas[i].p_id == id then
            self.p_machineOriDatas[i].p_maintain = value
        end
    end
    for i = 1, #self.p_machineDatas do
        if self.p_machineDatas[i].p_id == id then
            self.p_machineDatas[i].p_maintain = value
        end
    end
end

--获得关卡信息根据id
function SlotRunData:getLevelInfoById(id)
    if not id then
        return
    end
    local index = self.p_machineId_Idx["" .. id]
    if not index then
        return nil
    end
    local levelInfo = self.p_machineDatas[index]
    if levelInfo then
        assert(tonumber(id) == tonumber(levelInfo.p_id), "machine id is error!!!")
    end
    return levelInfo
end

-- 获得关卡索引
function SlotRunData:getLevelIdxByName(levelName)
    if not levelName then
        return
    end

    levelName = self:translateLevelName(levelName)

    local index = self.p_machineName_Idx["" .. levelName]

    return index
end

--获得关卡信息根据id
function SlotRunData:getLevelInfoByName(levelName)
    local index = self:getLevelIdxByName(levelName)
    if not index then
        return nil
    end
    local levelInfo = self.p_machineDatas[index]

    return levelInfo
end

function SlotRunData:changeMoreThanBet(betValue)
    local machineCurBetList = self.machineData:getMachineCurBetList()

    if machineCurBetList == nil or #machineCurBetList == 0 then
        return true
    end
    for i = 1, #machineCurBetList do
        if machineCurBetList[i].p_totalBetValue >= tonumber(betValue) then
            return machineCurBetList[i].p_betId
        end
    end
end

function SlotRunData:getLastEnterLevelInfo()
    return self.m_lastEnterLevelInfo
end

function SlotRunData:setLastEnterLevelInfo(info)
    if info then
        self.m_lastEnterLevelInfo = info
    end
end

-- 获取普通场的数据 - 大厅入口所用，查找配置用通用在p_machineDatas中
function SlotRunData:getNormalMachineEntryDatas()
    return self.m_normalMachineEntryDatas or {}
end

--获取大厅展示的关卡入口
function SlotRunData:getMachineEntryDatas()
    self.m_MachineEntryDatas = {}
    if self.m_normalMachineEntryDatas and #self.m_normalMachineEntryDatas > 0 then
        for i,v in ipairs(self.m_normalMachineEntryDatas) do
            if v.p_otherGame and v.p_otherGame == 1 then
            else
                table.insert(self.m_MachineEntryDatas,v)
            end
        end
    end
    return self.m_MachineEntryDatas
end

-- 获取高赔偿的数据 - 大厅入口所用，查找配置用通用在p_machineDatas中
function SlotRunData:getHighMachineEntryDatas()
    return self.m_highMachineEntryDatas or {}
end

-- 当前关卡是否竖屏
function SlotRunData:isMachinePortrait()
    if not self.machineData then
        return false
    end

    return self.machineData.p_portraitFlag
end

-- 设置显示是否竖屏
function SlotRunData:setFramePortrait(isPortrait)
    self.m_isFramePortrait = isPortrait or false
end

function SlotRunData:isFramePortrait()
    return self.m_isFramePortrait or false
end

function SlotRunData:updateLobbyEntryInfo(levelName)
    levelName = levelName or ""
    local info = self.m_slotsLobbyEntryInfos[levelName]
    if not info then
        if not SlotsLobbyEntryInfo then
            SlotsLobbyEntryInfo = require("data.baseDatas.SlotsLobbyEntryInfo")
        end
        info = SlotsLobbyEntryInfo:create()
        self.m_slotsLobbyEntryInfos[levelName] = info
    end
    info:updateInfo(levelName)
end

function SlotRunData:getLobbySpinInfo(levelName, mod)
    local info = self.m_slotsLobbyEntryInfos[levelName]
    if not info then
        return false, "", ""
    else
        if mod == "long" then
            return info:getLongSpineInfo()
        else
            return info:getSpineInfo()
        end
    end
end

--[[
    设置spin消息校验码
]]
function SlotRunData:setSpinDataValidCode(str)
    self.m_spinDataValidCode = str
end

function SlotRunData:getSpinDataValidCode()
    return self.m_spinDataValidCode
end

--[[
    MinZ 数据
]]

function SlotRunData:setIsMasterStamp(isTrue)
    self.m_IsMasterStamp = isTrue
end

function SlotRunData:setMasterStampBetCoins(betCoins)
    self.m_MasterStampBetCoins = betCoins
end

function SlotRunData:getMasterStampBetCoins()
    return self.m_MasterStampBetCoins
end

function SlotRunData:isMasterStamp()
    if self.m_IsMasterStamp and
            globalData.slotRunData and
            globalData.slotRunData.machineData and
            globalData.slotRunData.machineData.p_name == "MasterStamp" and 
            globalData.slotRunData.machineData.p_levelName == "GameScreenMasterStamp" then
            return true
    end
    return false
end

function SlotRunData:setIsDTY(isTrue)
    self.m_IsDIY = isTrue
end

function SlotRunData:setDIYBet(betCoins)
    self.m_DiyCoins = betCoins
end

function SlotRunData:getDIYBet()
    return self.m_DiyCoins
end

function SlotRunData:isDIY()
    return self.m_IsDIY
end

return SlotRunData
