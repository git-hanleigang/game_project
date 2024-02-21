--
-- 存储各个机器的数据，基础配置数据、客户端热更新数据、jackpot相关
-- 、bet档位相关
-- Date: 2019-04-10 17:24:18
-- FIX IOS 139
-- local RecommendBetData = require "data.baseDatas.RecommendBetData"
local MachineBetsData = require "data.baseDatas.MachineBetsData"
local BetConfigData = require "data.baseDatas.BetConfigData"
local MachineData = class("MachineData")

-- 客户端热更新数据
MachineData.p_id = nil
MachineData.p_levelName = nil
MachineData.p_csbName = nil
MachineData.p_betCsbName = nil
MachineData.p_showName = nil -- 客户端levels102.json中程序写的showName
MachineData.p_freeOpen = nil -- bool 类型
MachineData.p_showOrder = nil
MachineData.p_openLevel = 1
MachineData.p_showJackpot = nil -- 0 不显示 1显示
MachineData.p_specialFeature = nil -- 0 不显示 1显示
MachineData.p_levelVersion = nil -- 版本编号
MachineData.p_hideVersion = nil -- 隐藏的版本号， 默认为nil
MachineData.p_Log = nil -- hot  、 new
MachineData.p_firstOrder = nil --推荐关卡顺序(大图显示) 详细说明：有此字段是大图，并且表示大图的顺序
MachineData.p_longIcon = nil --在小图标顺序里面显示大图

MachineData.p_portraitFlag = nil -- 是否是竖屏 0 横， 1竖
MachineData.p_highBetFlag = nil -- 是否高倍场 0 否 1 是
MachineData.p_md5 = nil -- 关卡md5值

MachineData.p_commingSoonIndex = nil --自动添加的commingSoon
MachineData.p_showTitle = nil --是否显示标签目前只给commingSoon使用
-- 关卡模板基础数据
MachineData.p_name = nil -- 用来做网络消息通信使用
MachineData.p_serverShowName = nil -- 服务器关卡策划配置的 showName
MachineData.p_baseBet = nil
MachineData.p_lineNum = nil --
MachineData.p_specialLines = nil -- 存储特殊线数数组
MachineData.p_winTypes = nil -- 大赢倍数列表 目前只是配置了3个
MachineData.p_link = nil -- 是否产生link卡

MachineData.p_betsData = nil -- 关卡能使用的bet 列表

MachineData.p_WinSourceType = nil
MachineData.p_fastLevel = nil --是否快速进入关卡（在loading里下载资源）
MachineData.p_maintain = nil --版本维护中
MachineData.p_openAppVersion = nil --开启版本
MachineData.p_openTime = nil --开启日期
MachineData.p_bHideLevel = nil --隐藏关卡入口 -- 数据还是在的能查找到
-- cxc 新关卡显示推荐bet
MachineData.p_recommendBets = nil -- 推荐的bet 档位信息
MachineData.p_recommendType = nil -- 推荐bet显示类型
MachineData.p_recommendDesc = nil -- 推荐bet显示 描述
MachineData.p_specialBets = nil -- bet 类型基准 拿这个值做判断 大于等于显示黄色，小于显示绿色
MachineData.p_sepcialGameType = nil -- 特殊关卡标签 ps:例如推币机关卡通过该字段区别创建 Scene
-- grand分享
MachineData.p_jackpotShare = nil -- 可以分享的jackpot索引列表{1, 2, 3}
MachineData.p_minzGame = nil -- 是否是minz关卡
MachineData.p_diyFeatureGame = false -- 是否是DIY关卡
MachineData.p_frostFlameClashGame = nil -- 是否是1v1关卡
MachineData.p_playTypeInfo = nil -- 关卡玩法标签信息
MachineData.p_otherGame = nil -- 关卡玩法标签信息
MachineData.p_isSlotMod = false -- 是否在关卡模组中

function MachineData:ctor()
    self.m_extraLevel = 5
end

--解析levels.json数据新配置
function MachineData:parseLevelConfigs(levelData, config)
    self.p_id = levelData["ID"] --游戏id
    self.p_levelName = levelData["levelName"] --关卡名字
    self.p_csbName = levelData["csbName"] --入口图标下载相关
    self.p_showName = levelData["showName"] --显示名字
    self.p_md5 = levelData["md5"] -- 这个是自动生成的
    self.p_codemd5 = levelData["codemd5"] -- 这个是自动生成的
    self.p_showOrder = tonumber(levelData["showOrder"] or 9999) --列表中的顺序
    self.p_showJackpot = levelData["showJackpot"] -- 0 不显示 1显示
    self.p_specialFeature = levelData["specialFeature"] -- 特殊玩法标签
    self.p_WinSourceType = levelData["winSourceType"] -- 关卡音效第几套
    self.p_showTitle = levelData["showTitle"] --commonsoon title
    self.p_portraitFlag = levelData["portraitFlag"] -- 是否是竖屏 0 横， 1竖
    self.p_bytesSize = levelData["size"] -- 关卡大小
    self.p_codeSize = levelData["codeSize"] -- 关卡代码大小

    self:setOpenTime(levelData["openTime"]) --开放时间

    if self.p_portraitFlag == nil or self.p_portraitFlag == 0 then
        self.p_portraitFlag = false
    else
        self.p_portraitFlag = true
    end
    self.p_highBetFlag = false
    self.p_openAppVersion = levelData["openAppVersion"]
    --最低支持app版本例如"1.3.0"
    self:checkLongIcon(config["longIcon"]) --检测是否为大图
    -- self:updateOpenLevel(config["levelsInfo"])         --刷新解锁等级
    self:checkExtraInfo(config["extraInfo"]) --检测额外标签
    self:updateOtherInfo(config["ortherInfo"]) --刷新其他配置
    self:checkSpcialGameType(config["sepcialGame"]) --检测特殊关卡类型
end

function MachineData:parseBaseData(baseData)
    self.p_name = baseData.name -- 用来做网络消息通信使用
    self.p_baseBet = baseData.baseBet
    self.p_lineNum = baseData.lines --
    self.p_specialLines = baseData.specialLines -- 存储特殊线数数组
    self.p_winTypes = baseData.winTypes -- 大赢倍数列表 目前只是配置了3个
    if baseData.link then
        self.p_link = baseData.link -- 产出link卡
    end
    self.p_maintain = baseData.maintain -- 版本维护中

    self.p_recommendBets = baseData.recommendBets -- 推荐的bet 档位信息
    self.p_recommendType = baseData.type -- 推荐bet显示类型
    self.p_recommendDesc = baseData.description -- 推荐bet显示 描述
    self.p_specialBets = baseData.specialBets -- bet 类型基准 拿这个值做判断 大于等于显示黄色，小于显示绿色
    self.p_serverShowName = baseData.showName -- 服务器关卡策划配置的 showName
    self.p_jackpotShare = baseData.jackpotShare -- grand分享
    if not self:isHightMachine() then
        self.p_showOrder = baseData.showOrder -- 关卡显示顺序
        self.p_openLevel = baseData.openLevel -- 关卡开启等级
        self:parseTagShowType(baseData.showType) --关卡显示图标
    end
    -- 是否是minz关卡
    self.p_minzGame = baseData.minzGame or false
    -- 是否是Diy关卡
    self.p_diyFeatureGame = baseData.diyFeatureGame or false
    self.p_frostFlameClashGame = baseData.flameClashGame or false -- 是否是1v1关卡
    if string.len(baseData.playIcon or "") > 3 then
        self.p_playTypeInfo = string.split(baseData.playIcon, "|")
    end
    self.p_otherGame = baseData.otherGame --页签类别
end

--检测自己是否在列表中
function MachineData:getIndexForList(list)
    if self.p_levelName and list and #list > 0 then
        for i = 1, #list do
            if self.p_levelName == list[i] then
                return i
            end
        end
    end
    return 0
end

--检测是否为大图
function MachineData:checkLongIcon(longIconList)
    local index = self:getIndexForList(longIconList)
    if index > 0 then
        self.p_longIcon = true
    else
        self.p_longIcon = false
    end
end
--刷新解锁等级
-- function MachineData:updateOpenLevel(levelsInfo)
--       self.p_openLevel = 1
--       if not levelsInfo then
--             return
--       end
--       local openLevel = levelsInfo["initLevel"] or 1
--       local addLevel = levelsInfo["addLevel"]
--       --推算解锁等级
--       if self.p_showOrder and self.p_showOrder >0 then
--             for key,value in pairs(addLevel) do
--                   if value>0 then
--                         local numData = util_string_split(key,"-",true)
--                         if #numData==2 then
--                               if self.p_showOrder>=numData[2] then
--                                     local count = (numData[2]-numData[1]+1)*value
--                                     openLevel = openLevel+count
--                               elseif self.p_showOrder>=numData[1] then
--                                     local count = (self.p_showOrder-numData[1]+1)*value
--                                     openLevel = openLevel+count
--                               end
--                         elseif #numData==1 and self.p_showOrder >=numData[1]then
--                               openLevel = openLevel+value
--                         end
--                   end
--             end
--       end
--       self.p_openLevel = openLevel
-- end
--检测额外标签
function MachineData:checkExtraInfo(extraInfo)
    if not extraInfo then
        return
    end

    local extraLevel = extraInfo["extraInfo"] or 5
    self.m_extraLevel = extraLevel
end

--刷新其他配置
function MachineData:updateOtherInfo(ortherInfo)
    if not ortherInfo then
        return
    end
    --支持的热更版本
    self.p_levelVersion = 1
    local levelVersion = ortherInfo["levelVersion"]
    if levelVersion then
        for key, value in pairs(levelVersion) do
            local index = self:getIndexForList(value)
            if index > 0 then
                self.p_levelVersion = tonumber(key)
                break
            end
        end
    end
    --是否为打入包内关卡
    local freeOpen = ortherInfo["freeOpen"]
    local index = self:getIndexForList(freeOpen)
    if index > 0 then
        self.p_freeOpen = true
    else
        self.p_freeOpen = false
    end

    --所有关卡使用rgb8888 并且在loading期间下载
    self.p_fastLevel = true

    --是否隐藏关卡
    local hideLevel = ortherInfo["hideLevel"]
    local index = self:getIndexForList(hideLevel)
    if index > 0 then
        self.p_bHideLevel = true
    else
        self.p_bHideLevel = false
    end
end

function MachineData:checkSpcialGameType(_lSepcialGameList)
    local type = _lSepcialGameList[self.p_levelName]
    if type then
        self.p_sepcialGameType = type
    end
end

function MachineData:changeHighBet(showOrder)
    self.p_showOrder = showOrder or 1
    self.p_highBetFlag = true
    local strId = "2" .. string.sub(tostring(self.p_id), 2)
    self.p_id = tonumber(strId)
end

function MachineData:isHightMachine()
    return self.p_highBetFlag
end

function MachineData:getExtraBetData()
    return self.p_betsData.p_extraBetData
end

function MachineData:getFreeGameBetData()
    return self.p_betsData.p_freeGameBetData
end

--[[
    @desc: 解析关卡bet 档位信息
    time:2019-04-11 11:42:13
    @param betsData
    @return:
]]
function MachineData:parseMachineBetsData(data)
    local betsData = self.p_betsData
    if not betsData then
        betsData = MachineBetsData:create()
    end
    if data.name ~= nil and data.name ~= "" then
        betsData.p_machineName = data.name -- 关卡名字
    else
        betsData.p_machineName = "" -- 关卡名字
        release_print("关卡名字为空")
    end
    if data.gameId ~= nil and data.gameId ~= "" then
        betsData.p_machineId = data.gameId -- 关卡id
    else
        betsData.p_machineId = 0 -- 关卡id
        release_print("关卡id为空")
    end

    -- 解析上次 feature 中的total bet
    if data:HasField("extraBet") == true then
        local extraBetData = data.extraBet
        betsData.p_extraBetData = BetConfigData:create()
        betsData.p_extraBetData:parseData(extraBetData)
    else
        betsData.p_extraBetData = nil
    end

    -- 解析需要修改的bet（特殊玩法结束后，需要还原的bet）
    if data:HasField("newBet") == true then
        local newBet = data.newBet
        betsData.p_specNewBet = BetConfigData:create()
        betsData.p_specNewBet:parseData(newBet)
    else
        betsData.p_specNewBet = nil
    end

    -- 解析上次 免费spin活动 中的total bet
    if data:HasField("freeGameBet") == true then
        local freeGameBetData = data.freeGameBet
        betsData.p_freeGameBetData = BetConfigData:create()
        betsData.p_freeGameBetData:parseData(freeGameBetData)
    else
        betsData.p_freeGameBetData = nil
    end

    -- 特殊total bet 列表
    local specialList = data.specialBets
    local specialDatas = {}
    for i = 1, #specialList do
        local data = specialList[i]
        local specialData = BetConfigData:create()
        specialData:parseData(data)
        specialDatas[#specialDatas + 1] = specialData
    end
    betsData.p_specialBets = specialDatas --特殊total bet 列表

    local betList = data.betList
    local betDatas = {}
    for i = 1, #betList do
        local data = betList[i]
        local betData = BetConfigData:create()
        betData:parseData(data)

        betDatas[#betDatas + 1] = betData
    end
    betsData.p_betList = betDatas -- 对应等级可以使用的bet 列表

    betsData:updateCurBetList()
    self.p_betsData = betsData
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_SPIN_MAX_BET)
end

--[[
    @desc: 获取当前关卡 bet 列表
    time:2019-04-11 21:06:56
    @return:
]]
function MachineData:getMachineCurBetList()
    if not self.p_betsData then
        return {}
    end
    return self.p_betsData.p_curBetList
end

--[[
    @desc: 获取当前关卡 bet 列表
    time:2019-04-11 21:06:56
    @return:
]]
function MachineData:updateSpecNewBetsData()
    if not self.p_betsData then
        return
    end

    local specNewBet = self.p_betsData.p_specNewBet
    if not specNewBet then
        return
    end
    local betList = self.p_betsData.p_betList
    for i = 1, #betList do
        local betInfo = betList[i]
        if betInfo.p_betId == specNewBet.p_betId then
            self.p_betsData.p_betList[i] = clone(specNewBet)
            break
        end
    end
    local curBetList = self.p_betsData.p_curBetList
    for i = 1, #curBetList do
        local betInfo = curBetList[i]
        if betInfo.p_betId == specNewBet.p_betId then
            self.p_betsData.p_curBetList[i] = clone(specNewBet)
            break
        end
    end
    -- 只刷新一次就行了
    self.p_betsData.p_specNewBet = nil
end

--[[
    @desc: 获取最大bet ， maxbet
    time:2019-05-16 22:34:14
    @return:
]]
function MachineData:getMaxBet()
    local betList = self:getMachineCurBetList()
    if betList == nil or #betList == 0 then
        return 0
    end
    local betData = betList[#betList]
    return betData.p_totalBetValue
end

-- 检查是否触发新的 最大BetId
function MachineData:checkNewMaxBetActive()
    if not self.p_betsData then
        return false
    end
    return self.p_betsData:checkNewMaxBetActive()
end

-- 获取最大bet 配置
function MachineData:getMaxBetCfgData()
    if not self.p_betsData then
        return {}, {}
    end
    return self.p_betsData:getMaxBetCfgData()
end

--[[
    time:2019-04-16 16:34:27
    @return: 返回当前关卡配置的 bigwin 倍数, 如果为空用默认倍数
]]
function MachineData:getBigWinRate()
    local rate = BIG_WIN_COIN_LIMIT
    if self.p_winTypes ~= nil and self.p_winTypes[1] ~= nil then
        rate = self.p_winTypes[1]
    end
    return rate
end

--[[
    time:2019-04-16 16:34:27
    @return: 返回当前关卡配置的 megawin 倍数, 如果为空用默认倍数
]]
function MachineData:getMegaWinRate()
    local rate = MEGA_WIN_COIN_LIMIT
    if self.p_winTypes ~= nil and self.p_winTypes[2] ~= nil then
        rate = self.p_winTypes[2]
    end
    return rate
end

--[[
    time:2019-04-16 16:34:27
    @return: 返回当前关卡配置的 hugewin 倍数, 如果为空用默认倍数
]]
function MachineData:getHugeWinRate()
    local rate = EPIC_WIN_COIN_LIMIT
    if self.p_winTypes ~= nil and self.p_winTypes[3] ~= nil then
        rate = self.p_winTypes[3]
    end
    return rate
end

--[[
    time:2019-04-16 16:34:27
    @return: 返回当前关卡配置的 Legendary 倍数, 如果为空用默认倍数
]]
function MachineData:getLegendaryRate()
    local rate = LEGENDARY_WIN_COIN_LIMIT
    if self.p_winTypes ~= nil and self.p_winTypes[4] ~= nil then
        rate = self.p_winTypes[4]
    end
    return rate
end

--[[
      --打开时间
 ]]
function MachineData:setOpenTime(time)
    self.p_openTime = nil
    if time then
        self.p_openTime = util_getymd_time(time)
    -- self.p_openTime = math.floor(globalData.userRunData.p_serverTime / 1000+ 120)
    end
end

function MachineData:getLeftTime(time, str)
    local days = util_leftDays(time)
    if days > 0 then
        if str then
            return string.format("%d" .. str, days)
        else
            return string.format("%d", days)
        end
    else
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        local isOver = false
        local tempTime = time - curTime
        if tempTime <= 0 then
            tempTime = 0
            isOver = true
        end
        return util_count_down_str(tempTime), isOver
    end
end

function MachineData:getOpentLeftTime(str)
    local strLeftTime, isOver = self:getLeftTime(self.p_openTime, str)
    return strLeftTime, isOver
end

function MachineData:getLeftTimeInfo(str)
    if not self.p_openTime then
        return false
    end

    local timeStamp, isOver = self:getOpentLeftTime(str)
    local bDaysTimes = false

    if isOver then
        return false
    end

    if isOver == nil then
        bDaysTimes = true
    end

    return true, timeStamp, bDaysTimes
end

--[[
    @desc: 解析关卡显示图标
    --@_type: 类型 normal hot new extra_hot extra_new extra_feature
]]
function MachineData:parseTagShowType(_type)
    if not _type or _type == "" or _type == "normal" then
        return
    end

    local list = string.split(_type, "extra_")
    self.p_Log = list[#list]
    if #list == 1 then
        self.p_openLevel = 1
    elseif #list > 1 and self.p_openLevel > self.m_extraLevel then
        -- 包含extra
        self.p_openLevel = self.m_extraLevel
    end
end

-- 获取 网络消息通信使用 的关卡名字
function MachineData:getServerNetName()
    return self.p_name -- 用来做网络消息通信使用
end

-- 获取 服务器关卡策划配置的 showName
function MachineData:getServerShowName()
    return self.p_serverShowName -- 服务器关卡策划配置的 showName
end

-- 获取可以分享的jackpot索引列表
function MachineData:getJackpotShare()
    return self.p_jackpotShare or {}
end

-- 获取是否是minz关卡
function MachineData:getMinzGame()
    return self.p_minzGame or false
end

-- 获取是否是DiyFeature关卡
function MachineData:getDiyFeatureGame()
    return self.p_diyFeatureGame or false  
end

-- 获取是否是1v1关卡
function MachineData:getFrostFlameClashGame()
    return self.p_frostFlameClashGame or false
end

-- 设置是否是长关卡
function MachineData:setLongIcon(_longIcon)
    self.p_longIcon = _longIcon
end

-- 设置是否在关卡模组
function MachineData:setSlotMod(_isSlotMod)
    self.p_isSlotMod = _isSlotMod
end

-- 是否在关卡模组
function MachineData:isSlotMod()
    return self.p_isSlotMod
end

return MachineData
