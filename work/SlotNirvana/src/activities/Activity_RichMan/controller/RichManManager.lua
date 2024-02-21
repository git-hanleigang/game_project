--[[
    大富翁 活动管理器
    注意：尽量在此类进行数据处理 如有操作界面 必须post事件出去
]] --
local RichManManager = class("RichManManager", BaseActivityControl)
local RichManNet = require("activities.Activity_RichMan.net.RichManNet")

function RichManManager:ctor()
    RichManManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RichMan)
    self.inMonster = false

    self.nomalStep = {} -- 当前结果normal的步骤
    self.rushStep = {} -- 当前结果rush的步骤

    self.routerList = {} -- 路点列表
    self.curRouterIndex = 0 -- 当前位置

    self.m_richManNet = RichManNet:getInstance()
end

function RichManManager:getConfig()
    if not self.RichManConfig then
        self.RichManConfig = util_require("Activity.RichManGame.RichManConfig")
    end
    return self.RichManConfig
end

-- 发送掷骰子消息
function RichManManager:play()
    -- 等待消息结果
    if self.bl_waitting and self.bl_waitting == true then
        return
    end

    local isMonster = self:getInMonsterStage()

    local success_call_fun = function(responseTable, resData)
        self.bl_waitting = false
        local richManData = self:getRichManData()
        if richManData then
            local result = json.decode(resData.result)
            if result ~= nil then
                -- GD.dumpStrToDisk(result,"------------> result = ",20)
                if not isMonster then
                    richManData:parsePlayData(result)
                    -- 解析格子的步骤数据
                    self:parseStep(result)
                else
                    richManData:parseStageData(result)
                end
            else
                local errorMsg = "parse richman play json error"
                printInfo(errorMsg)
                release_print(errorMsg)
                gLobalViewManager:showReConnect()
            end
        end
        self:resetTargetRouter()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RICHMAN_PLAY_RESULT)
    end

    local faild_call_fun = function(target, errorCode, errorData)
        self.bl_waitting = false
        gLobalViewManager:showReConnect()
    end

    printInfo("发送掷骰子消息")
    gLobalSendDataManager:getNetWorkFeature():sendActionRichManPlay(isMonster, success_call_fun, faild_call_fun)
    self.bl_waitting = true
    local richManData = self:getRichManData()
    if richManData then
        self:setLastIndex(richManData.current)
    end
end

-- 发送掷骰子消息
function RichManManager:timeFreeze()
    -- 等待消息结果
    if self.bl_waitting and self.bl_waitting == true then
        return
    end

    local success_call_fun = function(responseTable, resData)
        self.bl_waitting = false
        local richManData = self:getRichManData()
        if richManData then
            if resData and resData.activity and resData.activity.rich then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
                richManData:parseData(resData.activity.rich)
            else
                local errorMsg = "parse richman time freeze json error"
                printInfo(errorMsg)
                release_print(errorMsg)
                gLobalViewManager:showReConnect()
            end
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        self.bl_waitting = false
        gLobalViewManager:showReConnect()
    end

    printInfo("发送消耗钻石锁定倒计时消息")
    gLobalSendDataManager:getNetWorkFeature():sendActionRichManTimeFreeze(success_call_fun, faild_call_fun)
    self.bl_waitting = true
end

-- 解析步骤
function RichManManager:parseStep(result)
    self.nomalStep = {} -- 只存两个位置 起始和结束
    self.rushStep = {} -- 只存两个位置 起始和结束
    local curStep = self.curRouterIndex
    local treasures = result.treasures
    if table.nums(treasures) > 0 then
        -- 有中奖
        local stepsNum = {}
        for k, v in pairs(treasures) do
            table.insert(stepsNum, tonumber(k))
        end
        table.sort(stepsNum)

        -- 检查这些奖励中是否中了rush
        local hasRush, rushStepNum = false, nil
        for i, v in ipairs(stepsNum) do
            if treasures[tostring(v)].rushSteps > 0 then
                hasRush = true
                rushStepNum = v
                break
            end
        end
        -- 存在rush
        if hasRush then
            -- 获得rush
            -- 普通步骤的写入
            table.insert(self.nomalStep, curStep + 1) -- 起始
            table.insert(self.nomalStep, rushStepNum) -- 结束
            -- rush步骤的写入
            table.insert(self.rushStep, rushStepNum + 1) -- 起始
            table.insert(self.rushStep, result.position) -- 结束
        else
            -- 没有rush 普通步骤的写入
            table.insert(self.nomalStep, curStep + 1) -- 起始
            table.insert(self.nomalStep, result.position) -- 结束
        end
    else
        -- 没有中奖 普通步骤的写入
        table.insert(self.nomalStep, curStep + 1) -- 起始
        table.insert(self.nomalStep, result.position) -- 结束
    end

    -- GD.dumpStrToDisk( self.nomalStep,"------------> self.nomalStep = ",20 )
    -- GD.dumpStrToDisk( self.rushStep,"------------> self.rushStep = ",20 )
end

-- 是否处于RushStep的状态中
function RichManManager:isInRushStep(curStep)
    if #self.rushStep == 0 then
        return false
    end
    local startStep = self.rushStep[1]
    local endStep = self.rushStep[2]
    return (curStep >= startStep and curStep <= endStep)
end

function RichManManager:isRushOverStep(curStep)
    if self.rushStep and #self.rushStep > 0 and self.rushStep[2] and self.rushStep[2] == curStep then
        return true
    end
    return false
end

-- 当前步骤的奖励是否已经获取
function RichManManager:isCollectReward(curStep)
    if not curStep then
        return false
    end
    local richManData = self:getRichManData()
    if richManData then
        local awardedPosition = richManData.awardedPosition
        if not awardedPosition or type(awardedPosition) ~= "table" then
            return false
        end
        for i, v in ipairs(awardedPosition) do
            if v == curStep then
                return true
            end
        end
    end
    return false
end

-- 是否处于进入rush状态
function RichManManager:isEnterRushStep(curStep)
    if #self.rushStep == 0 then
        return false
    end
    if self.nomalStep[2] == curStep then
        return true
    end
    return false
end

function RichManManager:resetTargetRouter()
    local richManData = self:getRichManData()
    if richManData and richManData.position then
        self.tarRouterIndex = richManData.position
    end
end

function RichManManager:getEnergyData()
    -- 考虑刷新globalData的数据
    local richManData = self:getRichManData()
    if richManData and richManData.energy then
        return richManData.energy
    else
        return nil
    end
end

-- 获取大富翁整体数据 --
function RichManManager:getRichManData()
    -- local richmanData = G_GetActivityDataByRef(ACTIVITY_REF.RichMan)
    -- if richmanData and richmanData:isRunning() then
    --     return richmanData
    -- end
    return self:getRunningData()
end

-- 初始化路点列表 --
function RichManManager:setRouterList(lData)
    self.routerList = {}
    if not RichManManager.obj_record then
        RichManManager.obj_record = self
        RichManManager.list_record = self.routerList
    end
    -- 将服务器数据和 显示数据合并 --
    local richManData = self:getRichManData()
    if not richManData then
        assert(false, "xcyy---------------->获取大富翁数据失败!")
        return
    end

    local lPositions = richManData.positions
    if #lData <= 399 then
        util_sendToSplunkMsg("RichMan_Datas", "下发数据长度 " .. #lData)
    end
    for i, v in ipairs(lData) do
        local router = {}
        -- 没有信息的地图块 是客户端表现用的 填默认数据就可以 服务器不会走到这里
        if not lPositions[i] then
            router.nIndex = i - 1
            router.sType = self:getConfig().enum_CellType.Blank
        else
            router.nIndex = lPositions[i].position
            router.sType = lPositions[i].type
        end
        router.pPos = v
        table.insert(self.routerList, router.nIndex, router)
    end
    printInfo("xcyy---------------->合并路点数据完成")
    -- dump(self.routerList,"大富翁地图块信息", 5)

    printInfo("xcyy---------------->初始化棋子初始位置")

    self.curRouterIndex = richManData.current
    self.tarRouterIndex = richManData.current
end

--
function RichManManager:getRouterList()
    return self.routerList
end

-- 获取下一路点 如果返回nil 说明到头了 --
function RichManManager:getRouter(pIndex)
    local pRouter = self.routerList[pIndex]
    return pRouter
end

-- 当前路点
function RichManManager:getCurRouter()
    local pRouter = self.routerList[self.curRouterIndex]
    return pRouter
end

-- 当前路点上的奖励类型
function RichManManager:getCurRouterType()
    local _curRouter = self:getCurRouter()
    if _curRouter then
        return _curRouter.sType
    end
    return self:getConfig().enum_CellType.Blank
end

-- 当前路点上的奖励数据
function RichManManager:getCurRouterTreasure()
    local _curRouter = self:getCurRouter()
    local richManData = self:getRichManData()
    if richManData then
        return richManData:getRreasuresData(_curRouter.nIndex)
    else
        return nil
    end
end

-- 当前路点上的奖励数据
function RichManManager:getRouterTreasureByIndex(nIndex)
    local richManData = self:getRichManData()
    if richManData then
        return richManData:getRreasuresData(nIndex)
    else
        return nil
    end
end

-- 获取最终大奖
function RichManManager:getFinalReward()
    local richManData = self:getRichManData()
    if richManData then
        return richManData:getFinalReward()
    else
        return nil
    end
end

-- 获取下一个路点
function RichManManager:getNextRouter()
    if not self:isEndRouter(self.curRouterIndex) then
        local nextRouderIndex = self.curRouterIndex + 1
        local nextRouter = self:getRouter(nextRouderIndex)
        return nextRouter
    end
    return false
end

function RichManManager:getCurrentRouterIndex()
    return self.curRouterIndex
end

-- 当前路点id刷新到下一个路点
function RichManManager:setNextRouter(_index)
    self.curRouterIndex = _index
end

-- 本次移动的最后一步
function RichManManager:isEndRouter(_index)
    return _index and _index >= self.tarRouterIndex
end

function RichManManager:isLastRouter(_index)
    local richManData = self:getRichManData()
    if richManData then
        return _index and _index == richManData.position
    else
        return false
    end
end

function RichManManager:setLastIndex(_index)
    self.lastIndex = _index
end
-- 上一次移动位置
function RichManManager:getLastIndex()
    return self.lastIndex
end

-- 本次棋子移动的终点
function RichManManager:getEndRouterIndex()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.current
    else
        return 0
    end
end

function RichManManager:setInMonster(bl_inMonster)
    self.inMonster = bl_inMonster
end

-- 狼关卡完全退出标记
function RichManManager:getInMonster()
    return self.inMonster
end

-- 是否正在狼关卡
function RichManManager:getInMonsterStage()
    local richManData = self:getRichManData()
    if not richManData then
        return false
    end

    if self:getCurRouterType() == self:getConfig().enum_CellType.Monster then
        -- 当前的位置是不是要打的怪物的位置 (添加这个验证是有这样的情况出现,自己打死了狼，然后摇骰子，中了race，又遇见了下一只狼)
        local _curRouter = self:getCurRouter()
        local position = _curRouter.nIndex
        local currentPosition = richManData.current -- 要到达的位置
        if position ~= currentPosition then
            return false
        end

        local monsterState = richManData.monster.status
        return tonumber(monsterState) == 0
    end
    return false
end

function RichManManager:getMonsterData()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.monster
    else
        return nil
    end
end

function RichManManager:getStateData()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.stageData
    else
        return nil
    end
end

-- 打狼奖励预览
function RichManManager:getMonsterRewards()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.monsterDisplays
    end
    return {}
end

-- 获取金币buff状态
function RichManManager:getInCoinbuff()
    local coinBuffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_RICH_COINBUFF)
    return coinBuffTimeLeft and coinBuffTimeLeft > 0
end

function RichManManager:isDoubleDice()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.doubleDiceNum and richManData.doubleDiceNum > 0
    else
        return false
    end
end

-- 剩余骰子数
function RichManManager:getLeftDice()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.leftDices
    else
        return 0
    end
end

-- 双倍骰子数
function RichManManager:getLeftDoubleDice()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.doubleDiceNum
    else
        return 0
    end
end

-- 骰子转动结果
function RichManManager:getDiceResult()
    local richManData = self:getRichManData()
    if richManData then
        return richManData.dice
    else
        return 0
    end
end

function RichManManager:willShowEnergyCollect(bl_willShow)
    self.bl_energyShow = bl_willShow
end

function RichManManager:getEnergyCollectWillShow()
    return self.bl_energyShow
end

function RichManManager:getTimeFrezzeAutoPoped()
    return self.m_timeFreezePoped or false
end

function RichManManager:setTimeFrezzeAutoPoped(bl_poped)
    self.m_timeFreezePoped = bl_poped
end

function RichManManager:getTimeUpAutoPoped()
    return self.m_timeUpPoped or false
end

function RichManManager:setTimeUpAutoPoped(bl_poped)
    self.m_timeUpPoped = bl_poped
end

-- 大厅展示资源判断
function RichManManager:isDownloadLobbyRes()
    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

function RichManManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("RichManMain") == nil then
        local richman = util_createFindView("Activity/RichManGame/RichManMain", params)
        if richman ~= nil then
            self:showLayer(richman, ViewZorder.ZORDER_UI - 2)
        end

        return richman
    else
        return nil
    end
end

function RichManManager:showRankView()
    if not self:isCanShowLayer() then
        return nil
    end

    local richManRankUI = nil
    if gLobalViewManager:getViewByExtendData("RichManRankUI") == nil then
        richManRankUI = util_createView("Activity.RichManRank.RichManRankUI")
        gLobalViewManager:showUI(richManRankUI, ViewZorder.ZORDER_POPUI)
    end
    return richManRankUI
end

-- 大富翁请求排行榜数据
function RichManManager:sendActionRank()
    self.m_richManNet:sendActionRank()
end

return RichManManager
