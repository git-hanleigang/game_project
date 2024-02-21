---
-- xcyy
-- 2018-12-18 
-- PussMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotParentData = require "data.slotsdata.SlotParentData"

local PussMiniMachine = class("PussMiniMachine", BaseMiniMachine)

PussMiniMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
PussMiniMachine.SYMBOL_SCORE_WILD_CAT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 
PussMiniMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
PussMiniMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1


PussMiniMachine.gameResumeFunc = nil
PussMiniMachine.gameRunPause = nil
PussMiniMachine.m_flyWildList = {}





-- 构造函数
function PussMiniMachine:ctor()
    BaseMiniMachine.ctor(self)
 
end

function PussMiniMachine:initData_( data )

    self.m_isOnceClipNode = false 
    
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_parent = data.parent 
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    self.m_flyWildList = {}

    --init
    self:initGame()
end

function PussMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function PussMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Puss"
end

function PussMiniMachine:getlevelConfigName( )
    local levelConfigName = "LevelPussMiniConfig.lua"

    return levelConfigName

end

function PussMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function PussMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_Puss_FixBonus"

    elseif symbolType == self.SYMBOL_SCORE_WILD_CAT then
        return "Socre_Puss_Wild_Cat"

    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Puss_10"
    end

    return ccbName
end

---
-- 读取配置文件数据
--
function PussMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),self:getlevelConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function PussMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("Puss/GameScreenPuss_One.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function PussMiniMachine:initMachine()
    self.m_moduleName = "Puss" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function PussMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_WILD_CAT,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function PussMiniMachine:addSelfEffect()
    

        -- -- 添加 fast赢钱弹板
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 2
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.EFFECT_TYPE_FAST_WIN
    
end


function PussMiniMachine:MachineRule_playSelfEffect(effectData)
    

    return true
end

-- 设置自定义游戏事件
function PussMiniMachine:restSelfEffect( selfEffect )
    for i = 1, #self.m_gameEffects , 1 do

        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            
            effectData.p_isPlay = true
            self:playGameEffect()

            break
        end
        
    end
    
end



function PussMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function PussMiniMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下 连线时通知钱数更新的接口

    if self.m_parent.m_runSpinResultData.p_winLines and #self.m_parent.m_runSpinResultData.p_winLines > 0 then
        
    else
        local winLines = self.m_reelResultLines

        if #winLines <= 0  then
            return
        end
        -- 如果freespin 未结束，不通知左上角玩家钱数量变化
        local isNotifyUpdateTop = true
        if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            isNotifyUpdateTop = false
        end 
    
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_iOnceSpinLastWin,isNotifyUpdateTop})
    end
    


end


-- 是不是 respinBonus小块
function PussMiniMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return true
    end
    return false
end

---
-- 每个reel条滚动到底
function PussMiniMachine:slotOneReelDown(reelCol)
    BaseMiniMachine.slotOneReelDown(self,reelCol)

    --local isplay= true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[k][reelCol]
            if symbolType and self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true then
            
            -- respinbonus落地音效
            -- gLobalSoundManager:playSound("PussSounds/music_Puss_fall_" .. reelCol ..".mp3") 
        end
    end

end

function PussMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function PussMiniMachine:reelDownNotifyChangeSpinStatus()
  
    if self.m_parent then
        self.m_parent:slotReelDownInFS()
    end 
    
end

function PussMiniMachine:quicklyStopReel(colIndex)

    if self.m_parent:isSevenRowsFreespin(  ) then
        BaseMiniMachine.quicklyStopReel(self, colIndex) 
    end
    
end

function PussMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function PussMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function PussMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function PussMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function PussMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function PussMiniMachine:enterLevelMiniSelf( )

    
    
end



function PussMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end


-- 处理特殊关卡 遮罩层级
function PussMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function PussMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end


function PussMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function PussMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function PussMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function PussMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end


function PussMiniMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    
end

function PussMiniMachine:netBackReelsStop( )
    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end



function PussMiniMachine:runFlyWildAct( flyWildList,func)

    for i=1,#flyWildList do
        local endNode = flyWildList[i]

        local flytime = 1
        -- 创建粒子
        local flyLizi =  util_createAnimation("Socre_Puss_fly_lizi.csb")
        self.m_root:addChild(flyLizi,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)
        flyLizi:findChild("Particle_1"):setDuration(flytime)
        flyLizi:findChild("Particle_1"):setPositionType(0)

        flyLizi:setPosition(cc.p(150,340))

        local liziWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(endNode:getPosition()))
        local liziPos = self:findChild("root"):convertToNodeSpace(cc.p(liziWorldPos))
        local endPos = cc.p(liziPos)


        self:flySpecialNode(flyLizi,cc.p(150,340),endPos,flytime,function(  )
            local flyLiziBaoZha =  util_createAnimation("Socre_Puss_Symbol_baozha.csb")
            self.m_root:addChild(flyLiziBaoZha,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
            local liziBaoZhaWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(endNode:getPosition()))
            local lizibaozhaPos = self:findChild("root"):convertToNodeSpace(cc.p(liziBaoZhaWorldPos))
            flyLiziBaoZha:setPosition(cc.p(lizibaozhaPos))

            flyLiziBaoZha:playAction("actionframe",false,function(  )
                if i == 1 then
                    if func then
                        func()
                    end
                end
    
                flyLiziBaoZha:removeFromParent()
                flyLizi:removeFromParent()
            end)

            local endWild = endNode
            performWithDelay(flyLiziBaoZha,function(  )
                endWild:setVisible(true)
            end,0.1)
        end)

        -- local actionList = {}
        -- actionList[#actionList + 1] = cc.MoveTo:create(flytime,endPos)
        -- actionList[#actionList + 1] = cc.DelayTime:create(flytime/2)
        -- actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            
        --     local flyLiziBaoZha =  util_createAnimation("Socre_Puss_Symbol_baozha.csb")
        --     self.m_root:addChild(flyLiziBaoZha,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
        --     local liziBaoZhaWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(endNode:getPosition()))
        --     local lizibaozhaPos = self:findChild("root"):convertToNodeSpace(cc.p(liziBaoZhaWorldPos))
        --     flyLiziBaoZha:setPosition(cc.p(lizibaozhaPos))

        --     flyLiziBaoZha:playAction("actionframe",false,function(  )
        --         if i == 1 then
        --             if func then
        --                 func()
        --             end
        --         end
    
        --         flyLiziBaoZha:removeFromParent()
        --         flyLizi:removeFromParent()
        --     end)

        --     local endWild = endNode
        --     performWithDelay(flyLiziBaoZha,function(  )
        --         endWild:setVisible(true)
        --     end,0.1)
            
            
        -- end)  
        -- local sq = cc.Sequence:create(actionList)
        -- flyLizi:runAction(sq)

    end
    
end

function PussMiniMachine:restFlyWild( )
    
    for i=1,#self.m_flyWildList do
        local wild = self.m_flyWildList[i]
        if wild then
            local linePos = {}
            wild.m_bInLine = false
            wild:setLinePos(linePos)
            wild:setName("")
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
    end

    self.m_flyWildList = {}
end

function PussMiniMachine:removeFlyWild( )
    
    for i=1,#self.m_flyWildList do
        local wild = self.m_flyWildList[i]
        if wild then
            wild:removeFromParent()
            local linePos = {}
            wild.m_bInLine = false
            wild:setLinePos(linePos)
            wild:setName("")
            local symbolType = wild.p_symbolType
            self:pushSlotNodeToPoolBySymobolType(symbolType, wild)
        end
    end

    self.m_flyWildList = {}
end

function PussMiniMachine:initFlyWild( catWildPositions)

    
    self.m_flyWildList = {}

    for i=1,#catWildPositions do
        local endPos = catWildPositions[i]
        local v = endPos
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY, false)   

        if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD

            targSp:setName("FsFlyWild_"..i)

            targSp:setVisible(false)

            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
            self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_NODE_TAG)
            local position =  self:getBaseReelsTarSpPos(pos )
            targSp:setPosition(cc.p(position))

            table.insert( self.m_flyWildList, targSp )
        end

    end


    return self.m_flyWildList
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function PussMiniMachine:getBaseReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function PussMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function PussMiniMachine:changeFlyWildList( )
    
    for k,node in pairs(self.m_flyWildList) do
        local name = node:getName()
        local oldNode = self.m_clipParent:getChildByName(name)
        if oldNode then
            self.m_flyWildList[k] = oldNode
        end
    end
end

function PussMiniMachine:changeClippingRegionToFiveRows( )
    for i = 1, self.m_iReelColumnNum, 1 do

        local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
        local rect = clipNode:getClippingRegion()
        rect.height =  self.m_parent.m_m_SevenRowsLayerBegimSize
        clipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = rect.height 
            }
        )


    end
end

function PussMiniMachine:updateSevenRowsSizeY( times , oldSizeList)

    local allOver = true

    for i = 1, self.m_iReelColumnNum, 1 do

        local addSizeY = (self.m_parent.m_SevenRowsLayerMaxSize[i] - self.m_parent.m_m_SevenRowsLayerBegimSize) / (60*times)
        oldSizeList[i] = oldSizeList[i] + addSizeY

        local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
        local rect = clipNode:getClippingRegion()

        local nowSizeY = rect.height
        if nowSizeY < self.m_parent.m_SevenRowsLayerMaxSize[i] then

            clipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = oldSizeList[i]
                }
            )
            
            allOver = false
        elseif nowSizeY > self.m_parent.m_SevenRowsLayerMaxSize[i] then

            clipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = self.m_parent.m_SevenRowsLayerMaxSize[i]
                }
            )
            
            allOver = false
        end

    end

    return allOver

end

function PussMiniMachine:updateSevenRowsToFiveSizeY( times , oldSizeList)

    local allOver = true

    for i = 1, self.m_iReelColumnNum, 1 do

        local addSizeY = (self.m_parent.m_SevenRowsLayerMaxSize[i] - self.m_parent.m_m_SevenRowsLayerBegimSize) / (60*times)
        oldSizeList[i] = oldSizeList[i] - addSizeY

        local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
        local rect = clipNode:getClippingRegion()

        local nowSizeY = rect.height
        if nowSizeY > self.m_parent.m_m_SevenRowsLayerBegimSize then

            clipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = oldSizeList[i]
                }
            )
            
            allOver = false
        elseif nowSizeY < self.m_parent.m_m_SevenRowsLayerBegimSize then

            clipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = self.m_parent.m_m_SevenRowsLayerBegimSize
                }
            )
            
            allOver = false
        end

    end

    return allOver

end

--node飞行的图片或者粒子,startPos开始坐标,endPos停止坐标,flyTime飞行时间,func结束回调
function PussMiniMachine:flySpecialNode(node,startPos,endPos,flyTime,func)
    if not node then
        return
    end
    if not flyTime then
        flyTime = 1
    end
    local actionList = {}
    local tempPos = cc.p(startPos.x+100+endPos.x*0.1,startPos.y+400+endPos.y*0.1)
    local bez1=cc.BezierTo:create(flyTime*0.5,{cc.p(startPos.x+500,startPos.y),cc.p(startPos.x+300,tempPos.y),tempPos})
    actionList[#actionList + 1] = bez1
    local bez2=cc.BezierTo:create(flyTime*0.5,{cc.p(tempPos.x-300,(startPos.y+tempPos.y)*0.5),cc.p(tempPos.x-100,(startPos.y+tempPos.y)*0.5),endPos})
    actionList[#actionList + 1] = bez2
    if func then
        actionList[#actionList + 1] = cc.CallFunc:create(func)
    end
    node:runAction(cc.Sequence:create(actionList))
end

function PussMiniMachine:playEffectNotifyChangeSpinStatus( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Auto,true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            -- {SpinBtn_Type.BtnType_Auto,true})
            -- globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            -- if self.m_handerIdAutoSpin == nil then
            --     self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            --         self:normalSpinBtnCall()
            --     end, 0.5,self:getModuleName())
            -- end
        else
            if self.m_parent.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,true})
            end
        end
    end
end

return PussMiniMachine
