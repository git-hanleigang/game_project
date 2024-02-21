--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-06 14:41:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-06 14:51:42
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/controller/NewUserExpandManager.lua
Description: 扩圈系统 管理类
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NewUserExpandData = util_require("GameModule.NewUserExpand.model.NewUserExpandData")
local NewUserExpandManager = class("NewUserExpandManager", BaseGameControl)

function NewUserExpandManager:ctor()
    NewUserExpandManager.super.ctor(self)
    self:setRefName(G_REF.NewUserExpand)

    self.m_curType = NewUserExpandConfig.LOBBY_TYPE.SLOTS
    self.m_bClickEntry = gLobalDataManager:getBoolByField("user_click_expand_entry", false)
    self.m_exPandData = NewUserExpandData:create()

    -- 登录前配置里 解析是否是扩圈用户，据此下载扩圈所需资源
    local expandCircleConfig = globalData.GameConfig:getExpandCircleConfig()
    self:setUserExpandEnabled(expandCircleConfig)
end

-- 获取网络 obj
function NewUserExpandManager:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local NewUserExpandNet = util_require("GameModule.NewUserExpand.net.NewUserExpandNet")
    self.m_net = NewUserExpandNet:getInstance()
    return self.m_net
end

-- 获取引导obj
function NewUserExpandManager:getGuide()
    if self.m_guideObj then
        return self.m_guideObj
    end
    local NewUserExpandGuideMgr = util_require("GameModule.NewUserExpand.controller.NewUserExpandGuideMgr")
    self.m_guideObj = NewUserExpandGuideMgr:getInstance()
    return self.m_guideObj
end

-- 获取日志obj
function NewUserExpandManager:getLogObj()
    if self.m_logObj then
        return self.m_logObj
    end
    local LogExpand = util_require("GameModule.NewUserExpand.net.LogExpand")
    self.m_logObj = LogExpand:create()
    return self.m_logObj
end

function NewUserExpandManager:setUserExpandEnabled(_config, _bHeart, _bForce)
    if not _config then
        return
    end

    if not _bForce and self.m_downloadGameKey then
        -- 登录后 扩圈游戏数据 强制修改游戏类型 (以登录数据游戏类型为主)
        return
    end

    local gameType = _config
    if type(_config) == "table" then
        gameType = _config.gameType
    end
    self:parseExpandGameDLKey(gameType)
    if _bHeart then
        self:checkActiveExpand()
    end
end
function NewUserExpandManager:parseExpandGameDLKey(_gameType)
    if type(_gameType) ~= "string" or _gameType == "" then
        return
    end

    local dlKey = NewUserExpandConfig.GMAE_DL_KEY[_gameType]
    self.m_downloadGameKey = dlKey
    self:checkRequireGameMgrLua()
end
function NewUserExpandManager:checkActiveExpand()
    if not self.m_downloadGameKey then
        return
    end

    -- 心跳中监测到玩家可以玩扩圈系统， 发请求激活扩圈系统
    self:sendActiveExpandFeatureReq()
    self:downloadExpandRes()
end
function NewUserExpandManager:getDownloadGameKey()
    return self.m_downloadGameKey
end

-- 获取数据
function NewUserExpandManager:getData()
    return self.m_exPandData
end
function NewUserExpandManager:parseData(_data)
    self.m_exPandData:parseData(_data)
end

-- 获取当前大厅 类型 普通大厅还是扩圈
function NewUserExpandManager:setCurLobbyStyle(_type)
    if not self.m_bClickEntry then
        self.m_bClickEntry = true
        gLobalDataManager:setBoolByField("user_click_expand_entry", true)
    end
    self.m_curType = _type
end
function NewUserExpandManager:getCurLobbyStyle()
    return self.m_curType
end
function NewUserExpandManager:checkLobbyIsSlotsStyle()
    return self.m_curType == NewUserExpandConfig.LOBBY_TYPE.SLOTS
end
-- 用户是否点击过 扩圈入口页签
function NewUserExpandManager:checkUserHadClickEntry()
    return self.m_bClickEntry
end

-- 扩圈玩家类型
function NewUserExpandManager:checkIsClientActiveType()
    return self.m_exPandData:checkIsClientActiveType()
end
function NewUserExpandManager:checkIsServerActiveType()
    return self.m_exPandData:checkIsServerActiveType()
end

-- 创建 大厅选择 大厅显示主题 标签UI
function NewUserExpandManager:createExpandEntryUI()
    if not self:checkExpandRunning() then
        return
    end

    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandEntry")
    return view
end

-- 创建 扩圈主UI
function NewUserExpandManager:createExpandMainLayer()
    if not self:checkExpandRunning() then
        return
    end

    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandMainUI")
    return view
end

-- 显示 奖励弹板
function NewUserExpandManager:showRewardLayer(_coins, _cb)
    if not self:checkExpandRunning() then
        return
    end

    if gLobalViewManager:getViewByName("ExpandRewardLayer") then
        return
    end

    local view = util_createView("GameModule.NewUserExpand.views.ExpandRewardLayer", _coins, _cb)
    self:showLayer(view)
    return view
end

-- 去玩小游戏
function NewUserExpandManager:gotoPlayGame()
    if not self.m_downloadGameKey then
        return
    end
    local gameMgr = G_GetMgr(self.m_downloadGameKey)
    if not gameMgr:isDownloadRes() then
        self:showLoadingLayer()
        return
    end
    local view = gameMgr:showMainLayer()
    return view
end
function NewUserExpandManager:showLoadingLayer()
    if not self.m_downloadGameKey then
        return
    end
    
    if gLobalViewManager:getViewByName("ExpandLoadingGameLayer") then
        return
    end

    local view = util_createView("GameModule.NewUserExpand.views.ExpandLoadingGameLayer", self.m_downloadGameKey)
    self:showLayer(view)
    return view
end

-- 心跳中监测到玩家可以玩扩圈系统， 发请求激活扩圈系统
function NewUserExpandManager:sendActiveExpandFeatureReq()
    if not self.m_downloadGameKey then
        return
    end

    local successCB = function()
        if self:checkExpandRunning(true) then
            gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.LOAD_EXPAND_FEATURE)
        end
    end
    self:getNetObj():sendActiveExpandFeatureReq(successCB)
end
-- 完成上一关激活下一个关卡
function NewUserExpandManager:sendActiveExpandNewTaskReq()
    self:getNetObj():sendActiveExpandNewTaskReq(self.m_downloadGameKey)
end

-- 是否下载 完
function NewUserExpandManager:isDownloadRes()
    -- if device.platform == "mac" then
    --     return true
    -- end

    local zipList = self:getUserNeedDLZips()
    if #zipList == 0 then
        return false
    end

    for _, dlKey in pairs(zipList) do
        local bDownload = self:checkDownloaded(dlKey)
        if not bDownload then
            return false
        end
    end

    return true
end

-- 获取该用户扩圈需要 下载的资源
function NewUserExpandManager:getUserNeedDLZips(_type)
    local zipList = {}
    local data = self:getData()
    if self.m_downloadGameKey then
        table.insert(zipList, "ExpandLobby")   -- 大厅资源放到res里，整包还有空间 2023年09月22日18:27:21 再放到dy里
        table.insert(zipList, self.m_downloadGameKey)
    end
    
    return zipList
end

-- 获取下载info list
function NewUserExpandManager:getDlZips(_type)
    local dlZips = {}
    local _dlZips = self:getUserNeedDLZips(_type)

    for _, dlKey in pairs(_dlZips) do
        local bDownload = self:checkDownloaded(dlKey)
        if not bDownload then

            local dyInfo = globalData.GameConfig.dynamicData[dlKey]
            if dyInfo then
                local dlInfo = {
                    key = dyInfo.zipName,
                    md5 = dyInfo.md5,
                    type = dyInfo.type,
                    zOrder = "1",
                    size = (dyInfo.size or 123)
                }
                table.insert(dlZips, dlInfo)
            end

        end
    end

    return dlZips
end

function NewUserExpandManager:downloadExpandRes()
    local dlZips = self:getDlZips()
    local ExpandSysDLControl = util_require("common.ExpandSysDLControl")
    ExpandSysDLControl:getInstance():downloadExpandRes(dlZips)
end
function NewUserExpandManager:downloadOver()
    if self:checkExpandRunning(true) then
        gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.LOAD_EXPAND_FEATURE)
    end
    util_printLog("cxc_NewUserExpandManager-download--over")
end

function NewUserExpandManager:checkRequireGameMgrLua()
    if not self.m_downloadGameKey then
        return
    end
 
    local mgrName = NewUserExpandConfig.MINI_GAME_MGR_NAME[self.m_downloadGameKey]
    if not mgrName then
        return
    end
    local mgrPath = string.format("GameModule.NewUserExpand.controller.%s", mgrName)
    util_require(mgrPath):getInstance()
end

-- 检查扩圈系统是否运行中
function NewUserExpandManager:checkExpandRunning(_bCheckRes)
    local _data = self:getRunningData()
    if not _data or (_data.isSleeping and _data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    -- 判断资源是否下载
    _bCheckRes = true
    if _bCheckRes and not self:isDownloadRes() then
        return false
    end

    return true
end
-- 登录到大厅检查下 显示哪种大厅
function NewUserExpandManager:checkUpdateLobbyStyle()
    if self:checkExpandRunning() then
        local gameData = self:getData():getGameData()
        local lastTaskData = gameData:getLastTaskData()
        if not lastTaskData:checkPass() then
            self.m_curType = NewUserExpandConfig.LOBBY_TYPE.PUZZLE
        end
    end
end

-- 获取 扩圈小游戏 mainUI 的luaname
function NewUserExpandManager:getMiniGameMainUILuaName()
    if not self.m_downloadGameKey then
        return
    end
 
    local mainLuaName = NewUserExpandConfig.MINI_GAME_MAIN_UI_LUA_NAME[self.m_downloadGameKey]
    return mainLuaName
end

-- 扩圈检查 是否需要过渡场景
function NewUserExpandManager:checkIgnoreTransitionScene()
    if self.m_curType ~= NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
        return false
    end

    local gameData = self:getData():getGameData()
    if not gameData then
        return false
    end

    local curTaskData = gameData:getCurTaskData()
    if not curTaskData then
        return
    end

    if curTaskData:getSeq() < 4 then
        -- 前三关 都不走过渡场景动画， 引导遮罩啊 横竖屏啊 都会有问题
        return true
    end
    return false
end

-- 矮人金矿 10125 扩圈玩家进入关卡 先引导 关卡规则 然后引导 noobTaskStart1
function NewUserExpandManager:checkShowExpandLevelsRuleGuide()
    local curMachineData = globalData.slotRunData.machineData or {}
    local slotId = curMachineData.p_id
    if tostring(slotId) ~= "10125" then
        return false
    end
    if not self:checkExpandRunning() then
        return false
    end

    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.noobTaskStart1.id)
    if bFinish then
        return false
    end

    if gLobalViewManager:getViewByName("ExpandGuideLevelRuleLayer") then
        return
    end
    local view = util_createView("GameModule.NewUserExpand.views.ExpandGuideLevelRuleLayer")
    self:showLayer(view)
    return view
end

return NewUserExpandManager