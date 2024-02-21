---
-- xcyy
-- 2018-12-18 
-- FruitPartyMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local FruitPartyMiniMachine = class("FruitPartyMiniMachine", BaseMiniMachine)

FruitPartyMiniMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- bonus收集


FruitPartyMiniMachine.m_machineIndex = nil -- csv 文件模块名字

FruitPartyMiniMachine.gameResumeFunc = nil
FruitPartyMiniMachine.gameRunPause = nil

local REWARD_TYPE_BONUS_GAME    =    1001       --奖励bonus
local REWARD_TYPE_ADD_TIME      =    1002       --奖励次数

local TITLE_TIP_ALLSPOT                 =       2001    --spot全中
local TITLE_TIP_COMPLETED               =       2002    --bonus结束
local TITLE_TIP_SPOT_NUM               =       2003    --spot中线数量
local TITLE_TIP_CUR_TIMES               =       2004    --当前次数

local POP_TIP_NEXT_TARGGER_FREESPIN     =       3001    --增加次数
local POP_TIP_BONUS                     =       3002    --bonus玩法
local POP_TIP_COMPLETED                 =       3003    --玩法结束
local POP_TIP_EXTRA_SPIN_TIMES          =       3004    --奖励次数


local REEL_SIZE = {width = 150, height = 390,decelerNum = 20}
local Main_Reels = 1

local BASE_SPIN_COUNT = 10
-- 构造函数
function FruitPartyMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    self.m_result = nil
    self.m_endFunc = nil
    self.m_curIndex = 1 --当前结果索引
    self.m_quickIndex = -1

    self.isSpecialReelEnd = {}
    self.m_realDataIndex = {1,1}
    self.m_bonusCount = 0
    self.m_freespin_count = BASE_SPIN_COUNT
    self.m_winCoins = 0
end

function FruitPartyMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 

    self.m_machineRootScale = self.m_parent.m_machineRootScale


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    

    --init
    self:initGame()
end

function FruitPartyMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FruitPartyMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FruitParty"
end

function FruitPartyMiniMachine:getMachineConfigName()

    return "FruitPartyMiniMachineConfig.csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FruitPartyMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)
    
    return ccbName
end

---
-- 读取配置文件数据
--
function FruitPartyMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function FruitPartyMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("FruitParty/GameScreenFruitParty_Bonus.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    --特效层
    self.m_effect_node = cc.Node:create()
    self:addChild(self.m_effect_node,100000)

    --轮盘遮罩
    self.m_effect_black = util_createAnimation("FruitParty_reel_zhezhao.csb")
    self:findChild("reelNode"):addChild(self.m_effect_black,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)
    local pos = util_convertToNodeSpace(self:findChild("sp_reel_2"),self:findChild("reelNode"))
    self.m_effect_black:setPosition(cc.p(pos.x + 75,pos.y + 195))
    self.m_effect_black:runCsbAction("idle")
    self.m_effect_black:setVisible(false)

    self:setNodePoolFunc()

    local reel_left = self:findChild("reel_left")
    local reel_right = self:findChild("reel_right")
    local size = reel_left:getContentSize()

    --左右两侧轮子
    self.m_specialReel = {}
    for index = 1,2 do
        local specialReel = self:createSpecialReel(index)
        self.m_specialReel[index] = specialReel
        specialReel:setPosition(cc.p(size.width / 2,size.height / 2))
    end

    reel_left:addChild(self.m_specialReel[1])
    reel_right:addChild(self.m_specialReel[2])


    --收集进度
    self.m_collect_bar = util_createAnimation("FruitParty_Collect.csb")
    self:findChild("Node_Collect"):addChild(self.m_collect_bar)
    self.m_collect_tip = util_createAnimation("FruitParty_Collect_0.csb")
    self.m_collect_bar:findChild("Node_Collect_0"):addChild(self.m_collect_tip)
    self:initColloctBar()

    --座位
    self.m_chairs = {}
    for index = 1,8 do
        local node = self:findChild("Node_BonusSlots_"..index)
        local user_chair = util_createAnimation("FruitParty_BonusSlots.csb")
        node:addChild(user_chair)
        self.m_chairs[index] = user_chair

        user_chair:findChild("Slots_M"):setVisible(false)
        user_chair:findChild("Slots_L"):setVisible(index <= 4)
        user_chair:findChild("Slots_R"):setVisible(index > 4)
    end

    --bonus弹版
    self.m_bonus_wheel = util_createAnimation("FruitParty_Wheel.csb")
    self:findChild("Node_BonusPopUp"):addChild(self.m_bonus_wheel)
    self:initBonusPop()
    self:setBonusPopShow(false)

    

    --顶部事件提示
    self.m_event_tip = util_createAnimation("FruitParty_Tip.csb")
    self:findChild("Node_Tip"):addChild(self.m_event_tip)
    self.m_event_tip:findChild("m_lb_spot"):setString("1")

    --
    self.m_hugeWinView = util_createView("CodeFruitPartySrc.FruitPartyHugeWinView")
    self:findChild("root"):addChild(self.m_hugeWinView)
    self.m_hugeWinView:setVisible(false)
    self.m_hugeWinView:setPosition(cc.p(-display.width / 2 ,-display.height / 2))

    --弹出提示
    self.m_pop_tip = util_createAnimation("FruitParty/BonusGamePopUp.csb")
    self:findChild("root"):addChild(self.m_pop_tip)
    self.m_pop_tip:setVisible(false)

    --bonusover
    self.m_over_view = util_createView("CodeFruitPartySrc.FruitPartyBonusOverView")
    self:addChild(self.m_over_view)
    self.m_over_view:setPosition(cc.p(display.width / 2,display.height / 2))
    
    self.m_over_view:setVisible(false)
end

--[[
    显示遮罩
]]
function FruitPartyMiniMachine:showBlackLayer()
    self.m_effect_black:setVisible(true)
    self.m_effect_black:runCsbAction("show")
    self:addDelayFuncAct(self.m_effect_black,"show",function(  )
        self.m_effect_black:runCsbAction("idle")
    end)
end
--[[
    隐藏遮罩
]]
function FruitPartyMiniMachine:hideBlackLayer( )
    self.m_effect_black:runCsbAction("over")
    self:addDelayFuncAct(self.m_effect_black,"over",function(  )
        self.m_effect_black:setVisible(false)
        self.m_effect_black:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)
    end)
end

--添加动画回调(用延迟)
function FruitPartyMiniMachine:addDelayFuncAct(animationNode, animationName, func)
    self:stopDelayFuncAct(animationNode)
    animationNode.m_runDelayFuncAct =
        performWithDelay(
        animationNode,
        function()
            animationNode.m_runDelayFuncAct = nil
            if func then
                func()
            end
        end,
        util_csbGetAnimTimes(animationNode.m_csbAct, animationName)
    )
end

--停止动画回调
function FruitPartyMiniMachine:stopDelayFuncAct(animationNode)
    if animationNode and animationNode.m_runDelayFuncAct then
        animationNode:stopAction(animationNode.m_runDelayFuncAct)
        animationNode.m_runDelayFuncAct = nil
    end
end

--[[
    显示弹出提示
]]
function FruitPartyMiniMachine:showPopTip(tipType,func)
    local Node_ExtraSpinsTip = self.m_pop_tip:findChild("Node_ExtraSpinsTip")
    local Node_BonusReelTip = self.m_pop_tip:findChild("Node_BonusReelTip")
    local Node_ExtraSpinsAward = self.m_pop_tip:findChild("Node_ExtraSpinsAward")
    local Node_BonusCompleted = self.m_pop_tip:findChild("Node_BonusCompleted")

    Node_ExtraSpinsAward:setVisible(tipType == POP_TIP_EXTRA_SPIN_TIMES)
    Node_ExtraSpinsTip:setVisible(tipType == POP_TIP_NEXT_TARGGER_FREESPIN)
    Node_BonusReelTip:setVisible(tipType == POP_TIP_BONUS)
    Node_BonusCompleted:setVisible(tipType == POP_TIP_COMPLETED)

    --清理连线
    self:clearWinLineEffect()
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_next_collect_tip.mp3")
    self:showBlackLayer()
    self.m_effect_black:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100000)
    self.m_pop_tip:setVisible(true)
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_pop_tip,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
    }
    params[2] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_pop_tip,   --执行动画节点  必传参数
        actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
    }
    params[3] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_pop_tip,   --执行动画节点  必传参数
        actionName = "over", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  )
            self:hideBlackLayer()
            if type(func) == "function" then
                func()
            end
        end
    }
    util_runAnimations(params)
end

--[[
    设置缓存池回调
]]
function FruitPartyMiniMachine:setNodePoolFunc()
    self.m_getNodeByTypeFromPool = function(nextNodeData)

        local ccbName = "Socre_FruitParty_Head"
        local actNode = util_createAnimation(ccbName..".csb")

        local collectData = nextNodeData.collectData


        local m_lb_coins = actNode:findChild("m_lb_coins")
        m_lb_coins:setString(util_formatCoins(collectData.coins, 4))

        local head = actNode:findChild("sp_head")
        head:removeAllChildren(true)
        util_setHead(head, collectData.facebookId, collectData.head, nil, true)
        
        actNode:findChild("sp_headFrame_me"):setVisible(collectData.udid == globalData.userRunData.userUdid)
        actNode:findChild("sp_headFrame"):setVisible(collectData.udid ~= globalData.userRunData.userUdid)
        return actNode
    end


    self.m_pushNodeToPool = function(targSp)

    end
end

--[[
    刷新座位
]]
function FruitPartyMiniMachine:refreshChairs()
    local players = self.m_parent.m_roomData:getRoomRanks()
    for index = 1,8 do
        local playerData = players[index]
        local chairItem = self.m_chairs[index]

        local head = chairItem:findChild("sp_head")
        head:removeAllChildren(true)
        if playerData then
            chairItem.udid = playerData.udid
            chairItem:findChild("Node_BonusSlotsPlayer"):setVisible(true)

            local frameId = globalData.userRunData.userUdid == playerData.udid and globalData.userRunData.avatarFrameId or playerData.frame
            local headSize = head:getContentSize()

            local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerData.facebookId, playerData.head, frameId, nil, headSize)
            head:addChild(nodeAvatar)
            nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

            local headFrameNode = chairItem:findChild("Node_BonusSlotsPlayer"):getChildByName("headFrameNode")
            if not headFrameNode then
                headFrameNode = cc.Node:create()
                chairItem:findChild("Node_BonusSlotsPlayer"):addChild(headFrameNode, 1)
                headFrameNode:setName("headFrameNode")
                headFrameNode:setPosition(head:getPosition())
            else
                headFrameNode:removeAllChildren(true)
            end
            util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)

            chairItem:findChild("sp_headBg_me"):setVisible(playerData.udid == globalData.userRunData.userUdid)
            chairItem:findChild("sp_headBg"):setVisible(playerData.udid ~= globalData.userRunData.userUdid)
            chairItem:findChild("sp_headFrame_me"):setVisible(playerData.udid == globalData.userRunData.userUdid)
            chairItem:findChild("sp_headFrame"):setVisible(playerData.udid ~= globalData.userRunData.userUdid)
        else
            chairItem:findChild("Node_BonusSlotsPlayer"):setVisible(false)
            chairItem.udid = ""
        end
    end
end

--[[
    中奖动画
]]
function FruitPartyMiniMachine:userHitAni(udid)
    for index = 1,8 do
        local chairItem = self.m_chairs[index]
        if chairItem.udid and chairItem.udid == udid then
            chairItem:runCsbAction("actionframe")
        end
    end
end

--[[
    获取全部玩家
]]
function FruitPartyMiniMachine:getAllPlayer( )
    local player_exit = {}
    local players = {}
    
    local isSelfExit = false

    for k,data in pairs(self.m_result.data.collects) do
        if not player_exit[data.udid] then
            local temp = {
                udid = data.udid,
                head = data.head,
                facebookId = data.facebookId,
                nickName = data.nickName or ""
            }
            table.insert(players,#players + 1,temp)

            player_exit[data.udid] = temp
        end

        if data.udid == globalData.userRunData.userUdid then
            isSelfExit = true
        end
    end

    --自己不存在
    if not isSelfExit then
        local temp = {
            udid = globalData.userRunData.userUdid,
            head = globalData.userRunData.HeadName or "0",
            facebookId = globalData.userRunData.facebookBindingID or "",
            nickName = globalData.userRunData.nickName
        }

        table.insert(players,#players + 1,temp)

        player_exit[temp.udid] = temp
    end

    self.m_allPlayers = player_exit

    randomShuffle(players)
    return players
end

--[[
    初始化收集进度
]]
function FruitPartyMiniMachine:initColloctBar()
    self.m_collect_bar:runCsbAction("idle1")
    self.m_collect_tip:runCsbAction("idle")
    self:refreshColloctTip(REWARD_TYPE_BONUS_GAME)
end

--[[
    刷新收集条文字说明
]]
function FruitPartyMiniMachine:refreshColloctTip(rewardType)
    --奖励bonus
    if rewardType == REWARD_TYPE_BONUS_GAME then
        self.m_collect_tip:findChild("txt_1"):setVisible(true)
        self.m_collect_tip:findChild("txt_2"):setVisible(false)
    elseif rewardType == REWARD_TYPE_ADD_TIME then --奖励次数
        self.m_collect_tip:findChild("txt_1"):setVisible(false)
        self.m_collect_tip:findChild("txt_2"):setVisible(true)
    else
        self.m_collect_tip:findChild("txt_1"):setVisible(false)
        self.m_collect_tip:findChild("txt_2"):setVisible(false)
    end
end

--[[
    刷新收集进度
]]
function FruitPartyMiniMachine:refreshColloctBar(count,func)

    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol.p_symbolType == self.m_parent.SYMBOL_SCORE_BONUS then
                --飞粒子特效
                self:flyParticleAni(symbol,self.m_collect_bar)
            end
        end
    end

    self:collectBarAni(self.m_bonusCount + 1,count,function()
        self.m_bonusCount = count
        if self.m_bonusCount == 3 then
            self.m_bonusCount = 0
        end
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    收集特效
]]
function FruitPartyMiniMachine:collectBarAni(count,maxCount,func)
    local endFunc = function()
        self:collectBarAni(count + 1,maxCount,func)
    end

    if count > maxCount then
        if type(func) == "function" then
            func()
        end
        return
    end

    self:delayCallBack(40 / 60 ,function()
        gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_collect.mp3")
        if count == 0 then
            self.m_collect_bar:runCsbAction("idle1")
        elseif count == 1 then
            self.m_collect_bar:runCsbAction("actionframe1",false,function(  )
                self.m_collect_bar:runCsbAction("idle2",true)
                endFunc()
            end)
        elseif count == 2 then
            self.m_collect_bar:runCsbAction("actionframe2",false,function(  )
                self.m_collect_bar:runCsbAction("idle3",true)
                endFunc()
            end)
        elseif count == 3 then
            self.m_collect_bar:runCsbAction("actionframe3",false,function(  )
                self:refreshTitle(TITLE_TIP_COMPLETED)
                gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_collect_finished.mp3")
                self.m_collect_bar:runCsbAction("actionframe",false,function(  )
                    self.m_collect_bar:runCsbAction("idle1")
                    self.m_bonusCount = 0
                    endFunc()
                end)
            end)
        end
    end)
end

--[[
    飞粒子效果
]]
function FruitPartyMiniMachine:flyParticleAni(startNode,endNode,func)
    local ani = util_createAnimation("FruitParty_Bonus_collect.csb")
    ani:findChild("Particle_1"):setPositionType(0)
    ani:findChild("Particle_2"):setPositionType(0)
    ani:findChild("Particle_2"):setPositionType(0)
    self.m_effect_node:addChild(ani)

    ani:setPosition(util_convertToNodeSpace(startNode,self.m_effect_node))

    local endPos = util_convertToNodeSpace(endNode,self.m_effect_node)

    ani:runCsbAction("actionframe")
    local seq = cc.Sequence:create({
        cc.DelayTime:create(10 / 60),
        cc.MoveTo:create(30 / 60,endPos),
        cc.CallFunc:create(function(  )
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })
    ani:runAction(seq)
end

--[[
    初始化bonus弹版
]]
function FruitPartyMiniMachine:initBonusPop()
    self.m_bonus_users = {}
    for index = 1,24 do
        local bonusItem = util_createAnimation("FruitParty_WheelSpot.csb")
        self.m_bonus_wheel:findChild("Node_Spot_"..index):addChild(bonusItem)
        self.m_bonus_users[index] = bonusItem
    end

    --创建横向滚轮
    self.m_reel_horizontal = self:createSpecialReelHorizontal()
    self.m_bonus_wheel:findChild("node_reel"):addChild(self.m_reel_horizontal)
    self.m_reel_horizontal:setCsbNode(self.m_bonus_wheel)
    local size = self.m_bonus_wheel:findChild("node_reel"):getContentSize()
    self.m_reel_horizontal:setPosition(cc.p(0,size.height / 2))
    
end

--[[
    刷新bonus弹版
]]
function FruitPartyMiniMachine:refreshBonusPop( )
    local collects = self.m_result.data.collects
    self.m_reel_horizontal:setCollects(collects)
    for index = 1,24 do
        local data = collects[index]
        local bonusItem = self.m_bonus_users[index]
        bonusItem:findChild("sp_head"):removeAllChildren(true)
        bonusItem:findChild("m_lb_coins"):setString(util_formatCoins(data.coins, 4))
        local head = bonusItem:findChild("sp_head")
        util_setHead(head, data.facebookId, data.head, nil, true)

        bonusItem:findChild("sp_headFrame_me"):setVisible(data.udid == globalData.userRunData.userUdid)
        bonusItem:findChild("sp_headFrame"):setVisible(data.udid ~= globalData.userRunData.userUdid)
    end
end

--[[
    设置bonus弹版显示
]]
function FruitPartyMiniMachine:setBonusPopShow(isShow)
    self.m_bonus_wheel:setVisible(isShow)
    self:findChild("reelNode"):setVisible(not isShow)
    -- self.m_collect_bar:setVisible(not isShow)
    -- for k,chair in pairs(self.m_chairs) do
    --     chair:setVisible(not isShow)
    -- end
end

--[[
    创建特殊轮子
]]
function FruitPartyMiniMachine:createSpecialReel(index)
    local featureNode = util_createView("CodeFruitPartySpecialReel.FruitPartySpecialReelNode")
    
    featureNode:init(self.m_getNodeByTypeFromPool,self.m_pushNodeToPool,index,self)

    featureNode:initRunDate(nil, function(reelIndex)
        
        local collects = self.m_result.data.collects
        local randIndex = math.random(1,#collects)
        local reelData = self:getSpecialReelData(collects[randIndex],false)
        --获取当前显示进度
        local curIndex = self.m_realDataIndex[reelIndex]
        local isLast = false
        
        if curIndex == 3 then
            isLast = true
        end


        if self.isSpecialReelEnd[reelIndex] and curIndex <= 3 then
            local selfData = self.m_runSpinResultData.p_selfMakeData
            --获取额外轮盘
            local extralReel = selfData.extralReels[reelIndex]
            
            --获取数据
            local spotIndex = extralReel[3 - curIndex + 1]
            reelData = self:getSpecialReelData(collects[spotIndex + 1],isLast)

            --迭代进度
            curIndex = curIndex + 1
            self.m_realDataIndex[reelIndex] = curIndex
            
        end
        
        return  reelData
    end)

    if index == 2 then
        featureNode:setEndCallBackFun(function(  )
            self:reelDownNotifyPlayGameEffect( )  
        end)
    end

    return featureNode
end

--[[
    创建特殊轮子-横向
]]
function FruitPartyMiniMachine:createSpecialReelHorizontal()
    local featureNode = util_createView("CodeFruitPartySpecialReel.FruitPartySpecialReelNodeHorizontal")
    
    featureNode:init({parent = self})

    

    featureNode:initRunDate(nil, function(reelIndex)
        
        
    end)

    return featureNode
end

--[[
    获取特殊轮子小块数据
]]
function FruitPartyMiniMachine:getSpecialReelData(collectData,isLast)
    local reelData = util_require("data.slotsdata.SpecialReelData"):create()
    reelData.Zorder = 1
    reelData.Width = REEL_SIZE.width
    reelData.Height = REEL_SIZE.height / 3
    reelData.Last = isLast
    reelData.collectData = collectData
    return reelData
end

--
---
--
function FruitPartyMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    BaseMiniMachine.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function FruitPartyMiniMachine:startBonus()
    
    
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_show_side.mp3")
    self:runCsbAction("actionframe",false,function(  )
        self:runCsbAction("idleframe")
        gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_show_head.mp3")
        for k,reel in pairs(self.m_specialReel) do
            reel:showAni()
        end
    
        self:delayCallBack(1.5,function (  )
            self.m_parent:resetMusicBg(false,"FruitPartySounds/music_FruitParty_bgmusic_freegame.mp3")
            self:beginMiniReel()
        end)
    end)
end

--[[
    重置界面
]]
function FruitPartyMiniMachine:resetUI(result,func)
    self.m_result = result
    self.m_endFunc = func
    self.m_curIndex = 1
    self.m_bonusCount = 0
    self.m_winCoins = 0
    self.m_freespin_count = BASE_SPIN_COUNT
    self:refreshTitle(TITLE_TIP_CUR_TIMES)
    self:getAllPlayer()
    self:refreshChairs()
    self:findChild("root"):setVisible(true)
    self:refreshBonusPop()
    util_csbPauseForIndex(self.m_csbAct,0)

    self.m_event_tip:findChild("m_lb_spin"):setString("1/10")

    --自己获得的spot数量
    local spotCount = self:getSpotCount()
    -- self:findChild("Node_MySpotsNum"):setVisible(spotCount > 0)
    self:findChild("m_lb_num"):setString(spotCount)

    --是否需要领取bonus奖励
    local winSpots = self.m_parent.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local coins = 0
        for key,winInfo in pairs(winSpots) do
            if winInfo.udid == globalData.userRunData.userUdid then
                coins = coins + winInfo.coins
            end
        end
    end

    self:initColloctBar()
    --隐藏bonus弹版
    self:setBonusPopShow(false)
    local collects = self.m_result.data.collects
    for k,reel in pairs(self.m_specialReel) do
        local initReelData = {}
        for index = 1,3 do
            local randIndex = math.random(1,#collects)
            local reelData = self:getSpecialReelData(collects[randIndex],false)
            initReelData[index] = reelData
        end
        reel:initFirstSymbolBySymbols(initReelData)
        reel:initSymbolStatus()
    end
end

--[[
    获取spot数量
]]
function FruitPartyMiniMachine:getSpotCount( )
    local count = 0
    for k,data in pairs(self.m_result.data.collects) do
        if data.udid == globalData.userRunData.userUdid then
            count = count + 1
        end
    end
    return count
end

function FruitPartyMiniMachine:bonusEnd()
    self.m_parent:clearCurMusicBg()
    self:delayCallBack(0.5,function(  )
        self:showPopTip(POP_TIP_COMPLETED,function(  )

            self:findChild("root"):setVisible(false)
    
            self:showBonusOverView(function(  )
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                    self.m_endFunc = nil
                    self.m_result = nil
                end
            end)
            
        end)
    end)
    
end

--[[
    显示bonusOver界面
]]
function FruitPartyMiniMachine:showBonusOverView(func)
    --排名数据
    local rankList = clone(self.m_result.data.rank) 

    table.sort(rankList,function(a,b)
        return a.coins > b.coins
    end)
    --自身排名
    local selfRank = nil
    for k,rankData in pairs(rankList) do
        if rankData.udid == globalData.userRunData.userUdid then
            selfRank = rankData
            selfRank.rank = k
        end
    end

    local coins = 0
    if selfRank then
        coins = selfRank.coins
    else
        selfRank = {
            coins= 0,
            multiple= 0,
            udid = globalData.userRunData.userUdid,
            rank = -1
        }
        -- rankList[#rankList + 1] = selfRank
    end

    --判断自身排名
    if selfRank.rank > 9 then
        local rank = selfRank.rank
        --交换排名
        local temp = rankList[9]
        rankList[9] = rankList[rank]
        rankList[rank] = temp
        selfRank.rank = 9
    end

    --检测是否获得大奖
    -- self.m_parent:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS)
    self.m_parent:showBonusOverBg()
    self.m_over_view:showView(rankList,self.m_allPlayers,function(  )
        if coins > 0 then
            local gameName = self.m_parent:getNetWorkModuleName()
            local winSpots = self.m_parent.m_roomData:getWinSpots()
            local index = #winSpots - 1
            --发送领奖消息
            gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

                    if type(func) == "function" then
                        func()
                    end
                end,
                function(errorCode, errorData)
                    
                end
            )
        else    --自身没赢钱
            if type(func) == "function" then
                func()
            end
        end
        
        
    end)
end

function FruitPartyMiniMachine:addSelfEffect()

    local resultData = self.m_runSpinResultData
    if not resultData.p_selfMakeData then
        return
    end

    local selfData = resultData.p_selfMakeData

    if selfData.bonusCount > self.m_bonusCount then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
    end
 
end


function FruitPartyMiniMachine:MachineRule_playSelfEffect(effectData)
    local resultData = self.m_runSpinResultData

    local selfData = resultData.p_selfMakeData
    --bonus收集
    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        self:refreshColloctBar(selfData.bonusCount,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

function FruitPartyMiniMachine:showEffect_LineFrame(effectData)
    self.m_event_tip:findChild("m_lb_spot"):setString(#self.m_reelResultLines)
    self:refreshTitle(TITLE_TIP_SPOT_NUM,#self.m_reelResultLines)
    local lineDatas = self:mergeSameUserLines()

    if lineDatas then
        for k,data in pairs(lineDatas) do
            --玩家中奖动画
            self:userHitAni(data.udid)
        end
    end
    

    self:delayCallBack(0.2,function()
        self:showNextLineFrame(lineDatas,1,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end)

    return true

end

--[[
    合并相同玩家的连线
]]
function FruitPartyMiniMachine:mergeSameUserLines()
    local tempLines = {}
    local tempUsers = {}

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collects = self.m_result.data.collects

    for index,lineData in pairs(self.m_reelResultLines) do
        local pos = self:getRowAndColByPos(lineData.key)
        local iCol,iRow = pos.iY,pos.iX

        local reelIndex = 1
        if iCol == self.m_iReelColumnNum then
            reelIndex = 2
        end
        --获取额外轮盘
        local extralReel = selfData.extralReels[reelIndex]
        
        --获取数据
        local colloctData = collects[extralReel[3 - iRow + 1] + 1]

        local isExit = false
        local curData = nil

        for k,value in pairs(tempLines) do
            if value.udid and value.udid == colloctData.udid then
                isExit = true
                curData = value
                break
            end
        end

        if not isExit then
            curData = clone(lineData)
            tempLines[#tempLines + 1] = curData
            curData.udid = colloctData.udid
            curData.keys = {}
            curData.keys[#curData.keys + 1] = lineData.key
        else
            curData.keys[#curData.keys + 1] = lineData.key
            for iLine = 1,#lineData.lineData do
                curData.lineData[#curData.lineData + 1] = clone(lineData.lineData[iLine])
            end
        end
    end

    return tempLines
end

--[[
    显示下个连线
]]
function FruitPartyMiniMachine:showNextLineFrame(lineDatas,index,func)
    local winLines = lineDatas[index]
    if not winLines then
        if type(func) == "function" then
            func()
        end
        return
    end

    self:clearWinLineEffect()
    for index = 1 ,2 do
        self.m_specialReel[index]:clearLineAndFrame()
    end
    self:showInLineSlotNodeByWinLines(winLines.lineData, nil , nil)
    self:showAllFrame(winLines.lineData)
    self:playInLineNodes()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collects = self.m_result.data.collects
    local totalMutiples = 0

    local winUserInfo = {
        head= 1,
        coins= 0,
        multiple= 0,
        position= 0,
        udid= "",
        betCoins= 0
    }
    --两侧的轮子显示连线
    for index,key in pairs(winLines.keys) do
        local pos = self:getRowAndColByPos(key)
        local iCol,iRow = pos.iY,pos.iX

        local reelIndex = 1
        if iCol == 1 then
            self.m_specialReel[1]:showLineFrame(iRow)
        elseif iCol == self.m_iReelColumnNum then
            self.m_specialReel[2]:showLineFrame(iRow)
            reelIndex = 2
        end

        --获取额外轮盘
        local extralReel = selfData.extralReels[reelIndex]
        
        --获取数据
        local colloctData = clone(collects[extralReel[3 - iRow + 1] + 1]) 

        --计算总倍数
        local multiple = self:getLineMultiple(key)
        totalMutiples = totalMutiples + multiple

        winUserInfo.head = colloctData.head
        winUserInfo.udid = colloctData.udid
        winUserInfo.facebookId = colloctData.facebookId
        winUserInfo.nickName = colloctData.nickName
        --计算金币
        winUserInfo.coins = winUserInfo.coins + selfData.userWinCoins[tostring(colloctData.position)]
    end

    self:delayCallBack(1,function(  )
        self.m_hugeWinView:setVisible(true)
        self:showBlackLayer()

        self.m_hugeWinView:showView(winUserInfo,function()
            self.m_hugeWinView:setVisible(false)
        end,function()
            self:hideBlackLayer()
        end)
        --刷新金币
        if winLines.udid == globalData.userRunData.userUdid then
            self.m_winCoins = winUserInfo.coins + self.m_winCoins
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                self.m_winCoins, false, true,self.m_winCoins - winUserInfo.coins
            })
        end
    end)
    
    self:delayCallBack(5,function(  )
        self:showNextLineFrame(lineDatas,index + 1,func)
    end)

end

--[[
    播放赢钱音效
]]
function FruitPartyMiniMachine:playWinSound(winAmonut)
    if type(winAmonut) == "number" then
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winAmonut / lTatolBetNum
        local soundName = nil
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundName = self.m_parent.m_winPrizeSounds[1]
            elseif winRatio > 1 and winRatio <= 3 then
                soundName = self.m_parent.m_winPrizeSounds[2]
            elseif winRatio > 3 then
                soundName = self.m_parent.m_winPrizeSounds[3]
                soundTime = 3
            end
        end

        if soundName ~= nil then
            globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end
    end
end

--[[
    获取倍数
]]
function FruitPartyMiniMachine:getLineMultiple(key)
    local winLinesGroup = self.m_runSpinResultData.p_selfMakeData.winLinesGroup

    local lines = winLinesGroup[key]
    if not lines then
        lines = winLinesGroup[tostring(key)]
    end
    local multiple = 0
    for k,lineData in pairs(lines) do
        multiple = multiple + lineData.multiple
    end
    return multiple
end

---
--
function FruitPartyMiniMachine:clearLineAndFrame()

    for index = 1 ,2 do
        self.m_specialReel[index]:clearLineAndFrame()
    end

    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end


function FruitPartyMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function(self, _index)
        self:refreshChairs()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
end



function FruitPartyMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function FruitPartyMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function FruitPartyMiniMachine:quicklyStopReel(colIndex)


end

function FruitPartyMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function FruitPartyMiniMachine:removeObservers()
    BaseMiniMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function FruitPartyMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
end


function FruitPartyMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    self.m_realDataIndex = {1,1}
    self.m_quickIndex = -1
    BaseMiniMachine.beginReel(self)
    self.isSpecialReelEnd = {}
    for index = 1,2 do
        local reel = self.m_specialReel[index]
        reel:initAction()
        reel:beginMove()
        self:startSpecialAni(index)
    end
    self:netWorkCallFun()

    local features = self.m_runSpinResultData.p_features
    if features then
        for index = 1,#features do
            local featureID = features[index]
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                self.m_runSpinResultData.p_freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount - 2
                self.m_runSpinResultData.p_freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount - 2
            end
        end
    end
    

    self:refreshLeftTimes()
    self:refreshTitle(TITLE_TIP_CUR_TIMES)
end

--[[
    刷新标题
]]
function FruitPartyMiniMachine:refreshTitle(titleType,spotCount)
    local Tip_BonusReel = self.m_event_tip:findChild("Tip_BonusReel")
    local Tip_Collect = self.m_event_tip:findChild("Tip_Collect")
    local Tip_SpotsWon = self.m_event_tip:findChild("Tip_SpotsWon")
    local Tip_Spin = self.m_event_tip:findChild("Tip_Spin")

    Tip_BonusReel:setVisible(titleType == TITLE_TIP_ALLSPOT)
    Tip_Collect:setVisible(titleType == TITLE_TIP_COMPLETED)
    Tip_SpotsWon:setVisible(titleType == TITLE_TIP_SPOT_NUM)
    Tip_Spin:setVisible(titleType == TITLE_TIP_CUR_TIMES)

    if spotCount and spotCount == 1 then
        self.m_event_tip:findChild("SpotsWon_1"):setVisible(true)
        self.m_event_tip:findChild("SpotsWon"):setVisible(false)
    else
        self.m_event_tip:findChild("SpotsWon_1"):setVisible(false)
        self.m_event_tip:findChild("SpotsWon"):setVisible(true)
    end
end

--[[
      开始动作
]]
function FruitPartyMiniMachine:startSpecialAni(index)
    local maxCount = 10
    local curCount = 0
    self:createNextAniNode(curCount,maxCount,index)
end

function FruitPartyMiniMachine:createNextAniNode(curCount,maxCount,index)
    if curCount >= maxCount then
          return
    end

    local reel_node,reel_node_cut = nil, nil
    if index == 1 then
        reel_node = self:findChild("reel_left")
        reel_node_cut = self:findChild("reel_left_0")
    else
        reel_node = self:findChild("reel_right")
        reel_node_cut = self:findChild("reel_right_0")
    end

    local reel = self.m_specialReel[index]

    local node =  reel.m_symbolNodeList[1]
    local tempNode = reel.getSlotNodeBySymbolType(node.userData)
    local size = reel_node:getContentSize()

    local pos = util_convertToNodeSpace(reel_node,reel_node_cut)
    tempNode:setPosition(cc.p(pos.x + size.width / 2,pos.y + size.height - 65))

    reel_node_cut:addChild(tempNode,1000 - curCount)
    tempNode:runAction(cc.Sequence:create({
          cc.EaseSineIn:create(cc.MoveBy:create(1,cc.p(0,-REEL_SIZE.height))),
          cc.RemoveSelf:create(true)
    }))

    self:delayCallBack(0.1,function(  )
          self:createNextAniNode(curCount + 1,maxCount,index)
    end)
end


-- 消息返回更新数据
function FruitPartyMiniMachine:netWorkCallFun()
    local spinResult = self.m_result.data.spinResultList[self.m_curIndex]

    self:resetDataWithLineLogic()
    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)
    self:parseWinLines(spinResult)

    self:updateNetWorkData()

    self.m_curIndex = self.m_curIndex + 1
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function FruitPartyMiniMachine:netWorklineLogicCalculate()
    
    local isFiveOfKind = self:lineLogicWinLines()
    
    if isFiveOfKind then
        self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

    -- 根据features 添加具体玩法 
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

function FruitPartyMiniMachine:checkAndClearVecLines()

    if self.m_vecGetLineInfo == nil then
        self.m_vecGetLineInfo = {}
    end

    for lineIndex = #self.m_vecGetLineInfo , 1, -1 do
        local value = self.m_vecGetLineInfo[lineIndex]

        for index = #value.lineData ,1,-1 do
            local data = value.lineData[index]
            data:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = data
            value.lineData[index] = nil
        end
        

        self.m_vecGetLineInfo[lineIndex] = nil
    end

end

--[[
    解析连线数据
]]
function FruitPartyMiniMachine:parseWinLines(resultData)
    local selfData = resultData.selfData

    if not selfData  then
        return
    end
    --添加连线事件
    if selfData.winLinesGroup then
        for k,lines in pairs(selfData.winLinesGroup) do
            local temp = {}
            temp.key = tonumber(k)
            temp.lineData = {}
            for i = 1, #lines do
                local lineData = lines[i]
                local winLineData = self.m_runSpinResultData:getWinLineDataWithPool(self.m_lineDataPool)
                winLineData.p_id = lineData.id
                winLineData.p_amount = lineData.amount
                winLineData.p_iconPos = lineData.icons
                winLineData.p_type = lineData.type
                winLineData.p_multiple = lineData.multiple
                table.insert(temp.lineData,#temp.lineData + 1,winLineData)
            end
            table.insert(self.m_runSpinResultData.p_winLines,#self.m_runSpinResultData.p_winLines + 1,temp)
        end

        --排序
        util_bubbleSort(self.m_runSpinResultData.p_winLines,function(a,b)
            local pos1 = self:getRowAndColByPos(a.key)
            local pos2 = self:getRowAndColByPos(b.key)
            return (pos1.iY == pos2.iY and pos1.iX > pos2.iX) or (pos1.iY < pos2.iY) 
        end)
    end
end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function FruitPartyMiniMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        for index = 1,#winLines do

            local lines = winLines[index]
            --记录key值
            local temp = {
                key = lines.key,
                lineData = {}
            }
            for i = 1,#lines.lineData do
                local winLineData = lines.lineData[i]
                local iconsPos = winLineData.p_iconPos

                -- 处理连线数据
                local lineInfo = self:getReelLineInfo()
                local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
                
                lineInfo.enumSymbolType = enumSymbolType
                lineInfo.iLineIdx = winLineData.p_id
                lineInfo.iLineSymbolNum = #iconsPos
                lineInfo.lineSymbolRate = 1
                table.insert(temp.lineData,#temp.lineData + 1,lineInfo)
            end

            table.insert(self.m_vecGetLineInfo,#self.m_vecGetLineInfo + 1,temp)
        end

    end

    return isFiveOfKind
end

local function cloneLineInfo(originValue, targetValue)
    targetValue.enumSymbolType = originValue.enumSymbolType
    targetValue.enumSymbolEffectType = originValue.enumSymbolEffectType
    targetValue.iLineIdx = originValue.iLineIdx
    targetValue.iLineSymbolNum = originValue.iLineSymbolNum
    targetValue.iLineMulti = originValue.iLineMulti
    targetValue.lineSymbolRate = originValue.lineSymbolRate

    local matrixPosLen = #originValue.vecValidMatrixSymPos
    for i = 1, matrixPosLen do
        local value = originValue.vecValidMatrixSymPos[i]

        table.insert(targetValue.vecValidMatrixSymPos, {iX = value.iX, iY = value.iY})
    end
end

-- 组织播放连线动画信息
function FruitPartyMiniMachine:insterReelResultLines( )
    
    if #self.m_vecGetLineInfo ~= 0 then
        local lines = self.m_vecGetLineInfo
        local lineLen = #lines
        local hasBonus = false
        local hasScatter = false
        for i = 1, lineLen do
            local lineData = lines[i].lineData

            local temp = {
                key = lines[i].key,
                lineData = {}
            }

            for index = 1,#lineData do
                local value = lineData[index]
                local cloneValue = self:getReelLineInfo()
                cloneLineInfo(value, cloneValue)
                table.insert(temp.lineData,#temp.lineData + 1,cloneValue)
            end
            
            table.insert(self.m_reelResultLines,#self.m_reelResultLines + 1, temp)

        end
    end

end

---
--添加连线动画
function FruitPartyMiniMachine:addLineEffect()
    if #self.m_vecGetLineInfo ~= 0 then

        local effectData = GameEffectData.new()
        effectData.p_effectType = self.m_LineEffectType
         --GameEffect.EFFECT_SHOW_ALL_LINE
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData

    end
end

function FruitPartyMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function FruitPartyMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end

function FruitPartyMiniMachine:dealSmallReelsSpinStates( )
    
end

function FruitPartyMiniMachine:playEffectNotifyNextSpinCall( )
    local spinResultList = self.m_result.data.spinResultList
    if not spinResultList or self.m_curIndex > #spinResultList then
        self:bonusEnd()
        return
    end

    local delayTime = 0.5
    delayTime = delayTime + self:getWinCoinTime()

    self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
        gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
        self:beginMiniReel()
    end, delayTime,self:getModuleName())

end

-- 处理特殊关卡 遮罩层级
function FruitPartyMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function FruitPartyMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType )

end



function FruitPartyMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FruitPartyMiniMachine:checkGameResumeCallFun( )
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

function FruitPartyMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FruitPartyMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FruitPartyMiniMachine:resumeMachine()
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
function FruitPartyMiniMachine:clearSlotoData()
    
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
function FruitPartyMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FruitPartyMiniMachine:clearCurMusicBg( )
    
end

---
-- 老虎机滚动结束调用
function FruitPartyMiniMachine:slotReelDown()

    self:setGameSpinStage( STOP_RUN )
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            for index = #value.lineData ,1,-1 do
                local data = value.lineData[index]
                data:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = data
                value.lineData[index] = nil
            end
            

            self.m_reelResultLines[i] = nil
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end


    self:checkRestSlotNodePos( )

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()
    self:stopAllActions()

    local winCount = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.winLinesGroup then
        for k,v in pairs(selfData.winLinesGroup) do
            winCount = winCount + 1
        end
    end
    
    if winCount ~= 6 then
        for index = 1,2 do
            self.isSpecialReelEnd[index] = true
        end
    else
        for index = 1,2 do
            self.m_specialReel[index]:showNoticeLine()
        end
        self.m_quickIndex = 1
        self:playQuickRunSound()

        self:delayCallBack(2,function(  )
            self.isSpecialReelEnd[1] = true
            self:delayCallBack(2,function(  )
                self.isSpecialReelEnd[2] = true
            end)
        end)
    end

    
    
    
    -- self:reelDownNotifyPlayGameEffect( )
end

--[[
    播放快滚音效
]]
function FruitPartyMiniMachine:playQuickRunSound()
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    if self.m_quickIndex >= 1 and self.m_quickIndex <= 2 then
        self.m_quickIndex = self.m_quickIndex + 1
        self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
    end
    
end


function FruitPartyMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
    BaseMiniMachine.reelDownNotifyPlayGameEffect(self)
end

--
--单列滚动停止回调
--
function FruitPartyMiniMachine:slotOneReelDown(reelCol)    
    BaseMiniMachine.slotOneReelDown(self,reelCol) 

    local isBonusDown = false
    for iRow=1,self.m_iReelRowNum do
        local symbol = self:getFixSymbol(reelCol, iRow)
        if symbol and symbol.p_symbolType == self.m_parent.SYMBOL_SCORE_BONUS then
            isBonusDown = true
            symbol:runAnim("buling",false,function()
                symbol:runAnim("idleframe")
            end)
        end
    end

    if isBonusDown then

        local soundPath = "FruitPartySounds/sound_FruitParty_bonus_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
    
end

---
-- 显示bonus 触发的小游戏
function FruitPartyMiniMachine:showEffect_Bonus(effectData)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    --设置滚动数据
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_reel_horizontal:setAllRunSymbols(selfData.bonusReels)
    self.m_reel_horizontal:initAction()
    self.m_reel_horizontal:setEndCallBackFun(function()
        self:setBonusPopShow(false)
        self:refreshColloctTip(REWARD_TYPE_ADD_TIME)
        self.m_collect_tip:runCsbAction("actionframe")
        self.m_parent:resetMusicBg(false,"FruitPartySounds/music_FruitParty_bgmusic_freegame.mp3")
        self:showPopTip(POP_TIP_NEXT_TARGGER_FREESPIN,function(  )

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    end)


    --关键帧回调
    local keyFunc = function(  )
        self:setBonusPopShow(true)
    end
    --过场动画
    self.m_parent:changeSceneAni(keyFunc,function(  )
        self:refreshTitle(TITLE_TIP_ALLSPOT)
        self.m_parent:resetMusicBg(false,"FruitPartySounds/music_FruitParty_bgmusic_wheelgame.mp3")
        --开始滚动
        self.m_reel_horizontal:startMove(function(  )
            self:delayCallBack(1,function(  )
                self.m_reel_horizontal:beginMove()
            end)
        end)
    end)

    

    return true
end


function FruitPartyMiniMachine:showEffect_FreeSpin(effectData)
    self.m_runSpinResultData.p_freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount + 2
    self.m_runSpinResultData.p_freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount + 2
    self:refreshLeftTimes(true)

    self:refreshTitle(TITLE_TIP_CUR_TIMES)
    --显示加次数提示
    self:showPopTip(POP_TIP_EXTRA_SPIN_TIMES,function(  )
        self:refreshColloctTip(REWARD_TYPE_BONUS_GAME)
        self.m_collect_tip:runCsbAction("actionframe")
        --显示下次中奖bonus
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
        
        self:showPopTip(POP_TIP_BONUS,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end)
    

    return true
end

--[[
    刷新剩余次数
]]
function FruitPartyMiniMachine:refreshLeftTimes(isFree)
    local spinResult = self.m_runSpinResultData
    local leftCount = spinResult.p_freeSpinsLeftCount
    local totalCount = spinResult.p_freeSpinsTotalCount
    -- local newCount = spinResult.
    local str = (totalCount - leftCount).."/"..totalCount
    

    if isFree then
        self.m_event_tip:runCsbAction("actionframe")
        gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_bonus_add_times.mp3")
        self:delayCallBack(10 / 60,function()
            self.m_event_tip:findChild("m_lb_spin"):setString(str)
        end)
    else
        self.m_event_tip:findChild("m_lb_spin"):setString(str)
    end
end

--[[
    延迟回调
]]
function FruitPartyMiniMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return FruitPartyMiniMachine
