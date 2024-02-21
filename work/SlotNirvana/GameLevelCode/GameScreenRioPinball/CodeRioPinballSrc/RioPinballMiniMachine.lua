---
-- xcyy
-- 2018-12-18 
-- RioPinballMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local RioPinballMiniMachine = class("RioPinballMiniMachine", BaseMiniMachine)

local BALL_MOVE_SPEED = 1040        --小球运动速度
local SYMBOL_WIDTH = 180
local SYMBOL_HEIGHT = 130
local LIGHT_POINT_WIDTH = 30

local BALL_SCALE    =       0.8     --小球缩放

local BALL_WIDTH    =   64  --小球宽度

RioPinballMiniMachine.m_machineIndex = nil -- csv 文件模块名字

RioPinballMiniMachine.gameResumeFunc = nil
RioPinballMiniMachine.gameRunPause = nil


local LBL_WIDTH = {211,211,211}
local LBL_SCALES = {0.6,0.65,0.7}


local Main_Reels = 1

local BALL_COUNT = {4,3,2,1}


-- 构造函数
function RioPinballMiniMachine:ctor()
    RioPinballMiniMachine.super.ctor(self)

    self.m_routeListPointData = {}
end

function RioPinballMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil
    self.m_bonusData = nil
    self.m_isCorner = false

    

    self.m_machine = data.machine
    self.m_parentView = data.parentView

    self.m_winCoins = 0


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function RioPinballMiniMachine:resetWinCoins(coins)
    self.m_winCoins = coins
end

function RioPinballMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function RioPinballMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RioPinball"
end

function RioPinballMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function RioPinballMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function RioPinballMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
end

function RioPinballMiniMachine:initMachineCSB( )

    self:createCsbNode("RioPinball/BonusGameScreen.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    --特效层
    self.m_effectNode = self:findChild("node_effect")
    self.m_effectNode:setScale(1)

    self.m_effectNode2 = cc.Node:create()
    self:findChild("Root"):addChild(self.m_effectNode2, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    --左右两侧挡板,前8个在左边,后8个在右边,顺序由上到下
    self.m_dangBanAry = {}
    self.m_lightPoints = {}
    for index = 1,16 do
        local item = util_createAnimation("RioPinball_dangban.csb")
        self:findChild("dangban"..index):addChild(item)
        self.m_dangBanAry[index] = item
        item:setVisible(false)

        local lightPoint = util_createAnimation("RioPinball_deng.csb")
        self:findChild("Node_"..index):addChild(lightPoint)
        self.m_lightPoints[index] = lightPoint
    end

    self.m_round_tip = util_createAnimation("RioPinball_round.csb")
    self:findChild("round"):addChild(self.m_round_tip)

    self.m_spine_ball_count = util_spineCreate("banzi",true,true)
    util_spinePlay(self.m_spine_ball_count,"idle",true)
    self.m_spine_ball_count:setVisible(false)
    self:findChild("ballgeshu"):addChild(self.m_spine_ball_count)

    self.m_left_ball_count = util_createAnimation("RioPinball_ballgeshu.csb")
    util_spinePushBindNode(self.m_spine_ball_count,"shuzi",self.m_left_ball_count)

    --发射口
    self.m_launchPort = {}
    self.m_jianTou = {}
    for index = 1,2 do
        local port = util_createAnimation("RioPinball_fashekou.csb")
        self:findChild("fashekou"..index):addChild(port)
        self.m_launchPort[index] = port

        local jiantou = util_createAnimation("RioPinball_jiantou.csb")
        self.m_jianTou[index] = jiantou
        jiantou:runCsbAction("idle1")
        self:findChild("jiantou"..index):addChild(jiantou)
    end

    
    
end

function RioPinballMiniMachine:showColorLayer( )
    self.m_layerColor:setVisible(true)
    self.m_layerColor:setOpacity(0)
    
    self.m_layerColor:runAction(cc.FadeTo:create(0.1,math.floor(255 * 0.7)))
end

function RioPinballMiniMachine:hideColorLayer( )
    self.m_layerColor:setVisible(true)
    self.m_layerColor:runAction(cc.FadeTo:create(0.1,0))
    self.m_machine:delayCallBack(0.1,function()
        self.m_layerColor:setVisible(false)
    end)
end

--
---
--
function RioPinballMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    RioPinballMiniMachine.super.initMachine(self)

    --压黑层
    self.m_layerColor = self:findChild("Panel_2")
    local pos = util_convertToNodeSpace(self.m_layerColor,self.m_onceClipNode)
    util_changeNodeParent(self.m_onceClipNode,self.m_layerColor,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10000)
    self.m_layerColor:setPosition(pos)
    self.m_layerColor:setVisible(false)
end

----------------------------- 玩法处理 -----------------------------------

function RioPinballMiniMachine:addSelfEffect()


    -- -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 7
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
 
end


function RioPinballMiniMachine:MachineRule_playSelfEffect(effectData)
    return true
end




function RioPinballMiniMachine:onEnter()
    self.m_isEntered = true
    RioPinballMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:resetView()
end



function RioPinballMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function RioPinballMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function RioPinballMiniMachine:quicklyStopReel(colIndex)


end

function RioPinballMiniMachine:onExit()
    RioPinballMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    util_spineRemoveBindNode(self.m_spine_ball_count,self.m_left_ball_count)

    util_resetChildReferenceCount(self.m_effectNode)
    util_resetChildReferenceCount(self.m_effectNode2)

end

function RioPinballMiniMachine:removeObservers()
    RioPinballMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function RioPinballMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
end


function RioPinballMiniMachine:beginMiniReel()
     
end


-- 消息返回更新数据
function RioPinballMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

end

function RioPinballMiniMachine:enterLevel( )
    RioPinballMiniMachine.super.enterLevel(self)
end

function RioPinballMiniMachine:enterLevelMiniSelf( )

    RioPinballMiniMachine.super.enterLevel(self)
    
end

function RioPinballMiniMachine:dealSmallReelsSpinStates( )
    
end



-- 处理特殊关卡 遮罩层级
function RioPinballMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function RioPinballMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_machine:getBounsScatterDataZorder(symbolType )
end


function RioPinballMiniMachine:checkGameResumeCallFun( )
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

function RioPinballMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function RioPinballMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function RioPinballMiniMachine:resumeMachine()
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
function RioPinballMiniMachine:clearSlotoData()

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
function RioPinballMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function RioPinballMiniMachine:clearCurMusicBg( )
    
end

--[[
    刷新小块
]]
function RioPinballMiniMachine:updateReelGridNode(node)
    if not self.m_bonusData then
        return
    end

    local reels = self.m_bonusData.reels
    local creditReels = self.m_bonusData.creditReels
    if not creditReels then
        creditReels = self.m_bonusData.newCreditReels
    end
    local highLimit = self.m_bonusData.highLimit

    local colIndex = node.p_cloumnIndex
    local rowIndex = self.m_iReelRowNum - (node.p_rowIndex - 1)

    --获取目标信号值
    local symbolType = reels[rowIndex][colIndex]
    node.isChange = false
    if node.p_symbolType ~= symbolType then
        local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine,symbolType)
        node:changeCCBByName(ccbName, symbolType)
        node.p_symbolType = symbolType
        node.isChange = true
    end

    node.limitIndex = 1
    node.m_score = 0

    node:setVisible(true)

    if symbolType == self.m_machine.SYMBOL_BONUS_EMPTY then
        node:setVisible(false)
    elseif symbolType == self.m_machine.SYMBOL_BONUS_4 then
        --获取当前下注
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local multiple = creditReels[rowIndex][colIndex]
        local score = lineBet * multiple
        node.m_score = score
        score = util_formatCoins(score, 3)
        

        local limitIndex = 1
        if multiple >= highLimit[1] and multiple < highLimit[2] then
            limitIndex = 2
        elseif multiple >= highLimit[2] then
            limitIndex = 3
        end

        node.limitIndex = limitIndex
        
        for index = 1,3 do
            local lbl = node:getCcbProperty("lbl_score_"..index)
            lbl:setString(score)
            lbl:setVisible(limitIndex == index)
            self:updateLabelSize({label=lbl,sx=LBL_SCALES[index],sy=LBL_SCALES[index]},LBL_WIDTH[index])

            node:getCcbProperty("Sprite_"..index):setVisible(limitIndex == index)
        end

        if limitIndex == 3 then
            if not node.m_isIdle then
                node:runAnim("idle",true)
                node.m_isIdle = true
            end
        else
            node:runAnim("idle1")
            node.m_isIdle = false
        end
        
        
        
    elseif symbolType == self.m_machine.SYMBOL_BONUS_2 or symbolType == self.m_machine.SYMBOL_BONUS_3 then
        local roundIndex = self:getCurRoundIndex()
        node.limitIndex = 2
        if roundIndex == 1 then
            node:runAnim("idle",true)
        elseif roundIndex == 2 then
            node:runAnim("idle2x",true)
        elseif roundIndex == 3 then
            node:runAnim("idle3x",true)
        elseif roundIndex == 4 then
            node:runAnim("idle5x",true)
        end
        node.m_isIdle = true
    end
end

--[[
    变更新轮盘
]]
function RioPinballMiniMachine:changeNewReel()
    self.m_bonusData.creditReels = self.m_bonusData.newCreditReels
    self.m_bonusData.newCreditReels = nil
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            if self.m_bonusData.reels[iRow][iCol] == self.m_machine.SYMBOL_BONUS_EMPTY then
                self.m_bonusData.reels[iRow][iCol] = self.m_machine.SYMBOL_BONUS_4
            end
        end
    end
    self:refreshReelsByData()
end

--[[
    获取当前轮数
]]
function RioPinballMiniMachine:getCurRoundIndex()
    return self.m_parentView.m_curRound
end

--[[
    刷新轮盘
]]
function RioPinballMiniMachine:refreshReelsByData()
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
            if symbol then
                self:updateReelGridNode(symbol)
                if symbol.isChange then
                    symbol:setVisible(false)
                end
            end
        end
    end
end

--[[
    设置bonus数据
]]
function RioPinballMiniMachine:setBonusData(data)
    self.m_bonusData = data
end

--[[
    获取两个路径点的小块差值
]]
function RioPinballMiniMachine:getSymbolCountByRouteData(pointData,prePointData)
    local symbolCount = 0
    if pointData[3] == "LEFT" then
        symbolCount = prePointData[2] - pointData[2] 
    elseif pointData[3] == "RIGHT" then
        symbolCount = pointData[2] - prePointData[2]
        
    elseif pointData[3] == "UP" then
        symbolCount = prePointData[1] - pointData[1]
    else
        symbolCount = pointData[1] - prePointData[1] 
    end
    return symbolCount
end

--[[
    展示路径
]]
function RioPinballMiniMachine:showRouteList(func)
    local allRoad = self.m_bonusData.roadSet

    --高亮路线
    local highLightRoad = self.m_bonusData.highlightRoad
    local hitRoad = self.m_bonusData.effectRoad
    local hitRoadData = allRoad[hitRoad + 1]

    local endIndex = #highLightRoad
    local routeList = {}
    
    for index = 1,#highLightRoad do
        if highLightRoad[index] == hitRoad then
            endIndex = endIndex + index
            
        end

        local roadData = allRoad[highLightRoad[index] + 1]
        local road = roadData.road
        local corner = roadData.corner
        local lightPoints = {}

        for index = 1,#corner do
            local cornerData = corner[index]
            --前一个拐角数据
            local preData = corner[index - 1]
            --后一个拐角数据
            local nextData = corner[index + 1]
            local pointData = road[cornerData[1] + 1]
            local prePointData,nextPointData = nil,nil

            if preData then
                prePointData = road[preData[1] + 1]
            end

            if nextData then
                nextPointData = road[nextData[1] + 1]
            end
            
            local point = self:getRoutePoint(prePointData,nextPointData,pointData,cornerData,corner)

            self.m_effectNode2:addChild(point)
            lightPoints[#lightPoints + 1] = point
            --获取转角位置的小块
            local colIndex = pointData[2] + 1
            local rowIndex = self.m_iReelRowNum - pointData[1]
            local symbol = self:getFixSymbol(colIndex,rowIndex, SYMBOL_NODE_TAG)
            if symbol then
                point:setPosition(util_convertToNodeSpace(symbol,self.m_effectNode2))
            end
        end

        --最后的路径线
        local lastCornerData = corner[#corner]
        local lastCornerPoint = nil
        if lastCornerData then
            lastCornerPoint = road[lastCornerData[1] + 1]
        end
        local lastPoint = self:getRoutePoint(lastCornerPoint,nil,road[#road],nil,corner)
        self.m_effectNode2:addChild(lastPoint)
        lightPoints[#lightPoints + 1] = lastPoint
        local colIndex = road[#road][2] + 1
        local rowIndex = self.m_iReelRowNum - road[#road][1]
        local symbol = self:getFixSymbol(colIndex,rowIndex, SYMBOL_NODE_TAG)
        if symbol then
            lastPoint:setPosition(util_convertToNodeSpace(symbol,self.m_effectNode2))
        end

        local startIndex = 1
        if road[1][2] == 0 then
            startIndex = road[1][1] + 1
        else
            startIndex = road[1][1] + self.m_iReelRowNum + 1
        end
        routeList[index] = {
            lightPoints = lightPoints,
            roadIndex = highLightRoad[index],
            startIndex = startIndex,
            road = road
        }
    end

    self.m_routeListPointData = routeList

    self:showColorLayer()
    self:showRouteByRound(routeList,1,endIndex,function()

        if #hitRoadData.road == 10 then
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_wonderful_route.mp3")
        elseif #hitRoadData.road > 10 then
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_Road_to_wealth.mp3")
        end

        if type(func) == 'function' then
            func()
        end
    end)
end

--[[
    将所有小块放回普通层
]]
function RioPinballMiniMachine:changeParentToNormal()
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
            if symbol then
                symbol:changeParentToBaseNode()
            end
        end
    end
end

--[[
    将路径上的小块放到大信号层
]]
function RioPinballMiniMachine:changeParentToBig(road)
    for k,pointData in pairs(road) do
        local iCol = pointData[2] + 1
        local iRow = self.m_iReelRowNum - pointData[1]
        local symbol = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
        if symbol then
            symbol:changeParentToTopNode()
        end
    end
end

--[[
    获取路径点
]]
function RioPinballMiniMachine:getRoutePoint(preData,nextData,pointData,cornerData,cornerList)
    local point = util_createAnimation("RioPinball_diandian.csb")
    --转角小块距离边缘位置
    local distance = 0
    local symbolCount = 0
    local point_width = LIGHT_POINT_WIDTH
    if pointData[3] == "LEFT" then
        point:setRotation(0)
        if not preData then
            symbolCount = self.m_iReelColumnNum - pointData[2]
            distance = (SYMBOL_WIDTH / 2) * symbolCount - (SYMBOL_WIDTH / 4)
        else
            symbolCount = self:getSymbolCountByRouteData(pointData,preData)
            distance = (SYMBOL_WIDTH / 2) * symbolCount
        end
        
        
    elseif pointData[3] == "RIGHT" then
        point:setRotation(180)
        if not preData then
            symbolCount = pointData[2] + 1
            distance = (SYMBOL_WIDTH / 2) * symbolCount - (SYMBOL_WIDTH / 4)
        else
            symbolCount = self:getSymbolCountByRouteData(pointData,preData)
            distance = (SYMBOL_WIDTH / 2) * symbolCount
        end
        
    elseif pointData[3] == "UP" then
        point:setRotation(90)
        if not preData then
            symbolCount = self.m_iReelRowNum - pointData[1]
            distance = (SYMBOL_HEIGHT / 2) * symbolCount - (SYMBOL_WIDTH / 4)
        else
            symbolCount = self:getSymbolCountByRouteData(pointData,preData)
            distance = (SYMBOL_HEIGHT / 2) * symbolCount
        end
        
        point_width = LIGHT_POINT_WIDTH
    else
        point:setRotation(-90)
        if not preData then
            symbolCount = pointData[1] + 1
            distance = (SYMBOL_HEIGHT / 2) * symbolCount - (SYMBOL_WIDTH / 4)
        else
            symbolCount = self:getSymbolCountByRouteData(pointData,preData)
            distance = (SYMBOL_HEIGHT / 2) * symbolCount
        end
        
        point_width = LIGHT_POINT_WIDTH
    end
    

    --计算需要多少个点
    local pointCount = math.floor((distance + point_width * 0.4) / point_width) 
    if not preData then
        pointCount = pointCount + 1
    end
 
    local curRoundIndex = self:getCurRoundIndex()
    --获取当前路径所需字符
    local characterList = {".","B","P","Y"}
    local str = ""
    local character = characterList[curRoundIndex]
    if #cornerList == 0 or curRoundIndex == 1 then
        for index = 1,pointCount do
            str = str.."."
        end
    elseif cornerData and not preData then  --有拐角数据且没有前一个拐点的数据,说明是第一个拐点
        str = str..character
        for index = 2,pointCount do
            str = str.."."
        end
        
    else
        for index = 1,pointCount do
            str = str..character
        end
    end
    

    local offsetX = LIGHT_POINT_WIDTH
    if not cornerData then
        offsetX = offsetX + LIGHT_POINT_WIDTH / 2
    end

    point:findChild("m_lb_num"):setString(str)
    point:findChild("m_lb_num"):setPositionX(-LIGHT_POINT_WIDTH)

    return point
end

--[[
    轮流展示路径
]]
function RioPinballMiniMachine:showRouteByRound(routeList,index,endIndex,func)
    

    if index > endIndex then
        if type(func) == "function" then
            func()
        end
        return
    end

    --隐藏所有点
    for k,data in pairs(routeList) do
        for k2,point in pairs(data.lightPoints) do
            if point:isVisible() then
                point:setVisible(false)
            end
        end
    end
    

    for k,lightPoint in pairs(self.m_lightPoints) do
        lightPoint:setVisible(false)
    end

    --把所有小块放回普通层
    self:changeParentToNormal()

    local curIndex = index % (#routeList)
    if curIndex == 0 then
        curIndex = #routeList
    end
    local routeData = routeList[curIndex]

    self:changeParentToBig(routeData.road)

    

    local lightPoint = self.m_lightPoints[routeData.startIndex]
    lightPoint:setVisible(true)
    lightPoint:runCsbAction("idle")
    local time = 0.5 - 0.05 * (index - 1)

    self.m_machine:delayCallBack(time,function()
        lightPoint:setVisible(false)
        self:showRouteByRound(routeList,index + 1,endIndex,func)
    end)

    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_line.mp3")
    for k,point in pairs(routeData.lightPoints) do
        point:setVisible(true)
    end
end

--[[
    小球移动动作
]]
function RioPinballMiniMachine:ballMoveAction(func)
    local allRoad = self.m_bonusData.roadSet
    local hitRoad = self.m_bonusData.effectRoad
    self.m_machine.m_effectNode2:removeAllChildren()

    self.m_machine:hideTotalWinLight()

    self.m_isCorner = false
    local alreadyChange = false

    local changeTail = false

    --路径信息
    local roadData = allRoad[hitRoad + 1].road
    local cornerList = allRoad[hitRoad + 1].corner
    local lastDirection = allRoad[hitRoad + 1].lastDirection

    local reels = self.m_runSpinResultData.p_reels

    -- local str_road = json.encode(roadData)
    -- local str_cornerList = json.encode(cornerList)
    -- local str_reels = json.encode(reels)

    -- print("road = "..str_road)
    -- print("corner = "..str_cornerList)
    -- print("reels = "..str_reels)

    --小球
    local ball = util_createAnimation("RioPinball_qiu.csb")
    ball:findChild("Particle_1"):setVisible(false)
    self.m_effectNode:addChild(ball)
    ball:setScale(BALL_SCALE)

    --拖尾粒子
    local lizi = util_createAnimation("RioPinball_bonus_lizi.csb")
    ball:findChild("node_tail"):addChild(lizi)
    for index = 1,4 do
        local particle = lizi:findChild("Particle_"..index)
        if index == 1 then
            particle:setVisible(true)
            particle:setPositionType(0)
            particle:setDuration(-1)
        else
            particle:setVisible(false)
            particle:stopSystem()
        end
    end
    ball.m_lizi = lizi

    local routeList = {}

    local startSymbol = self:getFixSymbol(roadData[1][2] + 1,self.m_iReelRowNum - roadData[1][1],SYMBOL_NODE_TAG)
    local startSymbolPos = util_convertToNodeSpace(startSymbol,self.m_effectNode)

    --前一个点的位置
    local prePos,startPos = nil,nil
    local isLeft = false

    --从左侧进入
    local startIndex = 1
    local launchPort = self.m_launchPort[1]
    local jiantou = self.m_jianTou[1]
    if roadData[1][2] == 0 then
        startPos = util_convertToNodeSpace(self:findChild("qiu1"),self.m_effectNode)
        ball:setPosition(startPos)  
        isLeft = true

        startIndex = roadData[1][1] + 1

    else --从右侧进入
        launchPort = self.m_launchPort[2]
        jiantou = self.m_jianTou[2]
        startPos = util_convertToNodeSpace(self:findChild("qiiu2"),self.m_effectNode)
        ball:setPosition(startPos) 

        startIndex = roadData[1][1] + self.m_iReelRowNum + 1
    end

    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_send_out_fs.mp3")
    routeList = { --路径列表
        {
            startPos = startPos,
            speed = BALL_MOVE_SPEED,
            endPos = cc.p(startPos.x,startSymbolPos.y),     --终点位置
            endFunc = function()
                self.m_dangBanAry[startIndex]:runCsbAction("actionframe")
                gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_hit_board.mp3")
                if isLeft then
                    ball:setRotation(180)
                else
                    ball:setRotation(90)
                end
            end
        }
    }
    prePos = cc.p(startPos.x,startSymbolPos.y)

    --碰到挡板慢放动作
    local isSlowly = false
    --根据服务器数据插入路径
    for iRoad = 1,#roadData do
        local data = roadData[iRoad]
        local symbolNode = self:getFixSymbol(data[2] + 1,self.m_iReelRowNum - data[1], SYMBOL_NODE_TAG)
        if symbolNode then
            
            local symbolPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)

            local distance = cc.pGetDistance(prePos, symbolPos)
            local delayFuncTime = distance / BALL_MOVE_SPEED
            if symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_2 or symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_3 then
                delayFuncTime = delayFuncTime - 0.049
            end
            
            routeList[#routeList + 1] = {
                startPos = prePos,
                speed = BALL_MOVE_SPEED,
                endPos = symbolPos,
                isSlowly = isSlowly,
                slowlyRate = 0.16,
                delayFuncTime = delayFuncTime,
                delayFunc = function()
                    if data[3] == "DOWN" then 
                        ball:setRotation(180)
                    elseif data[3] == "UP" then
                        ball:setRotation(0)
                    elseif data[3] == "RIGHT" then
                        ball:setRotation(90)
                    else
                        ball:setRotation(-90)
                    end
                    if symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_2 or symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_3 then
                        

                        local roundIndex = self:getCurRoundIndex()
                        if symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_2 then
                            if data[3] == "DOWN" or data[3] == "RIGHT" then
                                symbolNode:runAnim("actionframe"..(1 + (roundIndex - 1) * 2))
                                --往下走的小球会转向左,向右走的小球会转向上
                                if data[3] == "DOWN" then
                                    ball:setRotation(-90)
                                else
                                    ball:setRotation(0)
                                end
                            else
                                symbolNode:runAnim("actionframe"..(2 + (roundIndex - 1) * 2))
                                 --向上走的小球会转向右侧,向左走的小球会转向下
                                 if data[3] == "LEFT" then
                                    ball:setRotation(180)
                                else
                                    ball:setRotation(90)
                                end
                            end

                            
                        elseif symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_3 then
                            if data[3] == "DOWN" or data[3] == "LEFT" then
                                symbolNode:runAnim("actionframe"..(1 + (roundIndex - 1) * 2))
                                --往下走的小球会转向右,向左走的小球会转向上
                                if data[3] == "DOWN" then
                                    ball:setRotation(90)
                                else
                                    ball:setRotation(0)
                                end
                            else
                                --往上走的小球会转向左,向右走的小球会转向下
                                if data[3] == "UP" then
                                    ball:setRotation(-90)
                                else
                                    ball:setRotation(180)
                                end
                                symbolNode:runAnim("actionframe"..(2 + (roundIndex - 1) * 2))
                            end
                        end
                        
                        
                        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_hit_board.mp3")
                        changeTail = true
                        self.m_isCorner = true
                    else
                        if symbolNode.limitIndex == 2 then
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_amazing.mp3")
                        elseif symbolNode.limitIndex == 3 then
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_unbelievable.mp3")
                        end
                    end
                    
                    
                    self:collectWinCoins(symbolNode,iRoad == #roadData)

                    if symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS_4 then
                        local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_BONUS_EMPTY)
                        symbolNode:changeCCBByName(ccbName, self.m_machine.SYMBOL_BONUS_EMPTY)
                        symbolNode:setVisible(false)
                        symbolNode.p_symbolType = self.m_machine.SYMBOL_BONUS_EMPTY
                    end
                end,
                endFunc = function ()   --结束回调 
                    
                    if changeTail and not alreadyChange then
                        changeTail = false
                        alreadyChange = true
                        local roundIndex = self:getCurRoundIndex()
                        if roundIndex ~= 1 then
                            for index = 1,4 do
                                local particle = ball.m_lizi:findChild("Particle_"..index)
                                if index == roundIndex then
                                    particle:setVisible(true)
                                    particle:resetSystem()
                                    particle:setPositionType(0)
                                    particle:setDuration(-1)
                                else
                                    particle:stopSystem()
                                end
                            end
                        end
                    end
                end
            }

            if symbolNode.limitIndex > 1 then
                isSlowly = true
            else
                isSlowly = false
            end

            prePos = symbolPos
        end
    end

    --小球移动出轮盘
    local sidePos = cc.p(prePos.x,prePos.y)
    --小球移动到轮盘外
    if lastDirection == "LEFT" then
        sidePos.x = sidePos.x - SYMBOL_WIDTH / 2 + BALL_WIDTH * BALL_SCALE
    elseif lastDirection == "RIGHT" then
        sidePos.x = sidePos.x + SYMBOL_WIDTH / 2 - BALL_WIDTH * BALL_SCALE
    elseif lastDirection == "UP" then
        sidePos.y = sidePos.y + SYMBOL_HEIGHT / 2 - BALL_WIDTH * BALL_SCALE 
    else
        sidePos.y = sidePos.y - SYMBOL_HEIGHT / 2 + BALL_WIDTH * BALL_SCALE
    end

    routeList[#routeList + 1] = {
        startPos = prePos,
        speed = BALL_MOVE_SPEED,
        endPos = sidePos,
        isSlowly = isSlowly,
        endFunc = function()

            local endPos = cc.p(sidePos.x,sidePos.y)
            --小球碎裂
            ball:findChild("Particle_1"):setVisible(true)
            ball:findChild("Particle_1"):resetSystem()
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_over.mp3")
            ball:runCsbAction("over",false,function()
                
            end)

            for index = 1,4 do
                local particle = ball.m_lizi:findChild("Particle_"..index)
                particle:stopSystem()
            end

            self:hideColorLayer()
            
            self:hideDangBanAct(isLeft,function()

                self.m_machine:delayCallBack(2,function()
                    ball:removeFromParent()
                    if type(func) == "function" then
                        func()
                    end
                end)
                
            end)
        end
    }

    self:showDangBanAct(isLeft,function()

        --隐藏所有点
        for k,data in pairs(self.m_routeListPointData) do
            for k2,point in pairs(data.lightPoints) do
                point:removeFromParent()
            end
        end

        self.m_routeListPointData = {}
        

        for k,lightPoint in pairs(self.m_lightPoints) do
            lightPoint:setVisible(false)
        end
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_jiantou.mp3")
        jiantou:runCsbAction("actionframe1",false,function()
            launchPort:runCsbAction("actionframe")
            util_moveByRouteList(ball,routeList)
        end)
        
    end)
end

--[[
    显示挡板动画
]]
function RioPinballMiniMachine:showDangBanAct(isLeft,func)
    if isLeft then
        self:runCsbAction("actionframe1_L",false,func)
        for index = 1,8 do
            self.m_dangBanAry[index]:setVisible(true)
        end
    else
        self:runCsbAction("actionframe1_R",false,func)
        for index = 8,16 do
            self.m_dangBanAry[index]:setVisible(true)
        end
    end
    
end

--[[
    隐藏挡板动画
]]
function RioPinballMiniMachine:hideDangBanAct(isLeft,func)
    local endFunc = function()
        for index = 1,16 do
            self.m_dangBanAry[index]:setVisible(false)
        end
        if type(func) == "function" then
            func()
        end
    end
    if isLeft then
        self:runCsbAction("actionframe2_L",false,endFunc)
    else
        self:runCsbAction("actionframe2_R",false,endFunc)
    end
    
end

--[[
    收集分数
]]
function RioPinballMiniMachine:collectWinCoins(symbolNode,isLast)

    local multiple = 1
    if self.m_isCorner then
        multiple = self.m_bonusData.bonusMulti[self:getCurRoundIndex()]
    end
    local temp = util_createAnimation("Socre_RioPinball_Bonus4.csb")
    self.m_machine.m_effectNode2:addChild(temp)
    temp:setPosition(util_convertToNodeSpace(symbolNode,self.m_machine.m_effectNode2))
    local endPos = util_convertToNodeSpace(self.m_machine.m_bottomUI.coinWinNode,self.m_machine.m_effectNode2)
    local seq = cc.Sequence:create({
        cc.DelayTime:create(15 / 60),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_collectCoins.mp3")
        end),
        cc.JumpTo:create(25 / 60,endPos,100,1),
        cc.CallFunc:create(function()
            if isLast then
                self.m_winCoins = self.m_parentView.m_bsWinCoins
            else
                self.m_winCoins = self.m_winCoins + symbolNode.m_score * multiple
            end
            
            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_winCoins))
            if temp:isVisible() then
                gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_collectCoins_feed_back.mp3")
                self.m_machine:totalWinAnim()
            end
            
        end),
        cc.Hide:create() --先隐藏在玩法结束后统一移除
    })
    temp:runAction(seq)

    if symbolNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS_4 then
        temp:setVisible(false)
        return
    end

    temp:setScale(0.5)

    

    for index = 1,4 do
        if self.m_isCorner then
            temp:findChild("Sprite_"..index):setVisible(self:getCurRoundIndex() == index)
        else
            temp:findChild("Sprite_"..index):setVisible(1 == index)
        end
    end

    for index = 1,3 do
        local lbl = temp:findChild("lbl_score_"..index)
        lbl:setVisible(symbolNode.limitIndex == index)
        lbl:setString(util_formatCoins(symbolNode.m_score, 3))
        self:updateLabelSize({label=lbl,sx=LBL_SCALES[index],sy=LBL_SCALES[index]},LBL_WIDTH[index])
        
    end

    local updateScore = function()
        local score = util_formatCoins(symbolNode.m_score * multiple, 3)
        for index = 1,3 do
            local lbl = temp:findChild("lbl_score_"..index)
            lbl:setString(score)
            self:updateLabelSize({label=lbl,sx=LBL_SCALES[index],sy=LBL_SCALES[index]},LBL_WIDTH[index])
        end
    end

    if self.m_isCorner and multiple > 1 then
        temp:runCsbAction("shouji2",false,function()
            
        end)
        self.m_machine:delayCallBack(7 / 60,updateScore)
    else
        temp:runCsbAction("change",false,function()
            temp:runCsbAction("shouji")
        end)
        -- updateScore()
    end
    
    
end

--[[
    隐藏所有小块
]]
function RioPinballMiniMachine:hideAllSymbol()
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
            if symbol then
                symbol.isChange = true
                symbol:setVisible(false)
            end
        end
    end
end

--[[
    转化挡板动画
]]
function RioPinballMiniMachine:changeBonusSymbol(func)
    local roundIndex = self:getCurRoundIndex()

    local time = 20 / 60
    local delayTime = 0

    --先转化挡板
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
            if symbol then
                symbol.m_isIdle = false
                local symbolType = symbol.p_symbolType
                if symbolType == self.m_machine.SYMBOL_BONUS_2 or symbolType == self.m_machine.SYMBOL_BONUS_3 then
                    
                    delayTime = delayTime + 0.1
                    if roundIndex == 1 then
                        time = 20 / 60
                        self.m_machine:delayCallBack(delayTime,function()
                            symbol:setVisible(true)
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_show_green.mp3")
                            symbol:runAnim("start",false,function()
                                symbol:runAnim("idle",true)
                                symbol.m_isIdle = true
                            end)
                        end)
                        
                    elseif roundIndex == 2 then
                        time = 60 / 60
                        self.m_machine:delayCallBack(delayTime,function()
                            symbol:setVisible(true)
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_show_blue.mp3")
                            symbol:runAnim("switch2x",false,function()
                                symbol:runAnim("idle2x",true)
                                symbol.m_isIdle = true
                            end)
                        end)
                        
                    elseif roundIndex == 3 then
                        time = 50 / 60
                        self.m_machine:delayCallBack(delayTime,function()
                            symbol:setVisible(true)
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_show_purple.mp3")
                            symbol:runAnim("switch3x",false,function()
                                symbol:runAnim("idle3x",true)
                                symbol.m_isIdle = true
                            end)
                        end)
                        
                    else
                        time = 50 / 60
                        self.m_machine:delayCallBack(delayTime,function()
                            symbol:setVisible(true)
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_show_yellow.mp3")
                            symbol:runAnim("switch5x",false,function()
                                symbol:runAnim("idle5x",true)
                                symbol.m_isIdle = true
                            end)
                        end)
                        
                    end
                end
            end
        end
    end

    self.m_machine:delayCallBack(time + delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    转化小块动画
]]
function RioPinballMiniMachine:changeSymbolByRound(func)

    local delayTime = 0
    --在转化普通图标
    for iCol = 1,self.m_iReelColumnNum do
        delayTime = delayTime + 0.1
        local isChange = false
        for iRow = 1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
            if symbol then
                
                symbol.m_isIdle = false
                local symbolType = symbol.p_symbolType
                if symbolType == self.m_machine.SYMBOL_BONUS_4 and symbol.isChange then
                    isChange = true
                    self.m_machine:delayCallBack(delayTime,function()
                        symbol:setVisible(true)
                        symbol:runAnim("start",false,function()
                            if symbol.limitIndex == 3 then
                                symbol:runAnim("idle",true)
                                symbol.m_isIdle = true
                            else
                                symbol:runAnim("idle1")
                                symbol.m_isIdle = false
                            end
                        end)
                    end)
                    
                elseif symbolType == self.m_machine.SYMBOL_BONUS_2 or symbolType == self.m_machine.SYMBOL_BONUS_3 then
                    symbol:setVisible(true)
                end
            end
        end
        if isChange then
            self.m_machine:delayCallBack(delayTime,function()
                gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_bonus_show.mp3")
            end)
            
        end
    end

    self.m_machine:delayCallBack(20 / 60 + delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    开始动作
]]
function RioPinballMiniMachine:startAction(func)
    for index = 1,16 do
        self.m_dangBanAry[index]:setVisible(true)
    end
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_all_dangban.mp3")
    self:runCsbAction("actionframe1",false,function()
        for index = 1,16 do
            self.m_dangBanAry[index]:setVisible(false)
        end
        if type(func) == "function" then
            func()
        end
    end)

    self.m_machine:delayCallBack(30 / 60,function()
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_refresh.mp3")
    end)
    self.m_machine:delayCallBack(105 / 60,function()
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_close.mp3")
    end)

    self.m_machine:delayCallBack(1.4,function()
        self.m_spine_ball_count:setVisible(true)
        util_spinePlay(self.m_spine_ball_count,"start")
        util_spineEndCallFunc(self.m_spine_ball_count,"start",function (  )
            util_spinePlay(self.m_spine_ball_count,"idle",true)
        end)
        self:updateBallCount()
        self:showRoundTip()
    end)
end

--[[
    更新球个数
]]
function RioPinballMiniMachine:updateBallCount(isRefreshRound,func)

    local ballProcess = self.m_bonusData.ballProcess
    local roundIndex = self:getCurRoundIndex()
    

    if isRefreshRound then
        self.m_left_ball_count:runCsbAction("actionframe",false,func)
        self.m_machine:delayCallBack(10 / 60,function()
            self.m_left_ball_count:findChild("m_lb_num_1"):setString(BALL_COUNT[roundIndex] - (ballProcess[roundIndex] or 0))
            self.m_left_ball_count:findChild("m_lb_num_2"):setString(BALL_COUNT[roundIndex] or 0)
        end)
    else
        self.m_left_ball_count:findChild("m_lb_num_1"):setString(BALL_COUNT[roundIndex] - (ballProcess[roundIndex] or 0))
        self.m_left_ball_count:findChild("m_lb_num_2"):setString(BALL_COUNT[roundIndex] or 0)
        self.m_left_ball_count:runCsbAction("switch2")
    end
end


--[[
    重置界面
]]
function RioPinballMiniMachine:resetView()
    self.m_spine_ball_count:setVisible(false)
    self:refreshReelsByData()
    self:hideAllSymbol()
    for index = 1,16 do
        self.m_dangBanAry[index]:setVisible(false)
        self.m_lightPoints[index]:setVisible(false)
    end

    self.m_round_tip:findChild("sp_rounds"):setVisible(true)
    self.m_round_tip:findChild("sp_round"):setVisible(false)

    self.m_round_tip:findChild("m_lb_num_2"):setVisible(true)
    self.m_round_tip:findChild("m_lb_num_1"):setVisible(false)
end

--[[
    刷新当前轮数
]]
function RioPinballMiniMachine:updateCurRound()
    self.m_round_tip:findChild("sp_rounds"):setVisible(false)
    self.m_round_tip:findChild("sp_round"):setVisible(true)

    self.m_round_tip:findChild("m_lb_num_2"):setVisible(false)
    self.m_round_tip:findChild("m_lb_num_1"):setVisible(true)

    local curRoundIndex = self:getCurRoundIndex()
    self.m_round_tip:findChild("m_lb_num_1"):setString(curRoundIndex)
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_round"..curRoundIndex..".mp3")

    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_change_round.mp3")
    self.m_round_tip:runCsbAction("actionframe1")
    self.m_round_tip:findChild("Particle_1"):resetSystem()
    
end

--[[
    显示轮数
]]
function RioPinballMiniMachine:showRoundTip()
    
    self.m_round_tip:runCsbAction("actionframe",false,function ()
        
    end)

    local curRoundIndex = self:getCurRoundIndex()
    

    self.m_machine:delayCallBack(12 / 60,function()
        self.m_round_tip:findChild("sp_rounds"):setVisible(false)
        self.m_round_tip:findChild("sp_round"):setVisible(true)

        self.m_round_tip:findChild("m_lb_num_2"):setVisible(false)
        self.m_round_tip:findChild("m_lb_num_1"):setVisible(true)

        self.m_round_tip:findChild("m_lb_num_1"):setString(curRoundIndex)
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_round"..curRoundIndex..".mp3")
    end)
end

return RioPinballMiniMachine
