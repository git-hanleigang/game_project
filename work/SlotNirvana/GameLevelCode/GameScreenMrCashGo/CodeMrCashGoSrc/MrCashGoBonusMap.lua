---
--xcyy
--2018年5月23日
--MrCashGoBonusMap.lua

local MrCashGoBonusMap = class("MrCashGoBonusMap",util_require("Levels.BaseLevelDialog"))

MrCashGoBonusMap.CELL_ORDER = {
    1,2,3,
    4,5,6,
    12,11,10,
    9,8,7,
}

function MrCashGoBonusMap:onExit()
    MrCashGoBonusMap.super.onExit(self)

    self:stopRoleRunSound()
end

function MrCashGoBonusMap:initDatas(_machine)
    self.m_machine  = _machine
end

function MrCashGoBonusMap:initUI()

    self:createCsbNode("MrCashGo_Map.csb")
    -- 中心裁剪区域 主要裁下方的左右两侧
    self.m_centerClip = cc.ClippingNode:create()
    local mask = util_createSprite("common/MrCashGo_youxi_wenzi_di_3.png")
    -- 3-60
    mask:setScale(4)
    mask:setPositionY(110)
    self.m_centerClip:setStencil(mask)
    self.m_centerClip:setAlphaThreshold(0)
    self:findChild("Spine_pushBtn"):addChild(self.m_centerClip)

    -- 中心按钮
    self.m_btnPush      = self:findChild("Button_push")
    self.m_btnPushSpine = util_spineCreate("MrCashGo_Anniu",true,true)
    self.m_centerClip:addChild(self.m_btnPushSpine)
    util_spinePlay(self.m_btnPushSpine, "idleframe")
    self.m_btnPush:setLocalZOrder(100)
    self.m_btnPush:setVisible(false)

    -- 骰子
    self.m_dice_1 = util_createAnimation("MrCashGo_Dice.csb") 
    self.m_dice_2 = util_createAnimation("MrCashGo_Dice.csb") 
    util_spinePushBindNode(self.m_btnPushSpine, "dianshu1", self.m_dice_1)
    util_spinePushBindNode(self.m_btnPushSpine, "dianshu2", self.m_dice_2)
    self.m_dice_1:setVisible(false)
    self.m_dice_2:setVisible(false)
    -- 骰子弹板
    self.m_diceViewSpine = util_spineCreateDifferentPath("MrCashGo_Tb", "MrCashGo_Anniu", true, true)
    self.m_diceViewCsb = util_createAnimation("MrCashGo_Tb.csb") 
    self:findChild("Node_DiceTb"):addChild(self.m_diceViewSpine, 10)
    self:findChild("Node_DiceTb"):addChild(self.m_diceViewCsb, 20)
    local dice_1 = util_createAnimation("MrCashGo_Dice.csb") 
    local dice_2 = util_createAnimation("MrCashGo_Dice.csb") 
    self.m_diceViewCsb:findChild("dianshu2"):addChild(dice_1)
    self.m_diceViewCsb:findChild("dianshu1"):addChild(dice_2)
    self.m_diceViewSpine:setVisible(false)
    self.m_diceViewCsb:setVisible(false)
    self.m_diceViewCsb.m_dice_1 = dice_1
    self.m_diceViewCsb.m_dice_2 = dice_2
    util_setCascadeOpacityEnabledRescursion(self.m_diceViewCsb, true)

    -- 人物
    self.m_role = util_spineCreateDifferentPath("Socre_MrCashGo_jiaose", "Socre_MrCashGo_Bonus", true, true)
    self:findChild("Node_Role"):addChild(self.m_role)
    self.m_role:setVisible(false)


    -- 三个玩法的 csb --{ [_mapPos] = Node }
    local featureParent = self:findChild("Node_feature")
    self.m_featureNodes = {}

    local feature2 = util_createAnimation("MrCashGo_MoneyBagFeature.csb") 
    featureParent:addChild(feature2)
    feature2:setPosition(util_convertToNodeSpace(self:findChild("MoneyBagFeature"), featureParent))

    self.m_featureNodes[4] = feature2

    local feature3 = util_createAnimation("MrCashGo_BigVillaFeature.csb")  
    featureParent:addChild(feature3)
    feature3:setPosition(util_convertToNodeSpace(self:findChild("BigVillaFeature"), featureParent))
    self.m_featureNodes[7] = feature3

    local feature4 = util_createAnimation("MrCashGo_CashRainFeature.csb") 
    featureParent:addChild(feature4)
    feature4:setPosition(util_convertToNodeSpace(self:findChild("CashRainFeature"), featureParent))
    self.m_featureNodes[10] = feature4

    self:playFeatureNodeIdleFrame()

    --玩法触发free时的底部光效
    self.m_featureLight = util_createAnimation("MrCashGo_Dice_gezi.csb") 
    self:findChild("Node_Light"):addChild(self.m_featureLight, 50)
    self.m_featureLight:setVisible(false)

    --触发jackpot底部光效
    self.m_jackpotLight = util_createAnimation("MrCashGo_Dice_gezi1.csb") 
    self:findChild("Node_Light"):addChild(self.m_jackpotLight, 50)
    self.m_jackpotLight:setVisible(false)

    --地板格子的光效
    self:initFloorLightAnim()

end

--创建csb节点
function MrCashGoBonusMap:createCsbNode(filePath, isAutoScale)
    self.m_baseFilePath = filePath
    local fullPath = cc.FileUtils:getInstance():fullPathForFilename(filePath)
    -- print("fullPath =".. fullPath)

    self.m_csbNode, self.m_csbAct = util_csbCreate(self.m_baseFilePath, self.m_isCsbPathLog)
    self:addChild(self.m_csbNode)
    self:bindingEvent(self.m_csbNode)
    self:pauseForIndex(0)
    self:setAutoScale(isAutoScale)

    self:initCsbNodes()

    -- 单独裁切一下 Node_Cell
    local Node_Cell = self:findChild("Node_Cell")
    local parent = Node_Cell:getParent()
    local pos = cc.p(Node_Cell:getPosition())
    --裁切层 代替原来的层级坐标
    self.m_nodeCellClip = cc.ClippingNode:create()
    local mask = util_createSprite("common/MrCashGo_mapMask.png")
    mask:setScale(2)
    self.m_nodeCellClip:setStencil(mask)
    mask:setPosition(0, 0)
    self.m_nodeCellClip:setAlphaThreshold(0)
    parent:addChild(self.m_nodeCellClip, -1)
    self.m_nodeCellClip:setPosition(pos)
    util_changeNodeParent(self.m_nodeCellClip, Node_Cell)
    Node_Cell:setPosition(0, 0)
end

function MrCashGoBonusMap:startRoleMove(_targetMapPos, _fun)
    if self.m_actionRoleMove then
        return
    end

    local pathData = self:getTargetMapPath(1, _targetMapPos)
    local actList  = {}
    local moveTime = 0.5
    local lastMoveData= pathData[#pathData]

    for i,_data in ipairs(pathData) do
        local mapPos  = _data.mapPos
        local actMove = cc.MoveTo:create(moveTime, _data.pos)
        local actFun  = cc.CallFunc:create(function()
            -- 到达位置如果是最后一次移动就不转向了
            if mapPos ~= lastMoveData.mapPos then
                if mapPos == 4 then
                    local roleAnimData = self:getRoleMoveAnimNameByPos(mapPos)
                    self:playRoleAnim(roleAnimData[1], true)
                    self.m_role:setScaleX(roleAnimData[3])
                elseif mapPos == 7 then
                    local roleAnimData = self:getRoleMoveAnimNameByPos(mapPos)
                    self:playRoleAnim(roleAnimData[1], true)
                    self.m_role:setScaleX(roleAnimData[3])
                elseif mapPos == 10 then
                    local roleAnimData = self:getRoleMoveAnimNameByPos(mapPos)
                    self:playRoleAnim(roleAnimData[1], true)
                    self.m_role:setScaleX(roleAnimData[3])
                end
            end
            self:playFloorAnim(mapPos)
            self:hideFloorLight(mapPos)
        end)

        table.insert(actList, actMove)
        table.insert(actList, actFun)
    end
    local isFeature = self:isFeatureNodePos(lastMoveData.mapPos)
    -- 人物到达格子开始欢呼
    local actRoleHuanhu = cc.CallFunc:create(function()
        self:stopRoleRunSound()

        local roleScaleX = lastMoveData.mapPos <= 7 and 1 or -1
        self.m_role:setScaleX(roleScaleX)
        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_roleHuanhu.mp3")

        local huanhuName = isFeature and "zou1_huanhu2" or "zou1_huanhu"
        self:playRoleAnim(huanhuName, false)
        --
        self:playFeatureNodeAnim(lastMoveData.mapPos)
        self:playJackpotNodeAnim(lastMoveData.mapPos)
        self:playRoleStopRunSound(lastMoveData.mapPos)
    end)
    local delayTime = isFeature and 60/30 or 36/30
    local actDelay = cc.DelayTime:create(delayTime)
    table.insert(actList, actRoleHuanhu)
    table.insert(actList, actDelay)
    -- 回到舞台中央坐飞机回去
    local actMoveEndFun = cc.CallFunc:create(function()
        self.m_actionRoleMove = nil
        
        if _fun then
            _fun()
        end
    end)
    table.insert(actList, actMoveEndFun)

    local roleAnimData = self:getRoleMoveAnimNameByPos(0)
    self:playRoleAnim(roleAnimData[1], true)
    self.m_role:setScaleX(-1)

    self:playFloorAnim(1)
    self:hideFloorLight(1)

    self:playRoleRunSound()

    self.m_actionRoleMove = cc.Sequence:create(actList)
    self.m_role:runAction(self.m_actionRoleMove)
end
-- 人物返回
function MrCashGoBonusMap:startRoleBack(_fun)
    if self.m_actionRoleMove then
        return
    end
    self.m_endFun   = _fun

    local startPos = cc.p(self.m_role:getPosition())
    local endPos   = cc.p(0, 0)
    local backAnimData = self:getRoleBackAnimNameByPosition(startPos.x - endPos.x)

    local actList  = {}
    -- 移动到舞台中央
    local actMove = cc.MoveTo:create(1, endPos)
    table.insert(actList, actMove)
     -- 飞走
    local actRoleFly = cc.CallFunc:create(function()
        self:stopRoleRunSound()

        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_roleBack.mp3")

        self.m_role:setScaleX(1)
        self:playRoleAnim("idle5", false, function()
            self.m_actionRoleMove = nil

            self.m_role:setVisible(false)
            if _fun then
                _fun()
            end
        end)
    end)
    table.insert(actList, actRoleFly)

    self:playRoleAnim(backAnimData[1], true)
    self.m_role:setScaleX(backAnimData[3])

    self:playRoleRunSound()

    self.m_actionRoleMove = cc.Sequence:create(actList)
    self.m_role:runAction(self.m_actionRoleMove)
end

--[[
    人物spine
]]
function MrCashGoBonusMap:playRoleAnim(_animName,_loop,_fun)
    util_spinePlay(self.m_role, _animName, _loop)
    if _fun then
        util_spineEndCallFunc(self.m_role, _animName, _fun)
    end

    self.m_role.m_curAnimName = _animName
end
-- 根绝所处格子获得对应的 走路时间线、静止时间线、x轴缩放
function MrCashGoBonusMap:getRoleMoveAnimNameByPos(_mapPos)
    local runName,stopName,scaleX = "zou1","zou1_stop",-1

    if _mapPos < 4 then
        runName,stopName,scaleX = "zou2","zou2_stop",-1    
    elseif _mapPos < 7 then
        runName,stopName,scaleX = "zou2","zou2_stop",1
    elseif _mapPos < 10 then
        runName,stopName,scaleX = "zou1","zou1_stop",1
    else
        runName,stopName,scaleX = "zou1","zou1_stop",-1
    end

    return {runName, stopName, scaleX}
end

function MrCashGoBonusMap:getRoleBackAnimNameByPosition(_offsetX)
    local runName,stopName,scaleX = "zou1","zou1_stop",-1

    if _offsetX <= 0 then
        runName,stopName,scaleX = "zou1","zou1_stop",1
    else
        runName,stopName,scaleX = "zou1","zou1_stop",-1
    end

    return {runName, stopName, scaleX}
end

function MrCashGoBonusMap:playRoleRunSound()
    if nil ~= self.m_upDateRoleRunSound then
        return
    end

    local node = self:findChild("Node_Role") 
    
    local soundTime = 0.35
    local times     = 1
    local soundIndex =  math.mod(times, 2) + 1
    local soundName = string.format("MrCashGoSounds/sound_MrCashGo_bonusGame_roleRun_%d.mp3", soundIndex)
    gLobalSoundManager:playSound(soundName)

    self.m_upDateRoleRunSound = schedule(node, function()
        times = times + 1
        soundIndex =  math.mod(times, 2) + 1
        soundName = string.format("MrCashGoSounds/sound_MrCashGo_bonusGame_roleRun_%d.mp3", soundIndex)
        gLobalSoundManager:playSound(soundName)
    end, soundTime)
end
function MrCashGoBonusMap:stopRoleRunSound()
    if nil ~= self.m_upDateRoleRunSound then
        self:findChild("Node_Role"):stopAction(self.m_upDateRoleRunSound)
        self.m_upDateRoleRunSound = nil
    end
end
--降落在start上
function MrCashGoBonusMap:playRoleDownAnim(_fun)
    local downPos = self:getCellPos(1)
    self.m_role:setPosition(downPos)
    self.m_role:setVisible(true)

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_roleDown.mp3")
    self:playRoleAnim("idle4_b", false, function()
        --应该等角色站到了地图上，再开始播放bonus音乐
        self.m_machine:resetMusicBg(nil,"MrCashGoSounds/music_MrCashGo_bonus.mp3")

        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_roleDown_idle.mp3")
        -- 向左:idle4_c 向右:stop1_idle
        self:playRoleAnim("idle4_c", true) 
        _fun()
    end)

    self.m_machine:levelPerformWithDelay(69/30, function()
        -- 人物落在START的位置，格子就应该沉一下
        self:playFloorAnim(1)
    end)
end

function MrCashGoBonusMap:playRoleStopRunSound(_mapPos)
    local soundList = {
        [4] = "MrCashGoSounds/sound_MrCashGo_bonusGame_moneyBag.mp3",
        [7] = "MrCashGoSounds/sound_MrCashGo_bonusGame_bigVilla.mp3",
        [10] = "MrCashGoSounds/sound_MrCashGo_bonusGame_cashRain.mp3",
    }
    local soundName = soundList[_mapPos] or "MrCashGoSounds/sound_MrCashGo_bonusGame_jackpot.mp3"
    gLobalSoundManager:playSound(soundName)
end
--[[
    push按钮
]]
function MrCashGoBonusMap:clickFunc(sender)
    local name = sender:getName()

    if name == "Button_push" then
        self:onPushBtnClick()
    end
end
function MrCashGoBonusMap:onPushBtnClick()
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_pushBtnClick.mp3")

    self.m_btnPush:setVisible(false)
    -- 弹出骰子
    self:showDicePoint()
end

-- 按钮摇骰子流程结束后的下一步
function MrCashGoBonusMap:setPushBtnCallBack(_fun)
    self.m_pushBtnCallBack = _fun
end
function MrCashGoBonusMap:playPushBtnStart(_diceData, _mapPos, _fun)
    self.m_dice_1:runCsbAction(string.format("dice_%d", _diceData[1]), false)
    self.m_dice_2:runCsbAction(string.format("dice_%d", _diceData[2]), false)
    self.m_diceViewCsb.m_dice_1:runCsbAction(string.format("dice_%d", _diceData[1]), false)
    self.m_diceViewCsb.m_dice_2:runCsbAction(string.format("dice_%d", _diceData[2]), false)
    local diceNum = _diceData[1] + _diceData[2]
    local labDiceNum = self.m_diceViewCsb:findChild("m_lb_num")
    labDiceNum:setString(string.format("%d", diceNum))
    self:updateLabelSize({label=labDiceNum,sx=1,sy=1}, 178)

    self.m_diceData      = _diceData
    self.m_roleTargetPos = _mapPos

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_pushBtnStart.mp3")
    util_spinePlay(self.m_btnPushSpine, "kaishi", false)
    util_spineEndCallFunc(self.m_btnPushSpine, "kaishi",handler(nil,function(  )
        util_spinePlay(self.m_btnPushSpine, "idleframe1", true)

        self:setPushBtnCallBack(_fun)
        self.m_btnPush:setVisible(true)
    end))
end
-- 骰子结果弹板消失，按钮和骰子下沉
function MrCashGoBonusMap:playPushBtnOver()
    --路径延伸
    self:showFloorLight(1, self.m_roleTargetPos, function()
        --骰子下沉
        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_hideDicePoint.mp3")
        util_spinePlay(self.m_btnPushSpine, "jieshu", false)
        util_spineEndCallFunc(self.m_btnPushSpine, "jieshu",handler(nil,function()
            self.m_dice_1:setVisible(false)
            self.m_dice_2:setVisible(false)
            self.m_machine:levelPerformWithDelay(0.5, function()

                if nil ~= self.m_pushBtnCallBack then
                    self.m_pushBtnCallBack()
                    self.m_pushBtnCallBack = nil
                end
            end)
        end))
    end)
end
--[[
    骰子
]]
function MrCashGoBonusMap:showDicePoint()
    self.m_machine:levelPerformWithDelay(1, function()
        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_showDicePoint.mp3")
    end)
    util_spinePlay(self.m_btnPushSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_btnPushSpine, "actionframe",handler(nil,function()
        self.m_machine:levelPerformWithDelay(0.5, function()
            self:showDiceResultView()
        end)
    end))
    -- 45帧展示骰子1
    self.m_machine:levelPerformWithDelay(42/30, function()
        self.m_dice_1:setVisible(true)
        -- 48帧展示骰子2
        self.m_machine:levelPerformWithDelay(3/30, function()
            self.m_dice_2:setVisible(true)
            local diceNum = self.m_diceData[1] + self.m_diceData[2]
            gLobalSoundManager:playSound(string.format("MrCashGoSounds/sound_MrCashGo_bonusGame_dice_%d.mp3", diceNum))
        end)
    end)
end
-- 结果弹板
function MrCashGoBonusMap:showDiceResultView()
    self.m_diceViewSpine:setVisible(true)
    self.m_diceViewCsb:setVisible(true)
    
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_showDiceResultView.mp3")
    self.m_diceViewCsb:runCsbAction("zhanshi", false, function()
        self.m_diceViewSpine:setVisible(false)
        self.m_diceViewCsb:setVisible(false)

        self.m_machine:levelPerformWithDelay(0.5, function()
            self:playPushBtnOver()
        end)
    end)
    util_spinePlay(self.m_diceViewSpine, "zhanshi", false)
end

--[[
    地板效果
]]
-- 踩踏效果
function MrCashGoBonusMap:playFloorAnim(_mapPos)
    local floorAnim = string.format("xia%d", _mapPos)
    self:runCsbAction(floorAnim)
end
-- 路径光效
function MrCashGoBonusMap:initFloorLightAnim()
    -- 1:粉 2:红 3:黄 4:蓝 5:绿
    -- local config = {
    --     0,1,4,
    --     3,5,4,
    --     3,5,4,
    --     3,5,2
    -- }
    
    local parent = self:findChild("Node_Light")
    self.m_floorLightList = {}
    for _mapPos=12,1,-1 do
        local lightAnim = util_createAnimation("MrCashGo_Map_faguang.csb")
        parent:addChild(lightAnim)
        lightAnim:setVisible(false)
        local pos = self:getCellPos(_mapPos)
        lightAnim:setPosition(pos)
        local order = self.CELL_ORDER[_mapPos]
        lightAnim:setLocalZOrder(order)
        self.m_floorLightList[_mapPos] = lightAnim
        
        -- 区分每个格子的光效颜色
        -- local colorType = config[_mapPos]
        -- local colorNode = lightAnim:findChild(string.format("sp_light_%d", colorType))
        -- if colorNode then
        --     colorNode:setVisible(true)
        -- end
    end
end
function MrCashGoBonusMap:showFloorLight(_startPos, _endPos, _fun)
    local direction = _endPos - _startPos > 0 and 1 or -1

    local actionTime = 12/60
    for _mapPos=_startPos,_endPos,direction do
        local lightAnim = self.m_floorLightList[_mapPos]
        lightAnim:findChild("sp_light_0"):setVisible(_mapPos ~= _endPos)
        lightAnim:findChild("sp_light_1"):setVisible(_mapPos == _endPos)


        local delayTime = actionTime * math.abs(_mapPos - _startPos)
        self.m_machine:levelPerformWithDelay(delayTime, function()
            lightAnim:setVisible(true)
            lightAnim:runCsbAction("start")
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_cell_light.mp3")
        end)
    end
    -- start: 0-10
    local time = math.abs(_endPos - _startPos) * actionTime
    self.m_machine:levelPerformWithDelay(time, function()
        _fun()
    end)
end
function MrCashGoBonusMap:hideFloorLight(_mapPos)
    local lightAnim = self.m_floorLightList[_mapPos]
    if nil ~= lightAnim then
        lightAnim:runCsbAction("over", false, function()
            lightAnim:setVisible(false)
        end)
    end
end
--[[
    三个玩法的特殊格子和光效
]]
-- 触发
function MrCashGoBonusMap:playFeatureNodeAnim(_mapPos)
    local featureNode = self.m_featureNodes[_mapPos]
    if self:isFeatureNodePos(_mapPos) then
        -- 音效名称和格子位置绑定了
        local soundName = string.format("MrCashGoSounds/sound_MrCashGo_bonusGame_feature_%d.mp3", _mapPos)
        gLobalSoundManager:playSound(soundName)

        featureNode:runCsbAction("fankui", false, function()
            featureNode:runCsbAction("idleframe", true)
        end)

        local pos = self:getCellPos(_mapPos)
        self.m_featureLight:setPosition(pos)
        self.m_featureLight:runCsbAction("idle", true)
        self.m_featureLight:setVisible(true)
    end
end
function MrCashGoBonusMap:hideFeatureLightAnim()
    util_setCsbVisible(self.m_featureLight, false)
end
function MrCashGoBonusMap:playFeatureNodeIdleFrame()
    for _mapPos,_featureNode in pairs(self.m_featureNodes) do
        _featureNode:runCsbAction("idleframe", true)
    end
end

function MrCashGoBonusMap:isFeatureNodePos(_mapPos)
    return nil ~= self.m_featureNodes[_mapPos]
end
--[[
    jackpot触发的格子光效
]]
function MrCashGoBonusMap:playJackpotNodeAnim(_mapPos)
    if not self:isFeatureNodePos(_mapPos) then
        local pos = self:getCellPos(_mapPos)
        self.m_jackpotLight:setPosition(pos)
        self.m_jackpotLight:runCsbAction("idle", true)
        self.m_jackpotLight:setVisible(true)
    end
end
function MrCashGoBonusMap:hideJackpotLightAnim()
    util_setCsbVisible(self.m_jackpotLight, false)
end
--[[
    工具
]]
function MrCashGoBonusMap:getTargetMapPath(_curMapPos, _targetMapPos)
    local pathData = {}

    local direction  = _targetMapPos - _curMapPos > 0 and 1 or -1
    local nextMapPos = _curMapPos + direction
    for _mapPos=nextMapPos,_targetMapPos,direction do
        local data = {
            mapPos = _mapPos,
            pos    = self:getCellPos(_mapPos)
        }
        table.insert(pathData, data)
    end
    
    return pathData
end


-- 光效和人物的挂点坐标一致都能用这个接口
function MrCashGoBonusMap:getCellPos(_mapPos)
    local cellNode   = self:findChild(string.format("%d", _mapPos))
    local roleParent = self.m_role:getParent()
    local cellPos    = util_convertToNodeSpace(cellNode, roleParent)

    return cellPos
end

return MrCashGoBonusMap