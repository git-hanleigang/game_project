---
-- xcyy
-- 2018-12-18 
-- LuckyRacingMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local LuckyRacingMiniMachine = class("LuckyRacingMiniMachine", BaseMiniMachine)




LuckyRacingMiniMachine.m_machineIndex = nil -- csv 文件模块名字

LuckyRacingMiniMachine.gameResumeFunc = nil
LuckyRacingMiniMachine.gameRunPause = nil



local Main_Reels = 1


-- 构造函数
function LuckyRacingMiniMachine:ctor()
    LuckyRacingMiniMachine.super.ctor(self)

    
end

function LuckyRacingMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parentMachine = data.parent 
    self.m_parentView = data.parentView
    self.m_maxReelIndex = data.maxReelIndex 


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    self.m_bonus_pool = {}

    --init
    self:initGame()
end

function LuckyRacingMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function LuckyRacingMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LuckyRacing"
end

function LuckyRacingMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function LuckyRacingMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "LuckyRacing_Mati"
    end
    local ccbName = self.m_parentMachine:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function LuckyRacingMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end

    if self.m_machineIndex == 2 or self.m_machineIndex == 4 then
        self.m_configData.p_reelRunDatas = {36,43,50}
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function LuckyRacingMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("LuckyRacing_XiaoQipan.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    --外圈光效
    self.m_light = util_createAnimation("LuckyRacing_jiantou_0L1.csb")
    self:addChild(self.m_light,100)
    self.m_light:runCsbAction("idleframe",true)
    self.m_light:setVisible(false)
    for index = 1,4 do
        self:findChild("qipan_"..(index - 1)):setVisible(index == self.m_machineIndex)
        self.m_light:findChild("Sprite_"..index):setVisible(index == self.m_machineIndex)
    end

end

--[[
    自己轮盘光效
]]
function LuckyRacingMiniMachine:isSelfMachineAni(isSelf)
    self.m_light:setVisible(isSelf)
    if isSelf then
        local pos = util_convertToNodeSpace(self.m_light,self.m_parentView)
        --变更父节点
        util_changeNodeParent(self.m_parentView,self.m_light,100)
        self.m_light:setPosition(pos)

        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_lock_reel.mp3")
        self.m_light:runCsbAction("actionframe",false,function()
            self.m_light:runCsbAction("idleframe",true)

            self:runCsbAction("actionframe",false,function()
                self:runCsbAction("idleframe2")
            end)

            local pos = util_convertToNodeSpace(self.m_light,self)
            --变更父节点
            util_changeNodeParent(self,self.m_light,100)
            self.m_light:setPosition(pos)
        end)
    end
end

--[[
    idle
]]
function LuckyRacingMiniMachine:runIdleAni()
    self:runCsbAction("idleframe")
end

--[[
    隐藏光效
]]
function LuckyRacingMiniMachine:hideLight()
    self.m_light:setVisible(false)
end

--
---
--
function LuckyRacingMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    LuckyRacingMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function LuckyRacingMiniMachine:addSelfEffect()


    -- -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 7
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
 
end


function LuckyRacingMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    -- end

    return true
end




function LuckyRacingMiniMachine:onEnter()
    LuckyRacingMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end



function LuckyRacingMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function LuckyRacingMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function LuckyRacingMiniMachine:quicklyStopReel(colIndex)


end

function LuckyRacingMiniMachine:onExit()
    LuckyRacingMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function LuckyRacingMiniMachine:removeObservers()
    LuckyRacingMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function LuckyRacingMiniMachine:setResultData(result)
    self.m_resultData = result
end

function LuckyRacingMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function LuckyRacingMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    self.m_bonus_pool = {}
    LuckyRacingMiniMachine.super.beginReel(self)

    self:netWorkCallFun(self:getSpinResult())    
end

function LuckyRacingMiniMachine:getSpinResult()
    local spinResult = {
        winAmount = 0,
        gemsExtra = {},
        prevReel = {94,94,94},
        nextReel = {94,94,94},
        jackpotCoins = {},
        avgBet = 0,
        jackpotMultiple = {},
        reels = {
            {94,94,94},
            {94,94,94},
            {94,94,94}
        },
        freespin = {
            fsMultiplier = 0,
            freeSpinNewCount = 0,
            freeSpinsLeftCount = 0,
            fsWinCoins = 0,
            newTrigger = false,
            freeSpinsTotalCount = 0,
            fsModeId = 0
        },
        selfData = {
            positionScore = {}
        },
        gems = 0,
        respin = {
            reSpinCurCount = 0,
            resWinCoins = 0,
            reSpinsTotalCount = 0
        },
        jackpots = {},
        payLineCount = 0,
        winAmountValue = 0
    }
    
    --当前spin次数
    local curSpinIndex = self.m_parentView.m_curSpinIndex
    --获取当前倍数列表
    local mutipleList = self.m_resultData.data.userMultipleList[tostring(self.m_machineIndex - 1)]
    local multiples = mutipleList[curSpinIndex]

    local pool = {0,1,2,3,4,5,6,7,8}
    if multiples then
        for index,multiple in pairs(multiples) do
            --把倍数插到轮盘里
            local randIndex = math.random(1,#pool)
            local pos = self:getRowAndColByPos(pool[randIndex])
            local iCol,iRow = pos.iY,pos.iX

            spinResult.reels[iRow][iCol] = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            spinResult.selfData.positionScore[tostring(pool[randIndex])] = multiple
            --移除池子里对应的位置
            table.remove(pool,randIndex,1)
        end

        spinResult.selfData.multipleList = clone(multiples)
        
    end

    return spinResult
end


-- 消息返回更新数据
function LuckyRacingMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function LuckyRacingMiniMachine:enterLevel( )
    LuckyRacingMiniMachine.super.enterLevel(self)
end

function LuckyRacingMiniMachine:enterLevelMiniSelf( )

    LuckyRacingMiniMachine.super.enterLevel(self)
    
end

function LuckyRacingMiniMachine:dealSmallReelsSpinStates( )
    
end



-- 处理特殊关卡 遮罩层级
function LuckyRacingMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end



---
--设置bonus scatter 层级
function LuckyRacingMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parentMachine:getBounsScatterDataZorder(symbolType )

end



function LuckyRacingMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function LuckyRacingMiniMachine:checkGameResumeCallFun( )
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function LuckyRacingMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function LuckyRacingMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function LuckyRacingMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



---
-- 清空掉产生的数据
--
function LuckyRacingMiniMachine:clearSlotoData()
    
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function LuckyRacingMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function LuckyRacingMiniMachine:clearCurMusicBg( )
    
end


function LuckyRacingMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
    

    self.m_bonus_pool = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1,-1 do
            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.m_bonus_pool[#self.m_bonus_pool + 1] = symbol
            end
        end
    end

    self.m_parentView:slotReelDown()
end

--[[
    收集动画
]]
function LuckyRacingMiniMachine:runCollectAni(func)
    if #self.m_bonus_pool <= 0 then
        if type(func) == "function" then
            func()
        end
        return 
    end
    local symbol = self.m_bonus_pool[1]
    table.remove(self.m_bonus_pool,1)
    symbol:runAnim("shouji",false,function()
        if type(func) == "function" then
            func()
        end
    end)

    

    if symbol then
        local csbNode = util_createAnimation("Socre_LuckyRacing_Bonus_1.csb")
        symbol:addChild(csbNode,90)
        csbNode:runCsbAction("shouji2",false,function()
            csbNode:removeFromParent()
        end)
    end
end


--[[
    刷新小块
]]
function LuckyRacingMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType    --信号类型
    local reelNode = node
    if symbolType and symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then    --Bouns信号
        if not node.m_csbNode then
            local csbNode = util_createAnimation("Socre_LuckyRacing_Bonus_1.csb")
            node.m_csbNode = csbNode
            node:addChild(csbNode,100)
        end
        node.m_csbNode:setVisible(true)
        self:setSpecialNodeScore(node)
    else
        if node.m_csbNode then
            node.m_csbNode:setVisible(false)
        end
        for index = 1,4 do
            local tempNode = node:getCcbProperty("tieti_"..(index - 1))
            if tempNode then
                tempNode:setVisible(self.m_machineIndex == index)
            end
            
        end
        
    end
end

--[[
    设置特殊小块分数
]]
function LuckyRacingMiniMachine:setSpecialNodeScore(node)
    local symbolNode = node
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 1
    --判断是否为真实数据
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --获取真实分数
        local storedIcons = selfData.positionScore
        if storedIcons and next(storedIcons) then
            score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) or 1
        end
        
    else
        --设置假滚Bonus,随机分数
        score = self:randomDownSymbolScore(symbolNode.p_symbolType)
        if score == nil then
            score = 1
        end
        -- local lineBet = globalData.slotRunData:getCurTotalBet()
        -- score = score * lineBet
    end

    if score and type(score) ~= "string" then
        -- --格式化字符串
        score = util_formatCoins(score, 3)
        if symbolNode then
            symbolNode.m_score = score
            local lbl_score = symbolNode.m_csbNode:findChild("font")
            if lbl_score then
                lbl_score:setString("X"..score)
                self:updateLabelSize({label=lbl_score,sx=1,sy=1},186)
            end
        end
    end
end

--[[
    获取小块真实分数
]]
function LuckyRacingMiniMachine:getSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.positionScore

    local mutipleList = self.m_runSpinResultData.p_selfMakeData.multipleList

    local mutiple = mutipleList[#mutipleList]
    table.remove(mutipleList,#mutipleList,1)
    return mutiple
    -- return storedIcons[tostring(id)]
end

--[[
    随机bonus分数
]]
function LuckyRacingMiniMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        score = self.m_parentMachine.m_configData:getBnBasePro(1)
    end

    return score
end

--播放提示动画
function LuckyRacingMiniMachine:playReelDownTipNode(slotNode)

    -- self:playScatterBonusSound(slotNode)
    slotNode:runAnim("buling")
    if slotNode.m_csbNode then
        slotNode.m_csbNode:runCsbAction("buling")
    end
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

---
-- 每个reel条滚动到底
function LuckyRacingMiniMachine:slotOneReelDown(reelCol)
    LuckyRacingMiniMachine.super.slotOneReelDown(self,reelCol)
    self.m_parentView:slotOneReelDown(self.m_machineIndex,reelCol)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function LuckyRacingMiniMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "LuckyRacingSounds/sound_LuckyRacing_scatter_tip.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end


return LuckyRacingMiniMachine
