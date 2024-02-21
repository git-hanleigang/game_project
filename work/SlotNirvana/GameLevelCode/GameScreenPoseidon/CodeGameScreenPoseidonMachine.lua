--[[
    author:{he}
    time:2019-02-20 16:35:57
]]
local BaseSlots = require "Levels.BaseSlots"
-- local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseMachine = require "Levels.BaseMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SlotParentData = require "data.slotsdata.SlotParentData"
local CodeGameScreenPoseidonMachine = class("CodeGameScreenPoseidonMachine", BaseSlotoManiaMachine)
CodeGameScreenPoseidonMachine.m_triggerRespin = nil
CodeGameScreenPoseidonMachine.m_respinAllFixPos = nil
CodeGameScreenPoseidonMachine.m_respinNewFixPos = nil
CodeGameScreenPoseidonMachine.m_jackPotBar = nil
CodeGameScreenPoseidonMachine.m_freeSpinBar = nil
CodeGameScreenPoseidonMachine.m_freeSpinAnimaBar = nil
CodeGameScreenPoseidonMachine.m_bigPoseidon = nil
CodeGameScreenPoseidonMachine.m_poseidonTip = nil
CodeGameScreenPoseidonMachine.m_jpBar = nil

CodeGameScreenPoseidonMachine.m_symbolUp1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE      --wild翻倍 93
CodeGameScreenPoseidonMachine.m_symbolUp2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --         94

CodeGameScreenPoseidonMachine.m_arrow = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  --         94


CodeGameScreenPoseidonMachine.m_symbolBlank = 100             --空白图

CodeGameScreenPoseidonMachine.m_jackPotScore = 101            --jackPot图标
CodeGameScreenPoseidonMachine.m_jackPotMini = 102
CodeGameScreenPoseidonMachine.m_jackPotMinor = 103
CodeGameScreenPoseidonMachine.m_jackPotMajor = 104
CodeGameScreenPoseidonMachine.m_jackPotGrand = 105
CodeGameScreenPoseidonMachine.m_jackPoseidon = 106

CodeGameScreenPoseidonMachine.m_jpposeidonTip = 107
CodeGameScreenPoseidonMachine.m_jpWinTip = 108


CodeGameScreenPoseidonMachine.m_symbolRepsinSpecial1 = 1001   --jp球
CodeGameScreenPoseidonMachine.m_symbolRepsinSpecial2 = 1002   --round球 x
CodeGameScreenPoseidonMachine.m_symbolRepsinSpecial3 = 1003   --up球 ⬆️
CodeGameScreenPoseidonMachine.m_symbolRepsinSpecial4 = 1004   -- +

--一些播放效果spine
CodeGameScreenPoseidonMachine.m_featureShowAnima = 10001       --feature开始过场
CodeGameScreenPoseidonMachine.m_featureOverAnima = 10002       --feature结束过场
CodeGameScreenPoseidonMachine.m_jpFixAnima = 10003             --jp固定
CodeGameScreenPoseidonMachine.m_respinFixAnima = 10004         --repsin固定动画
CodeGameScreenPoseidonMachine.m_upFixAnima = 10005             --repsinUp动画

CodeGameScreenPoseidonMachine.m_jpShowAnima = 10007      --jp过场动画
CodeGameScreenPoseidonMachine.m_scatterAddAnima = 10008      --jp过场动画

CodeGameScreenPoseidonMachine.m_bigPoseidonAnima = 10006      --bigposeidon\
CodeGameScreenPoseidonMachine.m_bigPoseidonAnima2 = 10009      --bigposeidon


--一些效果 studio
CodeGameScreenPoseidonMachine.m_respinLight = 20001            --respin 球变闪电
CodeGameScreenPoseidonMachine.m_peseidonChangeBig = 20002            --respin 变大图

CodeGameScreenPoseidonMachine.m_isBreakLine = nil

CodeGameScreenPoseidonMachine.m_scatterLineValue = nil
CodeGameScreenPoseidonMachine.m_lineScaleAction = nil

CodeGameScreenPoseidonMachine.m_respinLineNodes = nil
CodeGameScreenPoseidonMachine.m_respinGroupPos = nil

CodeGameScreenPoseidonMachine.m_respinWinCoinsBar = nil

CodeGameScreenPoseidonMachine.m_effectLayerPos = nil

CodeGameScreenPoseidonMachine.m_poseidonMoveDelay = nil

local MIN_CONTINUE_POSEIDON_COUNT = 6

local MOVE_TIME = 0.55
local ARROW_PLAY_TIME = 3

local SCATTER_MOVE_TIME = 0.3

local SCATTER_BAR_TIME = 1

local ROOT_NODE_POSY = 0

local ROOT_NODE_OFF_POSY = 0

local POSEIDON_POSY = 0

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

-- 构造函数
function CodeGameScreenPoseidonMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_triggerRespin = false
    self.m_respinAllFixPos = {}
    self.m_respinNewFixPos = {}
    self.m_isBreakLine = false
    self.m_jackPotBar = nil
    self.m_respinLineNodes = {}
    self.m_respinGroupPos = {}
    self.m_isFeatureOverBigWinInFree = true
	--init
	self:initGame()
end

function CodeGameScreenPoseidonMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
end
--[[
    手动调节 view 节点适配的接口
]]
function CodeGameScreenPoseidonMachine:changeViewNodePos( )

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenPoseidonMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i <= 2 then
            soundPath = "PoseidonSounds/Poseidon_scatter_1.mp3"
        elseif i > 2 and i < 5 then
            soundPath = "PoseidonSounds/Poseidon_scatter_2.mp3"
        else
            soundPath = "PoseidonSounds/Poseidon_scatter_3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

--画出裁剪区域
function CodeGameScreenPoseidonMachine:drawReelArea()
    --    local time = xcyy.SlotsUtil:getMilliSeconds()

    if display.height > DESIGN_SIZE.height then
        local posY = (display.height - DESIGN_SIZE.height) * 0.5
        local sizeY = (display.height / DESIGN_SIZE.height)

        -- local manSize = (1-sizeY) + self:findChild("Node_man"):get
        -- self:findChild("Node_man"):setScale(sizeY)

        self:findChild("Particle_1_0"):setPositionY(self:findChild("Particle_1_0"):getPositionY() - posY)
        self:findChild("Node_goldSea"):setPositionY(self:findChild("Node_goldSea"):getPositionY() - posY)
        self:findChild("Particle_1"):setPositionY(self:findChild("Particle_1"):getPositionY() - posY)
        self:findChild("node_freespin"):setPositionY(self:findChild("node_freespin"):getPositionY() - posY)
        self:findChild("node_ChnangefreespinAnima"):setPositionY(self:findChild("node_ChnangefreespinAnima"):getPositionY() - posY)
        -- self:findChild("Node_1"):setPositionY(self:findChild("Node_1"):getPositionY() - posY)

        self:findChild("Node_bonus_lunpan"):setPositionY(self:findChild("Node_bonus_lunpan"):getPositionY() - posY)
        self:findChild("Node_Light"):setPositionY(self:findChild("Node_Light"):getPositionY() - posY)
        self:findChild("Node_Center"):setPositionY(self:findChild("Node_Center"):getPositionY() - posY)
        self:findChild("Node_Luolei"):setPositionY(self:findChild("Node_Luolei"):getPositionY() - posY)
        self:findChild("node_tittle"):setPositionY(self:findChild("node_tittle"):getPositionY() - posY)

        self:findChild("Node_lunpan"):setPositionY(self:findChild("Node_lunpan"):getPositionY() - posY)
        self:findChild("Node_upreel"):setPositionY(self:findChild("Node_upreel"):getPositionY() - posY)

        self:findChild("Node_1"):setPositionY(self:findChild("Node_1"):getPositionY() - posY)
        self:findChild("light_left"):setPositionY(self:findChild("light_left"):getPositionY() - posY)
        self:findChild("light_right"):setPositionY(self:findChild("light_right"):getPositionY() - posY)

        local nodeJackpot = self:findChild("node_top")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY * 0.5 )
    else
        local posY = (DESIGN_SIZE.height - display.height) * 0.5
        local nodeJackpot = self:findChild("node_top")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY * 0.4 )
    end


    local iColNum = self.m_iReelColumnNum

    -- local stencilParent = cc.Node:create()

    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()

    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1
    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2
        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)

        local parentData = SlotParentData:new()

        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData
    end

    if self.m_clipParent ~= nil then
        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        local nodePos = self.m_clipParent:getParent():convertToNodeSpace(worldPos)
        self.m_slotEffectLayer:setPosition(nodePos)
        self.m_clipParent:getParent():addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(nodePos)
        self.m_clipParent:getParent():addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
        
        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

        
    end
end

function CodeGameScreenPoseidonMachine:addPoseidon(symbolType)
    if  self.m_bigPoseidon ~= nil then
        self.m_bigPoseidon:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(self.m_bigPoseidon.p_symbolType,self.m_bigPoseidon )
    end
    self.m_bigPoseidon = self:getSlotNodeBySymbolType(symbolType)
    self.m_bigPoseidon:runAnim("Poseidon_normal_poseidon", true)
    self.m_csbOwner["Node_man"]:addChild(self.m_bigPoseidon )

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_bigPoseidon.getRotateBackScaleFlag = function(  ) return false end
    end


    self.m_bigPoseidon:setPosition(cc.p(0, POSEIDON_POSY))
    self.m_bigPoseidon:setScale(0.7)

end

function CodeGameScreenPoseidonMachine:checkGameRunPause()
    if self:checkReSpinFrist() then
        return false
    end
    if globalData.slotRunData.gameRunPause == true then
        return true
    else
        return false
    end
end

function CodeGameScreenPoseidonMachine:checkReSpinFrist()
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount or 0
    local curCount = self.m_runSpinResultData.p_reSpinCurCount or 0
    if totalCount == 3 and curCount == 3 then
        return true
    end
end

function CodeGameScreenPoseidonMachine:initUI()

    local  machineRootScale = self.m_machineRootScale
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            self.m_machineRootScale = self.m_machineRootScale - 0.01
            util_csbScale(self.m_machineNode, self.m_machineRootScale)
            -- self.m_machineRootScale = self.m_machineRootScale
        else
            self.m_machineRootScale = self.m_machineRootScale - 0.02
            util_csbScale(self.m_machineNode, self.m_machineRootScale)
            -- self.m_machineRootScale = self.m_machineRootScale
        end
    end

    POSEIDON_POSY = 380
    if display.height > 1550 then
        POSEIDON_POSY = 420
    end
    self:runCsbAction("idle3")

    self.m_jackPotBar = util_createView("CodePoseidonSrc.PoseidonJackPotLayer", self)
    self.m_csbOwner["node_top"]:addChild(self.m_jackPotBar)
    self.m_jackPotBar:setPosition(cc.p(0,0))
    -- self.m_csbOwner["node_top"]:setVisible(false)
    self:addPoseidon(self.m_bigPoseidonAnima2)

    self.m_freeSpinBar = util_createView("CodePoseidonSrc.PoseidonFreeSpinBar", self)
    self.m_csbOwner["node_freespin"]:addChild(self.m_freeSpinBar )
    self.m_freeSpinBar:setVisible(false)

    self.m_freeSpinAnimaBar = util_createView("CodePoseidonSrc.PoseidonFreeSpinBar2", self)
    self.m_csbOwner["node_freespinAnima"]:addChild(self.m_freeSpinAnimaBar )
    self.m_freeSpinAnimaBar:setVisible(false)

    self.m_poseidonTip = self:getSlotNodeBySymbolType(self.m_jpposeidonTip)
    self.m_csbOwner["node_tittle"]:addChild(self.m_poseidonTip )
    self.m_poseidonTip:setVisible(false)

    self.m_jpBar = util_createView("CodePoseidonSrc.PoseidonRespinBottomBar", self)
    self.m_csbOwner["Node_1"]:addChild(self.m_jpBar )
    self.m_jpBar:setVisible(false)
    -- self.m_csbOwner["Node_1"]:setScale(self.m_machineRootScale)

    self.m_lowBetIcon = util_createView("CodePoseidonSrc.PoseidonLowerBetIcon", self)
    self.m_csbOwner["Node_Luolei"]:addChild(self.m_lowBetIcon)
    self.m_lowBetIcon:setPosition(-342.50,311)
    self:setParticleNodeVisible(false)

    self.m_gameBG = util_createView("CodePoseidonSrc.PoseidonGameBg")
    self.m_csbOwner["bg"]:addChild(self.m_gameBG)
    if display.height >= DESIGN_SIZE.height then
        self.m_gameBG:setScale(1/self.m_machineRootScale)
    end

    self.m_leftLamp = util_createView("CodePoseidonSrc.PoseidonLamp", "left")
    -- local pos = self.m_csbOwner["Node_left_lamp"]:getParent():convertToWorldSpace(cc.p(self.m_csbOwner["Node_left_lamp"]:getPosition()))
    -- self:addChild(self.m_leftLamp, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    -- self.m_leftLamp:setPosition(0, display.height - 20)
    self.m_csbOwner["Node_left_lamp"]:addChild(self.m_leftLamp)
    self.m_rightLamp = util_createView("CodePoseidonSrc.PoseidonLamp", "right")
    -- pos = self.m_csbOwner["Node_right_lamp"]:getParent():convertToWorldSpace(cc.p(self.m_csbOwner["Node_right_lamp"]:getPosition()))
    -- self:addChild(self.m_rightLamp, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    -- self.m_rightLamp:setPosition(0, display.height - 20)
    self.m_csbOwner["Node_right_lamp"]:addChild(self.m_rightLamp)
    -- if display.height >= DESIGN_SIZE.height then
    --     self.m_leftLamp:setPositionY(display.height - 120)
    --     self.m_rightLamp:setPositionY(display.height - 120)
    -- end

    --左右跑马灯的适配
         --计算出主轮盘缩的长度
         local disBoundary = 50                 --设一个跑马灯距离边界的距离
         self.m_leftLamp:setPositionY( 210)
         self.m_rightLamp:setPositionY( 210)
         local scaleHalfWildth = math.abs(display.width * (1 - machineRootScale) ) / 2
         if scaleHalfWildth > disBoundary then
             print(self.m_leftLamp:getPosition() .. " " .. self.m_leftLamp:getPosition() )
             local moveX =  (scaleHalfWildth - disBoundary) / machineRootScale
             self.m_leftLamp:setPositionX( -moveX)
             self.m_rightLamp:setPositionX( moveX)
            --  self.m_scaleJackpotView = 1 + moveX / display.width
         end


    self.m_csbOwner["sp_black"]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    self.m_csbOwner["sp_black"]:setVisible(false)

    ROOT_NODE_POSY = self.m_csbOwner["root"]:getPositionY()

    ROOT_NODE_OFF_POSY = ROOT_NODE_POSY - 100

    self.m_effectLayerPos = {}
    self.m_effectLayerPos.x,  self.m_effectLayerPos.y = self.m_slotEffectLayer:getPosition()

    --respin 滚动倒计时
    self.m_RESPIN_RUN_TIME = 0

   
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            self.m_leftLamp:runAnimByName("bigwin", true)
            self.m_rightLamp:runAnimByName("bigwin", true)
            return
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
            return
        end

        self.m_leftLamp:runAnimByName("littlewin", true)
        self.m_rightLamp:runAnimByName("littlewin", true)
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local showTime = 2
        local soundTime = 2
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 2
        elseif winRate > 3 then
            showTime = 3
            soundTime = 3
        end
        local soundName = "PoseidonSounds/music_Poseidon_last_win"..showTime..".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        performWithDelay(self,function()
            self.m_winSoundsId = nil
        end,soundTime)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenPoseidonMachine:initJackpotInfo(jackpotPool,lastBetId)
    self:updateJackpot()
end

function CodeGameScreenPoseidonMachine:updateJackpot()
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 初始化轮盘界面, 已进入游戏时初始化
--
function CodeGameScreenPoseidonMachine:initMachineGame()

end

function CodeGameScreenPoseidonMachine:upDataJpTotleCount()
    self.m_jpBar:upRespinTotleCount(self.m_runSpinResultData.p_reSpinsTotalCount)
end

function CodeGameScreenPoseidonMachine:upDataJpLeftCount()
    self.m_jpBar:upRespinLeftCount(self.m_runSpinResultData.p_reSpinsTotalCount - self.m_runSpinResultData.p_reSpinCurCount)
end

-- 断线重连
function CodeGameScreenPoseidonMachine:MachineRule_initGame(  )
    self.m_isBreakLine = true

    if self.m_bProduceSlots_InFreeSpin == true
    and globalData.slotRunData.currSpinMode ~= RESPIN_MODE
    and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false then
        self.m_freeSpinBar:setVisible(true)
        self.m_freeSpinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount)
    end
end

function CodeGameScreenPoseidonMachine:respinModeChangeSymbolType( )
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPoseidonMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Poseidon"
end

function CodeGameScreenPoseidonMachine:updateReelGridNode(node)
    if node and node.p_symbolType and node.p_symbolType == 101 then
        -- local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {node})
        -- node:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end
end

-- 重写 getSlotNodeWithPosAndType 方法
function CodeGameScreenPoseidonMachine:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)


    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType,iRow,iCol,isLastSymbol)
    local fsTimesNode = reelNode:getChildByName("PoseidonFsTimes")
    if fsTimesNode ~= nil then
        fsTimesNode:removeFromParent()
    end

    if symbolType and symbolType == 101 then

        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        reelNode:runAction(callFun)
    end
    return reelNode
end

function CodeGameScreenPoseidonMachine:setSpecialNodeScore(sender, parma)
    local symbolNode = parma[1]

    if symbolNode.score ~= nil then
        local totleBet = self:BaseMania_getLineBet() * self.m_lineCount
        local  score = symbolNode.score * totleBet
        score = util_formatCoins(score, 6)
        if symbolNode then
            if symbolNode:getCcbProperty("jpScore") then
                symbolNode:getCcbProperty("jpScore"):setString(score)
            end
            symbolNode:runAnim("idleframe")
        end

    end

end


-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPoseidonMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.m_symbolUp1 then
        return "Poseidon_man_blue"
    elseif symbolType == self.m_symbolUp2 then
        return "Poseidon_man_red"
    elseif symbolType == self.m_symbolBlank then
        return "Socre_Poseidon_Blank"
    elseif symbolType == self.m_symbolRepsinSpecial1 then
        return "Poseidon_Respin_Special"
    elseif symbolType == self.m_symbolRepsinSpecial2 then
        return "Poseidon_Respin_Special"
    elseif symbolType == self.m_symbolRepsinSpecial3 then
        return "Poseidon_Respin_Special"
    elseif symbolType == self.m_symbolRepsinSpecial4 then
        return "Poseidon_Respin_Special"
    elseif symbolType == self.m_jackPotScore then
        return "Poseidon_Respin_Score"
    elseif symbolType == self.m_jackPotMini then
        return "Poseidon_Respin_Mini"
    elseif symbolType == self.m_jackPotMinor then
        return "Poseidon_Respin_Minor"
    elseif symbolType == self.m_jackPotMajor then
        return "Poseidon_Respin_Major"
    elseif symbolType == self.m_jackPotGrand then
        return "Poseidon_Respin_Mega"
    elseif symbolType == self.m_jackPoseidon then
        return "Poseidon_Respin_Poseidon"
    elseif symbolType == self.m_featureShowAnima then
        return "Poseidon_GC1"
    elseif symbolType == self.m_featureOverAnima  then
        return "Poseidon_GC2"
    elseif symbolType ==  self.m_jpFixAnima  then
        return "Poseidon_Jackpot_ZJ"
    elseif symbolType == self.m_respinFixAnima then
        return "Poseidon_H1SD"
    elseif symbolType == self.m_upFixAnima then
        return "Poseidon_H1_CX"
    elseif symbolType == self.m_respinLight then
        return "Poseidon_Respin_Light"
    elseif symbolType == self.m_bigPoseidonAnima then
        return "Poseidon_poseidon"
    elseif symbolType == self.m_bigPoseidonAnima2 then
        return "Poseidon_poseidon2"
    elseif symbolType == self.m_jpShowAnima then
        return "Poseidon_GC3"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_Poseidon_Wild"
    elseif symbolType == self.m_arrow then
        return "Poseidon_FirstReel_Fulling_tip"
    elseif symbolType == self.m_scatterAddAnima then
        return "scatter_tc_fsg"
    elseif symbolType == self.m_jpposeidonTip then
        return "Poseidon_tittle"
    elseif symbolType == self.m_jpWinTip then
        return "Poseidon_Score_Bar"
    elseif symbolType == self.m_peseidonChangeBig then
        return "Poseidon_H1_HT"
    end
    return nil
end

function CodeGameScreenPoseidonMachine:getReelHeight()
    return 400
end

function CodeGameScreenPoseidonMachine:getReelWidth()
    return 750
end

function CodeGameScreenPoseidonMachine:getRespinView()
    return "CodePoseidonSrc.PoseidonRespinView"
end

function CodeGameScreenPoseidonMachine:getRespinNode()
    return "CodePoseidonSrc.PoseidonRespinNode"
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPoseidonMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,


    loadNode[#loadNode + 1] = { symbolType = self.m_symbolUp1,count =  10}
    loadNode[#loadNode + 1] = { symbolType = self.m_symbolUp2,count =  10}
    loadNode[#loadNode + 1] = { symbolType = self.m_symbolBlank,count =  10}

    loadNode[#loadNode + 1] = { symbolType = self.m_symbolRepsinSpecial1,count =  10}
    loadNode[#loadNode + 1] = { symbolType = self.m_jackPotScore,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.m_jackPotMini,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.m_jackPotMinor,count =  5}

    loadNode[#loadNode + 1] = { symbolType = self.m_jackPotMajor,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.m_jackPotGrand,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.m_jackPoseidon,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.m_jackPoseidon,count =  5}
    loadNode[#loadNode + 1] = { symbolType = self.m_featureShowAnima,count =  1}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_featureOverAnima,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_jpFixAnima,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_respinFixAnima,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_upFixAnima,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_respinLight,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_bigPoseidonAnima,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_jpShowAnima,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_scatterAddAnima,count =  1}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_jpposeidonTip,count =  1}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_jpWinTip,count =  1}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_peseidonChangeBig,count =  1}

    return loadNode
end

function CodeGameScreenPoseidonMachine:playOutFrameAnima(upTimes)

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_reels_Thunder.mp3")

    self:runCsbAction("actionframe"..tostring(upTimes + 1))
end

function CodeGameScreenPoseidonMachine:setInRespinData()
    --放置随机放置wild

    --放置玩法图标

    self.m_respinNewFixPos = {}


end

function CodeGameScreenPoseidonMachine:playPoseidonShakre()
    local soundName = "PoseidonSounds/music_Poseidon_change_"..math.random(1, 2)..".mp3"
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound(soundName, false, function()
        gLobalSoundManager:setBackgroundMusicVolume(1)
    end)
    self.m_bigPoseidon:runAnim( "Poseidon_powerup_poseidon", false,function()
        self.m_respinView:updataTotleCount()
        self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)
    end)
end

function CodeGameScreenPoseidonMachine:checkPoseidonTriggerRspin()
    self.m_triggerRespin = false

    function getOneReelContinueSymbolCount(beginRow, belowDire, symbolType, col)
        local addNum = 1

        if belowDire == true then
            addNum = -1
        end

        local continueNum = 0

        for iRow = beginRow, addNum do
            if self.m_stcValidSymbolMatrix[iRow][col] == symbolType then
                continueNum = continueNum + 1
            else
                break
            end
        end

        return continueNum
    end

    --是否触发respin
    if getOneReelContinueSymbolCount(1, false, TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, 1) >= MIN_CONTINUE_POSEIDON_COUNT
    or getOneReelContinueSymbolCount(8, true, TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, 1) >= MIN_CONTINUE_POSEIDON_COUNT
    then
        self.m_triggerRespin = true
        self.m_reSpinsTotalCount = 3
        self.m_reSpinCurCount = 3

        local posDatas = self:getOneSymbolPosVec(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
        self.m_respinAllFixPos = clone(posDatas)
        self.m_respinNewFixPos = clone(posDatas)
    end

end


------- just can used in level --
function CodeGameScreenPoseidonMachine:getOneSymbolPosVec(symbolType)
    
    local symbolTypePos = nil
    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = 1, self.m_iReelRowNum, 1 do  -- update on 2020-07-02 之前是从 m_configData.vecColumnCount[iCol] 获取的
            if self.m_stcValidSymbolMatrix[iRow][iCol] == symbolType then
                if symbolTypePos == nil then
                    symbolTypePos = {}
                end
                symbolTypePos[#symbolTypePos + 1] = {iRow, iCol}
            end
        end
    end
    return symbolTypePos
end

----------------------------- 玩法处理 -----------------------------------
-- 修改特殊情况的scatter数量 （网络数据是否用到待验证 --）
---
-- 轮盘停下后 改变数据
--
function CodeGameScreenPoseidonMachine:MachineRule_stopReelChangeData()
    local hasRespin = self:checkHasGameEffectType( GameEffect.EFFECT_RESPIN)
    if hasRespin then
        if self:checkHasGameEffectType( GameEffect.EFFECT_LEVELUP) then
            self:removeGameEffectType(GameEffect.EFFECT_LEVELUP)
        end
    end
end
---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPoseidonMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPoseidonMachine:levelFreeSpinOverChangeEffect()

end

function CodeGameScreenPoseidonMachine:setParticleNodeVisible(isVisble)
    self.m_csbOwner["Particle_1"]:setVisible(isVisble)
    self.m_csbOwner["Particle_1_0"]:setVisible(isVisble)
end

---------------------------------------------------------------------------

-- --裁剪层升高一个小格子高度
-- function CodeGameScreenPoseidonMachine:addMachineClipNodeHeight()
-- end

-- --裁剪层恢复
-- function CodeGameScreenPoseidonMachine:resetMachineClipNodeHeight()
-- end

function CodeGameScreenPoseidonMachine:getBigScatterNode(iX, iY)
    local slotNode = nil
    if self.m_bigSymbolColumnInfo ~= nil and
        self.m_bigSymbolColumnInfo[iY] ~= nil then
        local parentData = self.m_slotParents[iY]
        local slotParent = parentData.slotParent

        local bigSymbolInfos = self.m_bigSymbolColumnInfo[iY]
        for k = 1, #bigSymbolInfos do

            local bigSymbolInfo = bigSymbolInfos[k]

            for changeIndex=1,#bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == iX then

                    slotNode = slotParent:getChildByTag(iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)

                    return slotNode, bigSymbolInfo.changeRows
                end
            end

        end
    end
    assert(false , "getBigScatterNode")
    return slotNode
end



function CodeGameScreenPoseidonMachine:getScatterTimes()
    local freespinTimes = self.m_runSpinResultData.p_fsExtraData.freespinTimes
    local posData = {}
    for i=1,#freespinTimes do
        local times = freespinTimes[i]
        local pos = self:getRowAndColByPos(times[1])
        if posData[pos.iY] == nil then
            posData[pos.iY] = {}
        end
        posData[pos.iY][#posData[pos.iY] + 1] = times[2]
    end
    return posData
end

---
--设置bonus scatter 层级
function CodeGameScreenPoseidonMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 - 10
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
--
function CodeGameScreenPoseidonMachine:showScatterAnima(func)
    local scatterPosData = {}
    local scatterNodes = {}
    local pullAnima = false
    local pullTime = 0

    local playPullScatterAnima = function(direUp, scatterNode, moveNum)
            local moveTime = moveNum * SCATTER_MOVE_TIME
            if pullTime < moveTime then
                pullTime = moveTime
            end
            scatterNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2)


            local callFunc = cc.CallFunc:create(function(  )
                scatterNode:runAnim("buling", false, nil, 20)
            end)

            if direUp == false then
                scatterNode:runAction(cc.Sequence:create( cc.MoveBy:create(moveTime, cc.p(0 , -self.m_SlotNodeH * moveNum) ), callFunc, nil) )
            else
                scatterNode:runAction(cc.Sequence:create(cc.MoveBy:create(moveTime, cc.p(0 , self.m_SlotNodeH * moveNum) ),callFunc , nil) )
            end
            if pullAnima == false then
                pullAnima = true
            end
    end

    local playAddTimeAnima = function (  )

        local scatterTimes =  self:getScatterTimes()
        local changeBarTime = 0
        for i=1,#scatterNodes do
            local col = scatterNodes[i].p_cloumnIndex
            local times = scatterTimes[col]
            local scatterNode = scatterNodes[i]

            performWithDelay(self, function(  )
                release_print("926 ")
                local fsTimesNode = scatterNode:getChildByName("PoseidonFsTimes")
                if fsTimesNode == nil then
                    fsTimesNode = util_createView("CodePoseidonSrc.PoseidonFsTimes")
                    fsTimesNode:setName("PoseidonFsTimes")
                    scatterNode:addChild(fsTimesNode, 2)
                end

                if i == #scatterNodes then
                    local time = scatterNode.fsTimes
                    fsTimesNode:runAnimByName("actionframe1", false , function(  )
                        performWithDelay(self, function (  )
                            release_print("932 ")
                            func()
                            release_print("926 END")
                        end, 2)
                    end, 20)
                else
                    local time = scatterNode.fsTimes
                    fsTimesNode:runAnimByName("actionframe1",false ,function(  )
                    end, 20)

                end

                for j=1,#times do
                    local time = times[j]
                    util_getChildByName(fsTimesNode, "lab_scatter_times"..j):setString("+"..tostring(time))
                    -- scatterNode.fsTimes = time
                    release_print("947 ")
                    performWithDelay(self, function(  )
                        self.m_freeSpinAnimaBar:addFreespinCount(time)
                    end, (j - 1) * SCATTER_BAR_TIME )
                    release_print("947 END")
                end
                release_print("926 ENd")
            end, 3 * (i - 1))
        end

    end

    for iCol=1,self.m_iReelColumnNum do
        local scatterPos = nil
        local scatterNode = nil
        local changeRow = nil
        for iRow=1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if scatterNode == nil then
                    scatterNode, changeRow  = self:getBigScatterNode(iRow, iCol)
                end
                break
            end
        end
        if scatterNode ~= nil then
            scatterNodes[#scatterNodes + 1] = scatterNode
            scatterNode:hideBigSymbolClip()
            local minRow = changeRow[1]
            local maxRow = changeRow[#changeRow]
            local moveNum = 0
            if minRow > 6 then
                moveNum = minRow - 6
                playPullScatterAnima(false, scatterNode, moveNum)
            elseif maxRow < 3 then
                moveNum = 3 - maxRow
                playPullScatterAnima(true, scatterNode, moveNum)
            end
        end

    end

    --播放下
    performWithDelay(self, function(  )
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_trigger_fs.mp3")
    end, pullTime + 0.2)

    performWithDelay(self, function(  )
        release_print("997")
        self.m_freeSpinAnimaBar:setFreeSpinNum("")
        if  self.m_scatterLineValue  ~= nil then
            self:showBonusAndScatterLineTip(self.m_scatterLineValue,function()
                -- self:visibleMaskLayer(true,true)
                self.m_freeSpinAnimaBar:setVisible(true)

                gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_show_fs_AddTimes_view.mp3")

                self.m_freeSpinAnimaBar:runCsbAction("actionframe1",false, function (  )
                    playAddTimeAnima()
                end )

            end)
                --播放动
        else
            self.m_freeSpinAnimaBar:setVisible(true)
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_show_fs_AddTimes_view.mp3")
            self.m_freeSpinAnimaBar:runCsbAction("actionframe1",false, function (  )
                playAddTimeAnima()
            end )
        end
        release_print("997 end")
    end, pullTime + 0.7)

end

function CodeGameScreenPoseidonMachine:showEffect_FreeSpin(effectData)
    self.m_scatterLineValue = nil
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            self.m_scatterLineValue  = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if self.m_scatterLineValue  ~= nil then

        gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
        --
        self:showFreeSpinView(effectData)


        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end


function CodeGameScreenPoseidonMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = #lineValue.vecValidMatrixSymPos
    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent

        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and


            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)

                        break
                    end
                end

            end
        end

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)
            local animaName = slotNode:getLineAnimName()
            animTime = util_max(animTime, slotNode:getAniamDurationByName(animaName) )
        end
    end
    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenPoseidonMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_slotEffectLayer:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_slotEffectLayer:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if slotNode ~= nil then
        local animName = slotNode:getLineAnimName()

        slotNode:runAnim(animName,false)
    end

    return slotNode
end

function CodeGameScreenPoseidonMachine:showFreeSpinView(effectData)


    self:clearCurMusicBg()
    if self.m_iBetLevel == 0 then
        self:hideLowerBetIcon()
    end
    if self.m_isBreakLine then
        self.m_freeSpinBar:setVisible(true)
        self.m_freeSpinAnimaBar:setVisible(false)
        self:playFeatureShowAnima(effectData)
    else
        -- self.m_freeSpinBar:setVisible(false)
        self.m_freeSpinAnimaBar:setVisible(false)
        self.m_freeSpinAnimaBar:setfreeSpinCount(0)
        self.m_freeSpinAnimaBar:setFreeSpinNum("")


        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            self.m_freeSpinBar:runCsbAction("actionframe2",false, function(  )
                self.m_freeSpinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount)
            end)
        else
            self.m_freeSpinBar:setVisible(false)
            self.m_freeSpinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount)

        end

        local function  playScatterAnima(  )
            self:showScatterAnima(function(  )

                if self.m_scatterLineValue ~= nil then
                    self.m_scatterLineValue:clean()
                    self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = self.m_scatterLineValue
                end

                if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                    gLobalSoundManager:playSound("PoseidonSounds/music_HowlingMoon_fs_more.mp3")
                        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()

                            self.m_freeSpinAnimaBar:runCsbAction("actionframe2",false, function (  )
                                self.m_freeSpinAnimaBar:setVisible(false)
                                self.m_freeSpinBar:setVisible(true)
                                self.m_freeSpinBar:runCsbAction("actionframe1")
                                gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_show_fs_AddTimes_view.mp3")

                                effectData.p_isPlay = true
                                self:playGameEffect()

                            end )

                        end,true)
                else
                    -- self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()

                        self.m_freeSpinAnimaBar:runCsbAction("actionframe2",false, function (  )
                            self.m_freeSpinAnimaBar:setVisible(false)
                            -- self.m_freeSpinBar:setVisible(true)
                            -- self.m_freeSpinBar:runCsbAction("actionframe1")
                            self:playFeatureShowAnima(effectData)
                        end )
                    -- end)

                end
            end)
        end


        performWithDelay(self, function (  )
            playScatterAnima(  )
        end, 1)
        --

    end
end

function CodeGameScreenPoseidonMachine:triggerFreeSpin(effectData)

    -- if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    --     gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_enter_fs_view.mp3")
    --     self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()
    --         self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
    --             self.m_freeSpinBar:setVisible(true)
    --             self.m_freeSpinAnimaBar:setVisible(false)
    --             effectData.p_isPlay = true
    --             self:playGameEffect()
    --         end,true)
    --     end)

    -- else
           -- gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_enter_fs_view.mp3")

            self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                self.m_freeSpinBar:setVisible(true)
                self.m_freeSpinAnimaBar:setVisible(false)
                    self:triggerFreeSpinCallFun()

                    effectData.p_isPlay = true
                    self:playGameEffect()
            end)
    -- end

end

function CodeGameScreenPoseidonMachine:getReelMulitipTimes()
    local mulitipTimes =1
    for i=1,#self.m_runSpinResultData.p_reelsData do
        local reels = self.m_runSpinResultData.p_reelsData[i]
        for j=1,#reels do
            local type = reels[j]
            if type == self.m_symbolRepsinSpecial4 then
                mulitipTimes = mulitipTimes + 1
            end
        end
    end
    return mulitipTimes
end

function CodeGameScreenPoseidonMachine:reSpinEffectChange()

end

function CodeGameScreenPoseidonMachine:changeReSpinOverUI()

end

function CodeGameScreenPoseidonMachine:playRsSpecialNodeTip(symbol)
    if self.m_poseidonTip:isVisible() == false then
        self.m_poseidonTip:setVisible(true)
    end

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_show_lab_xiongkou.mp3")

    self.m_poseidonTip:runAnim("actionframe" .. tostring(symbol))
end

function CodeGameScreenPoseidonMachine:removeRespinNode()

    for i=1,self.m_iReelColumnNum do
        local reelChilds = self:getReelParent(i):getChildren()
        for i=1,#reelChilds do
            local  child = reelChilds[i]
            child:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(child.p_symbolType,child )
        end
    end
end

function CodeGameScreenPoseidonMachine:initRespinView(endTypes, randomTypes)

    self.m_respinView:setMachineNode(self)
    self.isInBonus = true
    if  self.m_isBreakLine then
        local poseidonSymbolType = self.m_runSpinResultData.p_rsExtraData.kingSignal
        for i=1,#self.m_runSpinResultData.p_reels do
            local reels = self.m_runSpinResultData.p_reels[i]
            reels[1] = poseidonSymbolType
        end

        local addRowNum = self:getUpSymbolNum()
        self:setUpSymbolInfo(addRowNum)

        --构造盘面数据
        local respinNodeInfo = self:reateRespinNodeInfo()

        --继承重写 改变盘面数据
        self:triggerChangeRespinNodeInfo(respinNodeInfo)
        self.m_respinView:setEndSymbolType(endTypes, randomTypes)
        local  reelHeight = self.m_fReelHeigth + (#self.m_runSpinResultData.p_reelsData - self.m_iReelRowNum) * (self.m_fReelHeigth / 8)

        self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, reelHeight)

        self.m_respinView:setMulitpTimes(self:getReelMulitipTimes())

        if #self.m_runSpinResultData.p_reels > self.m_iReelRowNum then
           self:runCsbAction("idle".. (#self.m_runSpinResultData.p_reels - self.m_iReelRowNum))
        else
           self:runCsbAction("idle")
        end
        self.m_respinView:setIsBreakLine(self.m_isBreakLine)
        self:setAllJpData()
        self.m_respinView:setAllJpData(self.m_runSpinResultData.p_rsExtraData.jackpots)

        self.m_respinView:initRespinElement(
            respinNodeInfo,
            #self.m_runSpinResultData.p_reels,
            self.m_iReelColumnNum,
            function()
                self:reSpinEffectChange()
                self:playRespinViewShowSound()
                self:showReSpinStart(
                    function()
                        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                        -- 更改respin 状态下的背景音乐
                        self:changeReSpinBgMusic()
                        self:runNextReSpinReel()
                    end
                )
            end
        )

        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)
    else
            --修改数据
        self:modifySpinReelsData()
        BaseSlotoManiaMachine.initRespinView(self, endTypes, randomTypes)
    end
        -- self.m_respinView:runAction(cc.OrbitCamera:create(3, 1, 0, 0, -30, 90, 0))

end
function CodeGameScreenPoseidonMachine:setAllJpData()

    local jpInfo = self.m_runSpinResultData.p_rsExtraData.jackpots
    if jpInfo ~= nil then
        for i = 1, #jpInfo do
            local jp  = jpInfo[i]
            local matrixPos = self:getRowAndColByPos(jp.position)
            jpInfo[i].pos = matrixPos
            jpInfo[i].wins = self:getJpWinCoins(jp.type, jp.multiple)
        end
    end

end

function CodeGameScreenPoseidonMachine:reateRespinNodeInfo()
    if  self.m_isBreakLine then
        local respinNodeInfo = {}

        for iCol = 1, self.m_iReelColumnNum do
            local columnData = self.m_reelColDatas[iCol]
            local rowCount = columnData.p_showGridCount
            for iRow = #self.m_runSpinResultData.p_reelsData, 1, -1 do

                --信号类型
                local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

                --层级
                local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
                --tag值
                local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
                --二维坐标
                local arrayPos = {iX = iRow, iY = iCol}

                --世界坐标
                local pos, reelHeight, reelWidth = self:getReelPos(iCol)
                reelHeight = reelHeight + (#self.m_runSpinResultData.p_reelsData - self.m_iReelRowNum) * (reelHeight / 8)
                pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
                local columnData = self.m_reelColDatas[iCol]
                local slotNodeH = columnData.p_showGridH
                pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

                local symbolNodeInfo = {
                    status = RESPIN_NODE_STATUS.IDLE,
                    bCleaning = true,
                    isVisible = true,
                    Type = symbolType,
                    Zorder = zorder,
                    Tag = tag,
                    Pos = pos,
                    ArrayPos = arrayPos
                }
                respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
            end
        end
        return respinNodeInfo
    else
        return BaseSlotoManiaMachine.reateRespinNodeInfo(self)
    end

end

function CodeGameScreenPoseidonMachine:getUpSymbolNum()
    local upNum = 0

    for i=1,#self.m_runSpinResultData.p_reelsData do
        local reels = self.m_runSpinResultData.p_reelsData[i]
        for j=1,#reels do
            local type = reels[j]
            if type == self.m_symbolRepsinSpecial3 then
                upNum = upNum + 1
            end
        end
    end
    return upNum
end

function CodeGameScreenPoseidonMachine:setUpSymbolInfo(upSymbolNum)
    local totleRowNum = self.m_iReelRowNum + upSymbolNum
    if #self.m_runSpinResultData.p_reels < totleRowNum then
        local addReelNum = totleRowNum - #self.m_runSpinResultData.p_reels
        local reels = {0, 0, 0, 0, 0}
        for i=1,addReelNum do
            self.m_runSpinResultData.p_reels[#self.m_runSpinResultData.p_reels + 1] = reels
        end
    end
end

function CodeGameScreenPoseidonMachine:stopRespinRun()
    self:setReduceOneReel()
    local respinStoreIcons = self:getRespinStoreIcons()
    local jpInfo = self:getJpInfo()
    self.m_respinView:setRespinStoreIcons(respinStoreIcons, #self.m_runSpinResultData.p_reels)
    self.m_respinView:setJpInfo(jpInfo)
    local jpPoint = self:getJpPoint()

    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)

    local bUpdataTotleCount = false
    if self.m_runSpinResultData.p_reSpinStoredIcons ~= nil
    and #self.m_runSpinResultData.p_reSpinStoredIcons > 0
    then
        bUpdataTotleCount = true
    end

    local specailRun = false

    if self.m_runSpinResultData.p_reSpinCurCount <= 1
    and self.m_jpBar.m_leftCount + 1 == self.m_jpBar.m_totleCount
    then
        specailRun = true
    end

    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels, bUpdataTotleCount, specailRun)
end

function CodeGameScreenPoseidonMachine:getRespinStoreIcons()
    local respinStoredIcons = self.m_runSpinResultData.p_reSpinStoredIcons or {}

    table.sort( respinStoredIcons, function( a, b )
        local pos1 = self:getRowAndColByPos(a[1])
        local pos2 = self:getRowAndColByPos(b[1])

        if pos1.iY ~= pos2.iY then
            return pos1.iY < pos2.iY
        else
            return pos1.iX > pos2.iX
        end
     end )

    local allStoredIcons = self.m_runSpinResultData.p_storedIcons or {}

    local adjacentDiff = {6, 5, 4, 1}
    local changePosInfo = {}

    local isAjacent = function(pos, centerPos)
        if (centerPos % self.m_iReelColumnNum  == 4 and pos % self.m_iReelColumnNum == 0)
        or (centerPos % self.m_iReelColumnNum  == 0 and pos % self.m_iReelColumnNum == 4)
        then
            return false
        end
        local reveseAdjacentDiff = {}
        for i=1, #adjacentDiff do
            reveseAdjacentDiff[adjacentDiff[i]] = i
        end

        local diff = math.abs( centerPos - pos )
        if reveseAdjacentDiff[diff] ~= nil then
            return true
        end

        return false
    end

    local getReelRowDate = function(pos)
        local reels =  self.m_runSpinResultData.p_reels
        local row = math.ceil( (pos + 1) / self.m_iReelColumnNum )
        return reels[row] , (pos + 1) -  (row - 1) * self.m_iReelColumnNum
    end

    local getAjacentPos = function(posId)
        local endId = #self.m_runSpinResultData.p_reels * self.m_iReelColumnNum - 1
        local ajacentPos = {}

        for i=0,endId do
            if isAjacent(i, posId) then
                ajacentPos[#ajacentPos + 1] = i
            end
        end

        return ajacentPos
    end

    local inRespinStoreIcons = function(icons)
        for i=1, #respinStoredIcons do
            local respinIcons = respinStoredIcons[i]
            if respinIcons[1] == icons[1]
            and respinIcons[2] == icons[2]
            then
                return true
            end
        end
        return false
    end

    local removeStoreIcons = function(idx)

        for i=1, #allStoredIcons do
            local icons = allStoredIcons[i]
            if icons[1] == idx
            and icons[2] ~= self.m_symbolRepsinSpecial1
            and icons[2] ~= self.m_symbolRepsinSpecial2
            and icons[2] ~= self.m_symbolRepsinSpecial3
            and icons[2] ~= self.m_symbolRepsinSpecial4
            and inRespinStoreIcons(icons) == false
            then

                table.remove( allStoredIcons, i)
                return true
            end
        end
        return false
    end

    local bChangeAjacent = function( pos )

        for i=1, #respinStoredIcons do
            local icons = respinStoredIcons[i]

            if  pos == icons[1]
            and icons[2] ~= self.m_symbolRepsinSpecial1
            and icons[2] ~= self.m_symbolRepsinSpecial2
            and icons[2] ~= self.m_symbolRepsinSpecial3
            and icons[2] ~= self.m_symbolRepsinSpecial4
             then
                return true
            end
        end
        return false
    end

    for i=1, #respinStoredIcons do
        local icons = respinStoredIcons[i]
        if icons[2] == self.m_symbolRepsinSpecial2 then

            local pos = {}
            local centerPos = icons[1]
            pos[#pos + 1] = centerPos

            local allAjacentPos = getAjacentPos(centerPos)


            for j=1, #allAjacentPos do
                local ajacentPos = allAjacentPos[j]

                if removeStoreIcons(ajacentPos) then
                    --先变为100
                    local rowDate , index = getReelRowDate(ajacentPos)
                    rowDate[index] = self.m_symbolBlank
                    pos[#pos + 1] = ajacentPos
                end

            end

            -- for j=1, #respinStoredIcons do
            --     local storeIcons = respinStoredIcons[j]

            --     if storeIcons[2] == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
            --     or storeIcons[2] == self.m_symbolUp1
            --     or storeIcons[2] == self.m_symbolUp2
            --     then
            --         if isAjacent( storeIcons[1], centerPos)
            --         then
            --             local rowDate , index = getReelRowDate(storeIcons[1])
            --             rowDate[index] = storeIcons[2]
            --             local icons = {storeIcons[1], storeIcons[2]}
            --             allStoredIcons[#allStoredIcons] = icons

            --             for z=1, #pos do
            --                 local id = pos[z]
            --                 if id == storeIcons[1] then
            --                     table.remove( pos, z )
            --                 end
            --             end

            --         end
            --     end
            -- end
            changePosInfo[#changePosInfo + 1] = pos
        end
    end

    table.sort( allStoredIcons, function( a, b )
       return a[1] < b[1]
    end )

    return changePosInfo
end

function CodeGameScreenPoseidonMachine:setBigPoseidonScaleAnima(time)
    -- setScale(1)
    local scale =  self.m_bigPoseidon:getScale()
    self.m_bigPoseidon:runAction(cc.ScaleTo:create(time, scale - 0.035))

end

function CodeGameScreenPoseidonMachine:getJpWinCoins(type, multiple)
    local winCoins = 0
    if type == "normal" then
            local lineBet = self:BaseMania_getLineBet()
            winCoins = multiple * lineBet * self.m_lineCount
    elseif type == "mini" then
            winCoins = self:BaseMania_getJackpotScore(5)
    elseif type == "minor" then
            winCoins = self:BaseMania_getJackpotScore(4)
    elseif type == "major" then
            winCoins = self:BaseMania_getJackpotScore(3)
    elseif type == "mega" then
            winCoins = self:BaseMania_getJackpotScore(2)
    elseif type == "grand" then
            winCoins = self:BaseMania_getJackpotScore(1)
    end
    return winCoins
end

function CodeGameScreenPoseidonMachine:getJpInfo()
    local jpInfo = {}
    local respinExtraData = self.m_runSpinResultData.p_rsExtraData.jackpots
    local respinFixData = self.m_runSpinResultData.p_reSpinStoredIcons
    if respinFixData == nil then
        return nil
    end

    for j=1,#respinFixData do
        local fixData = respinFixData[j]
        if fixData[2] == self.m_symbolRepsinSpecial1 then
            local jp = {}

            for i=1,#respinExtraData do
                local data = respinExtraData[i]

                if fixData[1] == data.position then

                    local score = self:getJpWinCoins( data.type, data.multiple)
                    local oneJp = {type = data.type , multiple = data.multiple , score = score}
                    jp[#jp + 1] = oneJp
                end
            end

            jpInfo[#jpInfo + 1] = jp

        end

    end


    return jpInfo
end

--判断是否减去一行数据
function CodeGameScreenPoseidonMachine:setReduceOneReel()
    local upNum = 0
    local nowStoredIcons = self.m_runSpinResultData.p_reSpinStoredIcons or {}
    for i=1,#nowStoredIcons do

        local icon = nowStoredIcons[i]
        if icon[2] == self.m_symbolRepsinSpecial3 then
            upNum = upNum + 1
        end
    end
    for i=1,upNum do
        table.remove( self.m_runSpinResultData.p_reels, #self.m_runSpinResultData.p_reels)
    end
end


function CodeGameScreenPoseidonMachine:getUpSymbolCount()
    local upType = 0

    if self.m_runSpinResultData.p_reSpinStoredIcons then
        for i=1,#self.m_runSpinResultData.p_reSpinStoredIcons do
            local icons = self.m_runSpinResultData.p_reSpinStoredIcons
            if icons[2] == self.m_symbolRepsinSpecial3 then
                upType = upType + 1
            end
        end
    end
    return upType
end

function CodeGameScreenPoseidonMachine:getRowAndColByPos(posData)
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE  then
       return BaseSlotoManiaMachine.getRowAndColByPos(self,posData)
    end
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum
    local upTypeNum = self:getUpSymbolCount()
    local rowIndex = #self.m_runSpinResultData.p_reels - upTypeNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

function CodeGameScreenPoseidonMachine:getJpPoint()

    -- if jpAllData == nil then
    --     local jpAllData = self.m_runSpinResultData.p_rsExtraData.jackpotsAll

    -- end
end


function CodeGameScreenPoseidonMachine:getRespinSpinData()

    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local storedInfo = {}

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        if storedIcons[i][2] == 1002 then
           local a = 1
        end
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = storedIcons[i][2]}
    end

    return storedInfo
end

function CodeGameScreenPoseidonMachine:getRespinReelsButStored(storedInfo)
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE  then
        return BaseMachine.getRespinReelsButStored(self,storedInfo)
    end
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and  storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    local upTypeNum = self:getUpSymbolCount()

    function getMatrixPosSymbolType(iRow, iCol)
        local rowCount = #self.m_runSpinResultData.p_reels - upTypeNum
        for rowIndex = 1, rowCount do
            local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
            local colCount = #rowDatas

            for colIndex = 1, colCount do
                if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                    return rowDatas[colIndex]
                end
            end
        end
    end



    for iRow = #self.m_runSpinResultData.p_reels - upTypeNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
           local type = getMatrixPosSymbolType(iRow, iCol)
           if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
           end
        end
    end
    return reelData
end

function CodeGameScreenPoseidonMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    local freespinStart = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    freespinStart:addClick(freespinStart:findChild("Panel_2"))

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)


end

function CodeGameScreenPoseidonMachine:pushFrameToPool(node)
end

function CodeGameScreenPoseidonMachine:clearFrameNodes()
    for i = #self.m_framePool, 1, -1 do
        self.m_framePool[i] = nil
    end
end

function CodeGameScreenPoseidonMachine:showFreeSpinOverView()
    performWithDelay(self, function (  )
            -- 取消掉赢钱线的显示
        self.m_freeSpinBar:runCsbAction("actionframe2", false , function(  )
            self:clearWinLineEffect()
            self.m_freeSpinBar:setVisible(false)
            release_print("globalData.slotRunData.lastWinCoin " .. globalData.slotRunData.lastWinCoin)


            self:triggerFreeSpinOver(effectData)
        end)
    end, 1)


end

--触发respin
function CodeGameScreenPoseidonMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView)

    self:initRespinView(endTypes, randomTypes)

end

function CodeGameScreenPoseidonMachine:triggerFreeSpinOver(effectData)

    -- gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_freespin_over_view.mp3")
    local strCoins= globalData.slotRunData.lastWinCoin -- util_formatCoins(,30)
    local view = self:showFreeSpinOver( strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            local node = self:getSlotNodeBySymbolType(self.m_featureShowAnima)

            gLobalViewManager.p_ViewLayer:addChild(node)
            local pos =gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(display.width/2,display.height/2))
            node:setPosition(pos)
            if 0 == self.m_iBetLevel then
                self:showLowerBetIcon()
            end
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_GC_ShuiWoXuan.mp3")
            node:runAnimFrame("Poseidon_normal_freespin",false,"show_view",function()

                self.m_gameBG:runAnimByName("normal")
                self:addPoseidon(self.m_bigPoseidonAnima2)
                self:setParticleNodeVisible(false)
            end, function()
                self:triggerFreeSpinOverCallFun()

                node:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType,node )
            
                
            end)
    end)

    local node=view:findChild("m_lb_coins")
    local nodeTip=view:findChild("m_lb_fsover_tip_0")
    nodeTip:setString(self.m_runSpinResultData.p_freeSpinsTotalCount)
    view:updateLabelSize({label=node,sx=1,sy=1},559)
end

function CodeGameScreenPoseidonMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_freespin_over_view.mp3")

    local view = util_createView("CodePoseidonSrc.PoseidonFreespinOverView")
    view:initViewData(coins,num,func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node},559)

    return view
end


function CodeGameScreenPoseidonMachine:showReSpinStart(func)
    performWithDelay(self, function(  )
        release_print("1829")
        func()
        release_print("1829 end")
    end, 0.3)
    -- performWithDelay(self, function(  )
    --     self:clearCurMusicBg()
    --     local respinStartView = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func)
    --     respinStartView:addClick(respinStartView:findChild("Panel_2"))
    -- end, 1)
end

function CodeGameScreenPoseidonMachine:playChangeBigPoseidonAnima()
    release_print("playChangeBigPoseidonAnima 1")
    local firstNodePos = nil
    local reelParent = self:getReelParent(1)
    local tag = self:getNodeTag(1, 1, SYMBOL_NODE_TAG)
    if reelParent and tag then
        release_print("playChangeBigPoseidonAnima 2")
        local sp = reelParent:getChildByTag(tag)
        if sp then
            release_print("playChangeBigPoseidonAnima 3")
            firstNodePos = {x=0,y=0}
            firstNodePos.x, firstNodePos.y = sp:getPosition()
        end
    end
    if not firstNodePos then
        release_print("playChangeBigPoseidonAnima 4")
        return
    end
    release_print("playChangeBigPoseidonAnima 5")
    local animaTime = 0

    local unPoseidonPos = {}
    for iRow=1, self.m_iReelRowNum do
        if self.m_stcValidSymbolMatrix[iRow][1] ~= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            local pos = {iX = iRow,iY = 1}
            unPoseidonPos[#unPoseidonPos + 1] = pos
        end
    end

    local arrowMartixPos = nil
    if #unPoseidonPos ~= 0 then
        if #unPoseidonPos == 1 then
            arrowMartixPos = {iX = unPoseidonPos[1].iX, iY = 1}
        else
            for i=1,#unPoseidonPos do
                local pos = unPoseidonPos[i]
                if pos.iX == 2
                or pos.iX == 7
                then
                    arrowMartixPos = {iX = pos.iX, iY = 1}
                    break
                end
            end
        end
    end

    local firstNode = nil
    local arrowSymbol = nil
    if arrowMartixPos == nil then
        animaTime = 1
        firstNode = self:getReelParent(1):getChildByTag(self:getNodeTag(1, 1, SYMBOL_NODE_TAG))
        self.m_poseidonMoveDelay = 0
    else
        arrowSymbol = self:getSlotNodeBySymbolType(self.m_arrow)
        -- local targSp = self:getReelParent(1):getChildByTag(self:getNodeTag(1, arrowMartixPos.iX, SYMBOL_NODE_TAG))
        arrowSymbol:setPosition(cc.p(self.m_fReelWidth , -self:getReelParent(1):getPositionY() + self.m_fReelHeigth / 2))
        self:getReelParent(1):addChild(arrowSymbol,10000000)
        arrowSymbol:runAnim("actionframe2", true)

        local direUp = false
        if arrowMartixPos.iX >= 7 then
            arrowSymbol:setScaleY(-1)
            direUp = true
        else
            arrowSymbol:setScaleY(1)
        end

        local allNode = {}
        -- allNode[#allNode + 1] = arrowSymbol



        if direUp then
            local createNum = self.m_iReelRowNum - arrowMartixPos.iX + 1
            local firstSp = self:getReelParent(1):getChildByTag(self:getNodeTag(1, 1, SYMBOL_NODE_TAG))
            for i=1,createNum do
                local symbol = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
                symbol:setPosition(cc.p(firstSp:getPositionX(), firstSp:getPositionY() - self.m_SlotNodeH * i ))
                self:getReelParent(1):addChild(symbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                allNode[#allNode + 1] = symbol

                firstNode = symbol
            end

            for i=1,self.m_iReelRowNum do
                local node = self:getReelParent(1):getChildByTag(self:getNodeTag(1, i, SYMBOL_NODE_TAG))
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - i)
                allNode[#allNode + 1] = node
            end

            for i=1,#allNode do
                local node = allNode[i]
                local moveAction = cc.MoveBy:create( MOVE_TIME , cc.p(0, self.m_SlotNodeH * createNum))
                local delayAction = cc.DelayTime:create(ARROW_PLAY_TIME)
                -- node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2)
                local hide = cc.Hide:create()
                node:runAction(cc.Sequence:create(delayAction, moveAction, hide))
            end
        else
            local createNum = arrowMartixPos.iX
            local lastSp = self:getReelParent(1):getChildByTag(self:getNodeTag(1, self.m_iReelRowNum, SYMBOL_NODE_TAG))
            for i=1,createNum do
                local symbol = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
                symbol:setPosition(cc.p(lastSp:getPositionX(), lastSp:getPositionY() + self.m_SlotNodeH * i ))
                self:getReelParent(1):addChild(symbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                allNode[#allNode + 1] = symbol
            end

            for i= 1, self.m_iReelRowNum do
                local node = self:getReelParent(1):getChildByTag(self:getNodeTag(1, i, SYMBOL_NODE_TAG))
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - i)
                allNode[#allNode + 1] = node
            end

            for i=1,#allNode do
                local node = allNode[i]

                local moveAction = cc.MoveBy:create( MOVE_TIME , cc.p(0, -self.m_SlotNodeH *createNum))
                -- node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2)
                local delayAction = cc.DelayTime:create(ARROW_PLAY_TIME)
                local hide = cc.Hide:create()
                node:runAction(cc.Sequence:create(delayAction, moveAction, hide))
            end
            firstNode = self:getReelParent(1):getChildByTag(self:getNodeTag(1, arrowMartixPos.iX + 1, SYMBOL_NODE_TAG))
        end
        animaTime =  ARROW_PLAY_TIME + MOVE_TIME
        self.m_poseidonMoveDelay = 0.7
    end

    -- gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_down_H1.mp3")

    performWithDelay(self, function(  )
        -- firstNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + self.m_iReelRowNum)
        -- firstNode:runAnim("idleframe7")
        release_print("1953")

        local childs = self:getReelParent(1):getChildren()
        for i=1,#childs do
            local child = childs[i]
            child:setVisible(false)
        end

        local posWorld = self:getReelParent(1):convertToWorldSpace(cc.p(firstNodePos.x, firstNodePos.y + self:getReelHeight() / 2 + self.m_SlotNodeH))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

        local changeBigNode = self:getSlotNodeBySymbolType(self.m_peseidonChangeBig)
        self.m_clipParent:addChild(changeBigNode, REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10)
        changeBigNode:setPosition(pos)

        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_move_chang.mp3")

        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_H1_HeTu.mp3")

        changeBigNode:runAnim("actionframe", false, function(  )

            local node = self:getSlotNodeBySymbolType(self.m_featureShowAnima)

            gLobalViewManager.p_ViewLayer:addChild(node)
            local pos =gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(display.width/2,display.height/2))
            node:setPosition(pos)

            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_GC_ShuiWoXuan.mp3")

            node:runAnimFrame("Poseidon_normal_freespin",false,"show_view",function()

                if self.m_bProduceSlots_InFreeSpin then
                    self.m_gameBG:runAnimByName("respinBGLight", true)
                else
                    self.m_gameBG:runAnimByName("respinBGLight", true)
                end
                self.m_leftLamp:runAnimByName("lighting", true)
                self.m_rightLamp:runAnimByName("lighting", true)
                self:runCsbAction("idle")
                self:addPoseidon(self.m_bigPoseidonAnima)
                self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)
                self:setRootNodeOffPos()
                self.m_jpBar:setVisible(true)
                self.m_jpBar:setRespinCount(self.m_runSpinResultData.p_reSpinsTotalCount - self.m_runSpinResultData.p_reSpinCurCount,  self.m_runSpinResultData.p_reSpinsTotalCount)
                self.m_bottomUI:setVisible(false)

                local slotParentDatas = self.m_slotParents

                for index = 1, #slotParentDatas do
                    local parentData = slotParentDatas[index]
                    local slotParent = parentData.slotParent
                    slotParent:setPositionY(parentData.moveDistance)
                end

                changeBigNode:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(changeBigNode.p_symbolType,changeBigNode )

                self:reelSchedulerHanlder(0)
            end, function()

                node:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)

            end)
        end)

        release_print("1953 end")

    end, animaTime)



    animaTime = animaTime + 3
    return animaTime
end
-- RespinView
function CodeGameScreenPoseidonMachine:showRespinView(effectData)
    self:setParticleNodeVisible(true)

    if self.m_bProduceSlots_InFreeSpin ~= true and self.m_iBetLevel == 0 then
        self:hideLowerBetIcon()
    end
    if  self.m_isBreakLine then
        self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)


        --先播放动画 再进入respin
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_goin_lightning.mp3")

        self:playFeatureShowAnima(effectData)
    else
        --播放向下的动画
        -- local time = self:playChangeBigPoseidonAnima()
        -- local time = 0
        performWithDelay(self, function (  )

            self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)


            --先播放动画 再进入respin
            self:clearCurMusicBg()
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_goin_lightning.mp3")

            self:playFeatureShowAnima(effectData)
        -- end, 0)
        end, self.m_poseidonMoveDelay)
    end

end

function CodeGameScreenPoseidonMachine:modifySpinReelsData()
    for i=1,#self.m_runSpinResultData.p_reels do
        local reels = self.m_runSpinResultData.p_reels[i]
        for i=2,#reels do
            reels[i] = self.m_symbolBlank
        end
        reels[1] = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
    end
end

function CodeGameScreenPoseidonMachine:triggerRespinView(effectData)

    -- local rootNode = self.m_csbOwner["root"]
    -- rootNode:setPositionY(-100)
    -- self.m_bottomUI:setPositionY(-200)
     --可随机的普通信息
     local randomTypes =
     {
         TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
         self.m_symbolBlank,
         self.m_symbolRepsinSpecial1,
     }

     --可随机的特殊信号
     local endTypes =
     {
         {type = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, runEndAnimaName = "", bRandom = true},
         {type = self.m_symbolRepsinSpecial1, runEndAnimaName = "", bRandom = true},
         {type = self.m_symbolRepsinSpecial2, runEndAnimaName = "", bRandom = true},
         {type = self.m_symbolRepsinSpecial3, runEndAnimaName = "", bRandom = true},
         {type = self.m_symbolRepsinSpecial4, runEndAnimaName = "", bRandom = true},
         {type = self.m_symbolUp1, runEndAnimaName = "", bRandom = false},
         {type = self.m_symbolUp2, runEndAnimaName = "", bRandom = false},
     }


     --播放feature 过场动画

     --构造盘面数据
    --  performWithDelay(self,function()

        self.m_freeSpinBar:setVisible(false)
        self.m_freeSpinAnimaBar:setVisible(false)

         if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
             self:triggerReSpinCallFun(endTypes, randomTypes)
         else
         -- 由玩法触发出来， 而不是多个元素触发
             if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                 self.m_runSpinResultData.p_reSpinCurCount = 3
              end
             self:triggerReSpinCallFun(endTypes, randomTypes)
     end

    --  end
    --  ,1)
end

function CodeGameScreenPoseidonMachine:setRootNodeOffPos()
    self.m_csbOwner["root"]:setPosition(cc.p(self.m_csbOwner["root"]:getPositionX(),ROOT_NODE_OFF_POSY))
    self.m_jackPotBar:setPosition(cc.p(0, 100))
    self.m_gameBG:setPosition(cc.p(0, 100))
end

function CodeGameScreenPoseidonMachine:resetRootNodePos()
    self.m_csbOwner["root"]:setPosition(cc.p(self.m_csbOwner["root"]:getPositionX(),ROOT_NODE_POSY))
    self.m_jackPotBar:setPosition(cc.p(0,0))
    self.m_gameBG:setPosition(cc.p(0, 0))
end

function CodeGameScreenPoseidonMachine:playFeatureShowAnima(effectData)

    if effectData.p_effectType == GameEffect.EFFECT_RESPIN then
        if  self.m_isBreakLine then
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_GC_ShuiWoXuan.mp3")

            local node = self:getSlotNodeBySymbolType(self.m_featureShowAnima)

            gLobalViewManager.p_ViewLayer:addChild(node)
            local pos =gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(display.width/2,display.height/2))
            node:setPosition(pos)
            node:runAnimFrame("Poseidon_normal_freespin",false,"show_view",function()

                if self.m_bProduceSlots_InFreeSpin then
                    self.m_gameBG:runAnimByName("respinBGLight", true)
                else
                    self.m_gameBG:runAnimByName("respinBGLight", true)
                end
                self:addPoseidon(self.m_bigPoseidonAnima)
                self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)
                self:triggerRespinView(effectData)
                self:setRootNodeOffPos()
                self.m_jpBar:setVisible(true)
                self.m_jpBar:setRespinCount( self.m_runSpinResultData.p_reSpinsTotalCount - self.m_runSpinResultData.p_reSpinCurCount,  self.m_runSpinResultData.p_reSpinsTotalCount)
                self.m_bottomUI:setVisible(false)
            end, function()

                node:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
                
            end)
        else

            if self.m_bProduceSlots_InFreeSpin then
                self.m_gameBG:runAnimByName("respinBGLight", true)
            else
                self.m_gameBG:runAnimByName("respinBGLight", true)
            end
            self:addPoseidon(self.m_bigPoseidonAnima)
            self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)
            self:triggerRespinView(effectData)
        end
        self.m_leftLamp:runAnimByName("lighting", true)
        self.m_rightLamp:runAnimByName("lighting", true)
    elseif effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN then

        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_GC_ShuiWoXuan.mp3")

        local node = self:getSlotNodeBySymbolType(self.m_featureShowAnima)

        gLobalViewManager.p_ViewLayer:addChild(node)
        local pos =gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(display.width/2,display.height/2))
        node:setPosition(pos)

        node:runAnimFrame("Poseidon_normal_freespin",false,"show_view",function()
        end, function()

            self.m_gameBG:runAnimByName("freespin")

            self:addPoseidon(self.m_bigPoseidonAnima2)

            self:setParticleNodeVisible(true)

            self.m_freeSpinBar:setVisible(true)
            self.m_freeSpinBar:runCsbAction("actionframe1")
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_show_fs_AddTimes_view.mp3")
            
            node:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
            
            self:triggerFreeSpin(effectData)

        end)

    end

end

function CodeGameScreenPoseidonMachine:playFeatureOverAnima(type)

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_GC_ShuiWoXuan.mp3")

    local node = self:getSlotNodeBySymbolType(self.m_featureShowAnima)

    gLobalViewManager.p_ViewLayer:addChild(node)
    local pos =gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(display.width/2,display.height/2))
    node:setPosition(pos)

    node:runAnimFrame("Poseidon_normal_freespin",false,"show_view",function()
        if type == GameEffect.EFFECT_RESPIN_OVER then

            BaseMachine.removeRespinNode(self)

            if self.m_bProduceSlots_InFreeSpin then
                self.m_gameBG:runAnimByName("rs_freespin")
                self:setParticleNodeVisible(true)
                self:addPoseidon(self.m_bigPoseidonAnima2)
            else
                self:setParticleNodeVisible(false)
                self.m_gameBG:runAnimByName("normal")
                self:addPoseidon(self.m_bigPoseidonAnima2)
            end
            self.m_leftLamp:runIdleFram()
            self.m_rightLamp:runIdleFram()
            self:resetRootNodePos()
            self.m_jpBar:setVisible(false)
            self.m_bottomUI:setVisible(true)
            self:triggerRespinOver()
            self.m_respinWinCoinsBar:setVisible(false)

        elseif type == GameEffect.EFFECT_FREE_SPIN_OVER then


        end
    end,function()

        node:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(node.p_symbolType,node )
    

    end)
end

function CodeGameScreenPoseidonMachine:respinOver()
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    self.m_respinGroupPos = {}

    local oneGroupPos = {}
    for j = 1, self.m_iReelColumnNum do

        local allColNode = {}

        for i=1,#allEndNode do
            local node = allEndNode[i]
            if node.p_cloumnIndex == j then
                allColNode[#allColNode + 1] = node
            end
        end

        table.sort( allColNode, function(a, b)
            return a.p_rowIndex < b.p_rowIndex
        end)

        local adjantNum = 0
        local firstNode = nil
        for n=1, #allColNode do
            local colNode = allColNode[n]
            if firstNode == nil then
                firstNode = colNode

                oneGroupPos[#oneGroupPos + 1] = {iX =firstNode.p_rowIndex , iY = firstNode.p_cloumnIndex }
            end

            if colNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
            or colNode.p_symbolType == self.m_symbolUp1
            or colNode.p_symbolType == self.m_symbolUp2
            then
                colNode:runAnim("idleframe0")
            end

            if colNode.p_symbolType ~= self.m_symbolBlank
            and  colNode.p_symbolType ~= self.m_symbolRepsinSpecial1
            then
                if adjantNum >= 1 then
                    colNode:setVisible(false)
                    oneGroupPos[#oneGroupPos + 1] = {iX =colNode.p_rowIndex , iY = colNode.p_cloumnIndex }
                end

                adjantNum = adjantNum + 1
            end

            if n == #allColNode
            or  colNode.p_symbolType == self.m_symbolBlank
            or  colNode.p_symbolType == self.m_symbolRepsinSpecial1
            then
                if adjantNum > 1 then
                    if self.m_respinGroupPos == nil then
                        self:replaceRespinNode(firstNode, adjantNum, true)
                    else
                        self:replaceRespinNode(firstNode, adjantNum)
                    end
                    self.m_respinGroupPos[#self.m_respinGroupPos + 1] = oneGroupPos

                end

                if adjantNum == 1
                and firstNode.p_symbolType ~= self.m_symbolRepsinSpecial1
                then
                    if self.m_respinGroupPos == nil then
                        self:replaceRespinNode(firstNode, adjantNum, true)
                    else
                        self:replaceRespinNode(firstNode, adjantNum)
                    end
                    self.m_respinGroupPos[#self.m_respinGroupPos + 1] = oneGroupPos
                end

                oneGroupPos =  {}

                adjantNum = 0
                firstNode = nil
            end

        end
        local adjantNum = 0
        local firstNode = nil
        oneGroupPos =  {}
    end


    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_reels_Thunder.mp3")
    local upTimes =  self.m_respinView:getUpTimes()
    self:runCsbAction("actionframe"..tostring(upTimes + 1).."_2")

    performWithDelay(self, function (  )
        release_print("2250 ")
        self:playRespinOverWinsAnima()
        self:showRespinWinCoinsAnima()
        release_print("2250 end")
    end, 2)

    performWithDelay(self, function (  )
        release_print("2257 ")
        self:stopEffectLayerAction()
        self:resetLineNodeParent()
        release_print("2257 end")
    end, 6)

    performWithDelay(self, function (  )
        release_print("2267 ")
        BaseMachine.respinOver(self)
        release_print("2267 end")
    end, 8.5)

end

function CodeGameScreenPoseidonMachine:replaceRespinNode(node, adjantNum,isPlaySound)
    if isPlaySound then
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_H1_HeTu.mp3")
    end

    if node.p_symbolType == self.m_symbolRepsinSpecial4
    or node.p_symbolType == self.m_symbolRepsinSpecial2
    or node.p_symbolType == self.m_symbolRepsinSpecial3
    then
        local nowType = self.m_respinView:getSpecialSymbolType()
        node = self.m_respinView:replaceFixSymbolNode(node, nowType)
    end
    self.m_respinView:removeBigSymolNode()
    node:setVisible(true)
    node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4)
    node:runAnim("idleframe"..adjantNum - 1)
end

function CodeGameScreenPoseidonMachine:playRespinOverWinsAnima()
    --提升层级播放动画
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    local winLines = self.m_runSpinResultData.p_winLines



    local allPos = {}
    self.m_respinLineNodes ={ }
    for i = 1, #winLines do
        local line = winLines[i]
        for j = 1, #line.p_iconPos do
            local posId = line.p_iconPos[j]
            if allPos[posId] == nil then
                allPos[posId] = 1
            end
        end
    end

    for i=1, #self.m_respinGroupPos do
        local oneGroupPos = self.m_respinGroupPos[i]
        for j=1, #oneGroupPos do
            local pos = oneGroupPos[j]
            local posId = (#self.m_runSpinResultData.p_reels - pos.iX) * self.m_iReelColumnNum + (pos.iY - 1)
            if allPos[posId] ~= nil then
                -- for n=1,#oneGroupPos do
                    local posTmp = oneGroupPos[1]
                    local posIdTmp = (#self.m_runSpinResultData.p_reels - posTmp.iX) * self.m_iReelColumnNum + (posTmp.iY - 1)
                    if allPos[posIdTmp] == nil then
                        allPos[posIdTmp] = 1
                    end
                -- end
            end
        end
    end

    for i=1,#allEndNode do
        local node = allEndNode[i]

        local id = (#self.m_runSpinResultData.p_reels - node.p_rowIndex) * self.m_iReelColumnNum + (node.p_cloumnIndex - 1)

        if allPos[id] ~= nil
        and node.p_symbolType ~= self.m_symbolRepsinSpecial1 then

            self.m_respinLineNodes[# self.m_respinLineNodes + 1] = node

            self:changeParentNode(node,  self.m_slotEffectLayer)

        end
    end
    self:runEffectLayerAction()
end

function CodeGameScreenPoseidonMachine:showRespinWinCoinsAnima()

    if  self.m_respinWinCoinsBar == nil then
        self.m_respinWinCoinsBar = self:getSlotNodeBySymbolType(self.m_jpWinTip)
        self.m_respinWinCoinsBar:setPositionY(0)
        self.m_csbOwner["Node_2"]:addChild(self.m_respinWinCoinsBar)
        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_respinWinCoinsBar.getRotateBackScaleFlag = function(  ) return false end
        end

    end
    self.m_jpBar:setVisible(false)
    self.m_respinWinCoinsBar:setVisible(true)
    self.m_respinWinCoinsBar:runAnim("idleframe", true)


    local winLab = self.m_respinWinCoinsBar:getCcbProperty("m_ll_coins")

    local coins = self.m_serverWinCoins
    local baseCoins = 0

    -- local addValue=(coins-baseCoins)*0.05+math.random(1,9)+math.random(1,9)*10+math.random(1,9)*100
    -- local addBaseValue = coins / 40
    -- util_jumpNum(winLab,0,coins,addBaseValue,0.05,{90})
    self:updateLabelSize({label = winLab ,sx=self.m_machineRootScale ,sy=self.m_machineRootScale  }, 700)
    winLab:setString(util_getFromatMoneyStr(coins))
    local soundName = "PoseidonSounds/music_Poseidon_freespin_over_view.mp3"


    gLobalSoundManager:stopBgMusic()
    self.m_winSound = gLobalSoundManager:playSound(soundName,false)
        --   --缩放
        --   local soundName = "PoseidonSounds/music_Poseidon_last_win.mp3"
        --   gLobalSoundManager:setBackgroundMusicVolume(0.4)
        --   self.m_winSound = gLobalSoundManager:playSound(soundName,false, function(  )
        --       gLobalSoundManager:setBackgroundMusicVolume(1)
        --   end)

        --   performWithDelay(self, function(  )
        --         gLobalSoundManager:stopAudio(self.m_winSound)
        --         self.m_winSound = nil
        --         gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_last_win_end.mp3", false, function(  )
        --               gLobalSoundManager:setBackgroundMusicVolume(1)
        --         end)

        --   end, 2.3)

end

function CodeGameScreenPoseidonMachine:changeParentNode(node, parentNode)
    local zorder = node:getLocalZOrder()
    local posX = node:getPositionX()
    local posY = node:getPositionY()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = parentNode:convertToNodeSpace(worldPos)
    node:removeFromParent()
    parentNode:addChild(node,zorder )
    node:setPosition(nodePos)
end

function CodeGameScreenPoseidonMachine:resetLineNodeParent()

    for i=1, #self.m_respinLineNodes do
        local node = self.m_respinLineNodes[i]
        node:setVisible(true)
        self:changeParentNode(node, self.m_respinView)
    end

    for i = 1, #self.m_respinGroupPos, 1 do
        local groupPos = self.m_respinGroupPos[i]
        if #groupPos > 1 then
            for j = 2, #groupPos, 1 do
                local pos = groupPos[j]
                local node = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                node:setVisible(false)
            end
        end
    end
end

function CodeGameScreenPoseidonMachine:showRespinOverView()
    self:playFeatureOverAnima(GameEffect.EFFECT_RESPIN_OVER)
end


function CodeGameScreenPoseidonMachine:triggerRespinOver()
    if self.m_bProduceSlots_InFreeSpin then
        self.m_freeSpinBar:setVisible(true)
    else
        if 0 == self.m_iBetLevel then
            self:showLowerBetIcon()
        end
    end
    self.m_bottomUI:notifyUpdateWinLabel(self:getLastWinCoin(),false,false)
    self.m_bigPoseidon:runAnim("Poseidon_normal_poseidon", true)
    self:runCsbAction("idle3")
    --gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_linghtning_over_win.mp3")
    self:triggerReSpinOverCallFun(self.m_serverWinCoins)

end

function CodeGameScreenPoseidonMachine:rundNodeFrameAciton(node)
    node:runAnim("actionframe",false,function()
        self.m_slotEffectLayer:setScale(1)
        self:rundNodeFrameAciton(node)
        -- self.m_slotEffectLayer:runAction(cc.ScaleTo:create(2, 3))
    end)
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPoseidonMachine:MachineRule_SpinBtnCall()
    self.m_leftLamp:runIdleFram()
    self.m_rightLamp:runIdleFram()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId ~= nil then
        self.m_winSoundsId = nil
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
    end

    for j=1,self.m_iReelColumnNum do
        local childs = self:getReelParent(j):getChildren()
        for i=1,#childs do
            local node = childs[i]
            if  node.p_rowIndex == self.m_iReelRowNum + 1
            and node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                node:setVisible(true)
                break
            end
        end
    end


    self.m_isBreakLine = false


    self.isInBonus = false


    return false
end

function CodeGameScreenPoseidonMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenPoseidonMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end

function CodeGameScreenPoseidonMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenPoseidonMachine:showLowerBetIcon()
    self.m_lowBetIcon:show()
end

function CodeGameScreenPoseidonMachine:hideLowerBetIcon()
    self.m_lowBetIcon:hide()
end

function CodeGameScreenPoseidonMachine:slotReelDown( )
    BaseMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)

end


function CodeGameScreenPoseidonMachine:playEffectNotifyNextSpinCall( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)
    BaseMachine.playEffectNotifyNextSpinCall(self )

end

function CodeGameScreenPoseidonMachine:showLowerBetTip()
    local tip, act = util_csbCreate("Poseidon_tips.csb")
    local parent = self.m_bottomUI:findChild("bet_eft")
    tip:setPositionY(74)
    parent:addChild(tip)
    util_csbPlayForKey(act, "AUTO", false, function()
        tip:removeFromParent(true)
    end)

end

function CodeGameScreenPoseidonMachine:showLowerBetLayer(showTip)
    local view = util_createView("CodePoseidonSrc.PoseidonLowerBetDialog", self, showTip)
    view:findChild("lab_bet"):setString(util_formatCoins(self.m_BetChooseGear, 30))
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
end

function CodeGameScreenPoseidonMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end


        end, 4.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenPoseidonMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    self:updateBetLevel()
    if self.m_bProduceSlots_InFreeSpin ~= true and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false then
        performWithDelay(self, function()
            if self.m_iBetLevel == 0 then
                self:showLowerBetLayer(true)
            end
        end, 0.2)
    end

    if self.m_isBreakLine == true then
        self:hideLowerBetIcon()
    end
end

function CodeGameScreenPoseidonMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel > self.m_iBetLevel then
            self:showLowerBetIcon()
            -- self:showLowerBetTip()
        elseif perBetLevel < self.m_iBetLevel then
            self:hideLowerBetIcon()
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end

function CodeGameScreenPoseidonMachine:onExit()
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenPoseidonMachine:changeToMaskLayerSlotNode(slotNode)

    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_slotEffectLayer:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)

   self.m_slotEffectLayer:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then

        printInfo("xcyy : %s","slotNode p_rowIndex  p_cloumnIndex isnil")

    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

--    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenPoseidonMachine:operaBigSymbolShowMask(childNode)
    -- 这行是获取每列的显示行数， 为了适应多不规则轮盘
    local colIndex = childNode.p_cloumnIndex
    local columnData = self.m_reelColDatas[colIndex]
    local rowCount = self.m_iReelRowNum

    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
    local startRowIndex = childNode.p_rowIndex

    local chipH = 0
    if startRowIndex < 1 then  -- 起始格子在屏幕的下方
        chipH = (symbolCount + startRowIndex - 1) * columnData.p_showGridH
    elseif startRowIndex > 1 then  -- 起始格子在屏幕上方
        local diffCount = startRowIndex + symbolCount - 1 - rowCount
        if diffCount > 0 then
            chipH = (symbolCount - diffCount) * columnData.p_showGridH
        else
            chipH = symbolCount * columnData.p_showGridH
        end
    else -- 起始格子处于屏幕范围内
        chipH = symbolCount * columnData.p_showGridH
    end

    local clipY = 0
    if startRowIndex < 1 then
        clipY = math.abs((startRowIndex - 1) * columnData.p_showGridH )
    end

    clipY = clipY - columnData.p_showGridH  * 0.5




    local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + colIndex)
    local reelW = clipNode:getClippingRegion().width

    childNode:showBigSymbolClip(clipY, reelW, chipH)

end


function CodeGameScreenPoseidonMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    -- self:clearFrames_Fun()


    if self.m_lineSlotNodes == nil then
        return
    end

    print("#self.m_lineSlotNodes " .. #self.m_lineSlotNodes)
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            self:playNodeLineAnim(slotsNode)
        end
    end
    self:runEffectLayerAction(true)
end

function CodeGameScreenPoseidonMachine:runEffectLayerAction(showMask)

    local action = cc.Spawn:create(cc.Sequence:create(cc.ScaleTo:create(0.7, 1.06), cc.ScaleTo:create(0.8, 1)),
        cc.Sequence:create(cc.MoveBy:create(0.7, cc.p(0, 10)),  cc.MoveBy:create(0.8, cc.p(0, -10))))

    local pos =  self.m_slotEffectLayer:getPosition()
    self.m_lineScaleAction = cc.RepeatForever:create(action)

    if showMask then
        self.m_csbOwner["sp_black"]:setVisible(true)
    end

    self.m_slotEffectLayer:runAction( self.m_lineScaleAction  )
end

function CodeGameScreenPoseidonMachine:stopEffectLayerAction()

    -- 清空掉所有遮罩提示的 SlotNode
    if self.m_lineScaleAction ~= nil then
        self.m_csbOwner["sp_black"]:setVisible(false)
        self.m_slotEffectLayer:stopAction(self.m_lineScaleAction )
        self.m_slotEffectLayer:setScale(1)
        self.m_slotEffectLayer:setPosition(cc.p(self.m_effectLayerPos.x,  self.m_effectLayerPos.y ))
        self.m_lineScaleAction = nil
    end
end

function CodeGameScreenPoseidonMachine:clearFrames_Fun()

end

function CodeGameScreenPoseidonMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                lineNode:removeFromParent()
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                preParent:addChild(lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            end
        end
    end
    self:stopEffectLayerAction()
end

function CodeGameScreenPoseidonMachine:playNodeLineAnim(slotsNode)
    local animName = slotsNode:getLineAnimName()
    slotsNode:runAnim(animName,true)
end

------------------------------------------------设置快滚  长条scatter 不能算多个scatter
--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

--设置bonus scatter 信息
function CodeGameScreenPoseidonMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then

    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount
    local bAdd = false

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then

            local bPlaySymbolAnima = bPlayAni

            if bAdd == false then
                allSpecicalSymbolNum = allSpecicalSymbolNum + 1
                bAdd = true
            end

            if bRun == true then

                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效

                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end

    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end


-- 特殊信号下落时播放的音效
function CodeGameScreenPoseidonMachine:playScatterBonusSound(slotNode)

    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false
    then
        BaseMachine.playScatterBonusSound(self, slotNode)
    end
end


function CodeGameScreenPoseidonMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
                if  reelCol == 1  then
                    gLobalSoundManager:playSound(self.m_reelDownSound)
                end
            else
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
            if  reelCol == 1  then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        else
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
    end
 

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end

         --最后列滚完之后隐藏长滚
        if self.m_reelRunAnima ~= nil then

            if self:getGameSpinStage( ) == QUICK_RUN then
                for k,v in pairs(self.m_reelRunAnima) do
                    local runEffectBg = v
                    if runEffectBg ~= nil and runEffectBg[1]:isVisible() then
                        runEffectBg[1]:setVisible(false)
                    end
                end

            end
        end

    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function CodeGameScreenPoseidonMachine:MachineRule_reelDown(slotParent, parentData)
    local speedActionTable, timeDown = BaseSlotoManiaMachine.MachineRule_reelDown(self, slotParent, parentData)
    local haveRespin = self:getHasRespinFeature()
    if haveRespin then
        if parentData.cloumnIndex == 1 then
            local callFunc = cc.CallFunc:create(function ()
                self:playChangeBigPoseidonAnima()
            end)
            speedActionTable[#speedActionTable + 1] = callFunc
        end
    end
    local resFinishCallFunc = cc.CallFunc:create(
        function()
            local childs = slotParent:getChildren()
            for i=1,#childs do
                local node = childs[i]
                if node.m_isLastSymbol
                and node:getTag() == -1
                and node.p_rowIndex == self.m_iReelRowNum + 1
                and node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    node:setVisible(false)
                    break
                end
            end
        end)
    speedActionTable[#speedActionTable + 1] = resFinishCallFunc
    return speedActionTable, timeDown
end


function CodeGameScreenPoseidonMachine:getEffectLayer()
    return self.m_slotEffectLayer
end

function CodeGameScreenPoseidonMachine:changeNodeParentLayer(node, parentLayer)
    local zorder = node:getLocalZOrder()
    local tag = node:getTag()

    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
    local nodePos = parentLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    node:removeFromParent()
    parentLayer:addChild(node, zorder, tag)
    node:setPosition(nodePos)

end

function CodeGameScreenPoseidonMachine:getHasRespinFeature()
    local haveRespin = false
    for i=1, #self.m_runSpinResultData.p_features do
        local feature = self.m_runSpinResultData.p_features[i]
        if feature == 3 then
            haveRespin = true
        end
    end
    return haveRespin
end

function CodeGameScreenPoseidonMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then

        self:compareScatterWinLines(winLines)

        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >=5
            and  enumSymbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            and  enumSymbolType ~= TAG_SYMBOL_TYPE.SYMBOL_BONUS
            then
                isFiveOfKind=true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end
function CodeGameScreenPoseidonMachine:operaNetWorkData(  )
    BaseSlotoManiaMachine.operaNetWorkData(self)

    if  self:getHasRespinFeature() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Stop,false})
    end

end

function CodeGameScreenPoseidonMachine:produceSlots()
    --延长滚动长度
    if  self:getHasRespinFeature() then
        for i=2,#self.m_reelRunInfo do
            local runInfo = self.m_reelRunInfo[i]
            --得到初始长度
            local len = runInfo:getInitReelRunLen()
            runInfo:setReelRunLen(200)
         end
    end

    BaseSlots.produceSlots(self)
end


function CodeGameScreenPoseidonMachine:showEffect_Respin(effectData)

    -- 停掉背景音乐
    self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(),childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:removeFromParent()
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
            -- end
        end
    end

    if  self:getLastWinCoin() > 0 then  -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
            removeMaskAndLine()
    end
    self:showRespinView(effectData)

    return true

end

function CodeGameScreenPoseidonMachine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self,param)
    if self.m_runSpinResultData.p_reSpinsTotalCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount ~= nil then
        self:upDataJpLeftCount()
    end
end


function CodeGameScreenPoseidonMachine:randomSlotNodesByReel( )
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        local rowIndex = 1
        local bigSymbolLen = 0

        while rowIndex <= resultLen do

            local isBigSymbol = false
            local bigSymbolCount = 0
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            dump(reelData.p_reelResultSymbols,"111")
            local posY = 0

            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local isBigSymbol = true
                bigSymbolLen = self.m_bigSymbolInfos[symbolType]

                local adjacentNum = 0

                for i = resultLen - (rowIndex - 1), 1 , -1 do
                    local symbolTypeTmp = reelData.p_reelResultSymbols[i]

                    if symbolTypeTmp == symbolType then
                        adjacentNum = adjacentNum + 1
                    else
                        break
                    end
                end

                bigSymbolCount = adjacentNum % bigSymbolLen

                local diffCount = 0
                if bigSymbolCount ~= 0 then
                    diffCount = bigSymbolLen - bigSymbolCount
                end

                posY = (rowIndex - 1 - diffCount) * reelColData.p_showGridH + halfNodeH

            else
                posY = (rowIndex - 1) * reelColData.p_showGridH + halfNodeH
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            parentData.slotParent:addChild(node,
            node.p_showOrder- rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(posY )

            if isBigSymbol == true then
                if bigSymbolCount == 0 then
                    rowIndex = rowIndex + bigSymbolLen
                else
                    rowIndex = rowIndex + bigSymbolCount
                end
            else
                rowIndex = rowIndex + 1
            end
        end


        -- for rowIndex=1,resultLen do

        --     local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

        --     local node = self:getSlotNodeBySymbolType(symbolType)
        --     node.p_slotNodeH = reelColData.p_showGridH
        --     node.p_cloumnIndex = colIndex
        --     node.p_rowIndex = rowIndex
        --     node.p_symbolType = symbolType
        --     node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

        --     parentData.slotParent:addChild(node,
        --     node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)

        --     node.p_reelDownRunAnima = parentData.reelDownAnima

        --     node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        --     node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        --     node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )

        -- end
    end
end
-- ------------玩法处理 --

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenPoseidonMachine:MachineRule_network_InterveneSymbolMap()


end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenPoseidonMachine:MachineRule_afterNetWorkLineLogicCalculate()

end


---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPoseidonMachine:addSelfEffect()


                    --                       赢钱改变轮盘
                  --   local selfEffect = GameEffectData.new()
                  --   selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                  --   selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
                  --   self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                  --   selfEffect.p_selfEffectType = self.CHANGE_BONUS_REEL_FOR_WIN_EFFECT


end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPoseidonMachine:MachineRule_playSelfEffect(effectData)
	return false
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPoseidonMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenPoseidonMachine:isShowChooseBetOnEnter( )
    return self.m_bProduceSlots_InFreeSpin ~= true and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false and self.m_iBetLevel == 0
end

return CodeGameScreenPoseidonMachine






