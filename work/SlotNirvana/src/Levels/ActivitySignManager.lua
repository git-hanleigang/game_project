--[[
    活动角标控制模块
]]
local GameEffectData = require "data.slotsdata.GameEffectData"
local ActivitySignManager = class("ActivitySignManager")

--位置类型
local POSITION_TYPE = {
    RIGHT_DOWN  =   1,  --右下角
    LEFT_DOWN   =   2,  --左下角
    RIGHT_UP    =   3,  --右上角
    LEFT_UP     =   4   --左上角
}

--活动配置
local ACTIVITY_DATA = {
    [1] = { --spin送道具
        actMgrName = G_REF.SpinGetItem,
        positionType = POSITION_TYPE.RIGHT_DOWN,
        signPosAry = {},
        signScale = 1,
        aniFunc = "checkCollectSign",
        signTag = 5001
    },
    [2] = { --气球限时活动
        actMgrName = ACTIVITY_REF.BalloonRush,
        positionType = POSITION_TYPE.LEFT_DOWN,
        signPosAry = {},
        signScale = 1,
        aniFunc = "checkCollectLimitActSign",
        signTag = 5002
    },
    [3] = { --Minz限时活动
        actMgrName = ACTIVITY_REF.Minz,
        positionType = POSITION_TYPE.RIGHT_UP,
        signPosAry = {},
        signScale = 1,
        aniFunc = "checkCollectMinzActSign",
        addSignFunc = "addMinzActSign",   --添加角标回调
        randSignFunc = "randMinzSignPos",  --随机角标位置回调
        effectFunc = "collectMinzSighEffect",        --事件回调
        signTag = 5003
    },
    [4] = { --DiyFeature限时活动
        actMgrName = ACTIVITY_REF.DiyFeature,
        positionType = POSITION_TYPE.RIGHT_UP,
        signPosAry = {},
        signScale = 1,
        aniFunc = "checkCollectDiyFeatureActSign",
        addSignFunc = "addDiyFeatureActSign",   --添加角标回调
        randSignFunc = "randDiyFeatureSignPos",  --随机角标位置回调
        effectFunc = "collectDiyFeatureSighEffect",        --事件回调
        signTag = 5004
    }
}

ActivitySignManager.m_activityData = ACTIVITY_DATA

-- ctor
function ActivitySignManager:ctor(params)
    self.m_machine = params.machine
    --是否允许添加角标
    self.m_isActSignClose = false

    --spin送道具表现结束回调
    self.m_spinItemCall = nil
end

--[[
    遍历活动配置
]]
function ActivitySignManager:forEachActData(func)
    for index = 1,#ACTIVITY_DATA do
        if ACTIVITY_DATA[index] then
            local isBreak = func(ACTIVITY_DATA[index],index)
            if isBreak then
                break
            end
        end
    end
    
end

--[[
    获取活动数据
]]
function ActivitySignManager:getActSignData(mgrName)
    for index = 1,#ACTIVITY_DATA do
        if ACTIVITY_DATA[index] and ACTIVITY_DATA[index].actMgrName == mgrName then
            return ACTIVITY_DATA[index]
        end
    end
end

-------------------------------基础接口不要动,如需修改请联系关卡负责人------------------------------------------------------

--[[
    随机角标位置
]]
function ActivitySignManager:randomAddSignPos()

    self:forEachActData(function(actData,index)

        --差异性接口判断
        if actData.randSignFunc then
            self[actData.randSignFunc](self,actData)
            return
        end

        local actMgr = G_GetMgr(actData.actMgrName)
        if not actMgr then
            return
        end

        local iconNum, dropNum = actMgr:getSlotData()
        --一列只能有一个出现角标的图标
        if not iconNum or iconNum == 0 or iconNum > self.m_machine.m_iReelColumnNum then
            return
        end

        actData.signPosAry = {}
        --检测轮盘内是否有长条图标,如果有则改变随机位置方式
        local isHaveLongSymbol = self.m_machine:checkHasLongSymbol()
        if isHaveLongSymbol then
            --获取所有可随机的位置
            local allPosAry = self.m_machine:getAllSignRandomPos()
            if #allPosAry == 0 then
                return
            end
            for iNum = 1, iconNum do
                local randIndex = math.random(1, #allPosAry)
                --转化索引值
                local posIndex = allPosAry[randIndex]
                actData.signPosAry[#actData.signPosAry + 1] = posIndex

                --移除已随机过的索引
                table.remove(allPosAry, randIndex)
            end
        else --一列随机一个位置
            local randomCols = {}
            for iCol = 1, self.m_machine.m_iReelColumnNum do
                randomCols[#randomCols + 1] = iCol
            end

            for iNum = 1, iconNum do
                local randIndex = math.random(1, #randomCols)
                --随机列坐标
                local colIndex = randomCols[randIndex]
                --移除已随机过的列坐标
                table.remove(randomCols, randIndex)

                --获取可视行数
                local reelColData = self.m_machine.m_reelColDatas[colIndex]
                local rowCount = reelColData.p_showGridCount or self.m_machine.m_iReelRowNum

                --随机行坐标
                local rowIndex = math.random(1, rowCount)

                --转化索引值
                local posIndex = self.m_machine:getPosReelIdx(rowIndex, colIndex)

                actData.signPosAry[#actData.signPosAry + 1] = posIndex
            end
        end

    end)
end


--[[
    添加活动角标
]]
function ActivitySignManager:addSignForActivity(symbolNode)
    if self.m_isActSignClose then
        return
    end

    self:forEachActData(function(actData,index)
        --差异性接口判断
        if actData.addSignFunc then
            self[actData.addSignFunc](self,symbolNode,actData)
            return
        end

        local signTag = actData.signTag
        local sign = symbolNode:getChildByTag(signTag)
        if not tolua.isnull(sign) then
            sign:removeFromParent()
        end

        local actMgr = G_GetMgr(actData.actMgrName)
        if not actMgr then
            return
        end

        local iconNum, dropNum = actMgr:getSlotData()
        if not iconNum or iconNum == 0 then
            return
        end

        if not actData.signPosAry or #actData.signPosAry == 0 then
            return
        end
        --检测该小块上是否有角标
        local function checkHasSign(posIndex)
            for index = 1, #actData.signPosAry do
                if actData.signPosAry[index] == posIndex then
                    return true
                end
            end
            return false
        end

        if symbolNode and symbolNode.m_isLastSymbol == true then
            local posIndex = self.m_machine:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            if checkHasSign(posIndex) then
                local scale = actData.signScale
                
                local signName = actMgr:getLevelLogoRes()
                if signName and type(signName) == "string" then
                    --创建角标精灵
                    local sign = util_createSprite(signName)
                    local size = sign:getContentSize()
                    sign:setScale(scale)
                    size.width = size.width * scale
                    size.height = size.height * scale
                    sign:setTag(actData.signTag)
                    symbolNode:addChild(sign, 100000)
                    local pos = self:getSignPosByType(actData.positionType,size)
                    --将角标放在图标的左下角
                    sign:setPosition(pos)
                end
            end
        end

    end)
end

--[[
    获取角标位置
]]
function ActivitySignManager:getSignPosByType(positionType,signSize)
    local symbolSize = CCSizeMake(self.m_machine.m_SlotNodeW, self.m_machine.m_SlotNodeH)
    if positionType == POSITION_TYPE.RIGHT_DOWN then -- 右下角
        return cc.p(symbolSize.width / 2 - signSize.width / 2, -symbolSize.height / 2 + signSize.height / 2)
    elseif positionType == POSITION_TYPE.LEFT_DOWN then -- 左下角
        return cc.p(-symbolSize.width / 2 + signSize.width / 2, -symbolSize.height / 2 + signSize.height / 2)
    elseif positionType == POSITION_TYPE.RIGHT_UP then -- 右上角
        return cc.p(symbolSize.width / 2 - signSize.width / 2, symbolSize.height / 2 - signSize.height / 2)
    else    --左上
        return cc.p(-symbolSize.width / 2 + signSize.width / 2, symbolSize.height / 2 - signSize.height / 2)
    end
end

--[[
    清除所有角标数据
]]
function ActivitySignManager:clearAllSignData()
    self:forEachActData(function(actData,index)
        actData.signPosAry = {}
        local actMgr = G_GetMgr(actData.actMgrName)
        if not actMgr then
            return
        end
        actMgr:clearSlotData()
    end)
end

--[[
    清除本次spin角标玩法数据
    退出关卡时手动调用一下
]]
function ActivitySignManager:clearSignDataByAct(mgrName)
    self:forEachActData(function(actData,index)
        if mgrName ~= actData.actMgrName then
            return
        end
        actData.signPosAry = {}
        local actMgr = G_GetMgr(actData.actMgrName)
        if not actMgr then
            return
        end
        actMgr:clearSlotData()
    end)
end

--[[
    添加收集角标事件
]]
function ActivitySignManager:addCollectSignEffect()
    if self.m_isActSignClose then
        return
    end

    local isNeedAddEffect = false
    self:forEachActData(function(actData,index)
        if actData.signPosAry and #actData.signPosAry > 0 then
            isNeedAddEffect = true
            return true
        end
    end)

    if isNeedAddEffect then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_COLLECT_SIGN
        effectData.p_effectOrder = GameEffect.EFFECT_COLLECT_SIGN
        self.m_machine.m_gameEffects[#self.m_machine.m_gameEffects + 1] = effectData
    end
end

--[[
    收集活动角标
]]
function ActivitySignManager:collectSignAni(func)

    self:collectNextActSign(1,function()
        if type(func) == "function" then
            func()
        end
    end)
    
end

--[[
    收集下个活动的角标
]]
function ActivitySignManager:collectNextActSign(index,func)
    if index > #ACTIVITY_DATA then
        if type(func) == "function" then
            func()
        end
        return 
    end

    local actData = ACTIVITY_DATA[index]

    --差异性接口判断
    if actData.effectFunc then
        self[actData.effectFunc](self,actData,index,func)
        return
    end

    local iconNum, point = G_GetMgr(actData.actMgrName):getSlotData()
    if not point or point <= 0 then
        --清理活动数据
        self:clearSignDataByAct(actData.actMgrName)
        self:collectNextActSign(index + 1,func)
        return
    end

    if type(self[actData.aniFunc]) == "function" then
        self[actData.aniFunc](self,function()
            --清理活动数据
            self:clearSignDataByAct(actData.actMgrName)
            self:collectNextActSign(index + 1,func)
        end)
    end
end

-------------------------------基础接口   end------------------------------------------------------------------------


-----------------------------------系统表现相关接口 各个活动的差异性接口写在这里--------------------------------------------------------------

-----------------------------------spin送道具-------------------------------------
--[[
    收集spin送道具活动角标
]]
function ActivitySignManager:checkCollectSign(func)
    local actMgr = G_GetMgr(G_REF.SpinGetItem)
    local actSignData = self:getActSignData(G_REF.SpinGetItem)
    local signPosAry = actSignData.signPosAry

    if not actMgr or not actMgr:getActivityData() or not signPosAry or #signPosAry == 0 then
        if type(func) == "function" then
            func()
        end
        return
    end

    local iconNum, dropNum = actMgr:getSlotData()
    if not dropNum or dropNum == 0 then
        if type(func) == "function" then
            func()
        end
        return
    end

    local tempList = {}
    local signs = {}
    local mask, maskAct, delayTime = actMgr:getLevelHeipingNode()
    mask:setScale(10)
    self.m_machine:addChild(mask, GAME_LAYER_ORDER.LAYER_ORDER_EFFECT)
    util_csbPlayForKey(
        maskAct,
        "start",
        false,
        function()
            if tolua.isnull(self.m_machine) or tolua.isnull(mask) then
                if type(func) == "function" then
                    func()
                end
                return
            end

            local scale = 1
            local getParentScale = function(node)
                if not node then
                    return
                end
                local parent = node:getParent()
                if parent then
                    local ps = parent:getScale()
                    scale = scale * ps
                    return parent
                end
            end

            for k, posIndex in pairs(signPosAry) do
                local symbolNode = self.m_machine:getSymbolByPosIndex(posIndex)
                if tolua.isnull(symbolNode) then
                    if type(func) == "function" then
                        func()
                    end
                    return
                end
                local sign = symbolNode:getChildByTag(actSignData.signTag)
                local logoNode, act = actMgr:getLevelLogoNode()
                if not logoNode or not act or not sign then
                    mask:removeFromParent()
                    if type(func) == "function" then
                        func()
                    end
                    return
                end

                signs[#signs + 1] = sign
                local startPos = util_convertToNodeSpace(sign, self.m_machine)
                scale = sign:getScale()
                logoNode:setPosition(startPos)
                logoNode:setScale(scale)
                local parent = getParentScale(sign)
                while parent do
                    parent = getParentScale(parent)
                end
                self.m_machine:addChild(logoNode, GAME_LAYER_ORDER.LAYER_ORDER_EFFECT)
                table.insert(tempList, logoNode)
                sign:setScale(1 / scale)
                sign:setVisible(false)
                util_csbPlayForKey(
                    act,
                    "start",
                    false,
                    function()
                    end,
                    60
                )
            end

            performWithDelay(
                mask,
                function()
                    util_csbPlayForKey(
                        maskAct,
                        "over",
                        false,
                        function()
                            if not tolua.isnull(mask) then
                                mask:removeFromParent()
                            end
                            for i, v in ipairs(tempList) do
                                if not tolua.isnull(v) then
                                    v:removeFromParent()
                                end
                            end
                            for k, sign in pairs(signs) do
                                sign:setVisible(true)
                            end
                            --清除本次spin活动数据
                            self:clearSignDataByAct(G_REF.SpinGetItem)
                            self.m_spinItemCall = func
                            -- func()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SPIN_ITEM, iconNum)
                        end,
                        60
                    )
                end,
                delayTime / 60
            )
        end,
        60
    )
end

--[[
    spin送道具活动回调
]]
function ActivitySignManager:spinItemCallBack()
    if type(self.m_spinItemCall) == "function" then
        self.m_spinItemCall()
        self.m_spinItemCall = nil
    end
end

-----------------------------------spin送道具  end--------------------------------------------------------------

-----------------------------------气球限时活动--------------------------------------------------------------
--[[
    检测收集限时活动角标
]]
function ActivitySignManager:checkCollectLimitActSign(func)
    local actSignData = self:getActSignData(ACTIVITY_REF.BalloonRush)
    local signPosAry = actSignData.signPosAry
    local iconNum, point = G_GetMgr(ACTIVITY_REF.BalloonRush):getSlotData()
    if not point or point <= 0 or not signPosAry or #signPosAry == 0 then
        if func then
            func()
        end
        return
    end

    local center_pos = self.m_machine:convertToNodeSpace(globalData.bingoCollectPos)
    local time_delay = 0.4

    local signs = {}
    for index , posIndex in ipairs(signPosAry) do
        local symbolNode = self.m_machine:getSymbolByPosIndex(posIndex)
        if not tolua.isnull(symbolNode) then
            local sign = symbolNode:getChildByTag(actSignData.signTag)
            if sign then
                signs[#signs + 1] = sign
            end
        end
    end
    
    for idx, sign in ipairs(signs) do
        sign:setVisible(false)
        local res_path = G_GetMgr(ACTIVITY_REF.BalloonRush):getLevelLogoRes()
        local new_sign = util_createSprite(res_path)
        if new_sign then
            local world_pos = sign:getParent():convertToWorldSpace(cc.p(sign:getPosition()))
            local node_pos = gLobalViewManager:getViewLayer():convertToNodeSpace(world_pos)
            new_sign:setPosition(node_pos)
            new_sign:addTo(gLobalViewManager:getViewLayer())
            new_sign:setZOrder(ViewZorder.ZORDER_UI)
            -- 移动到中心位置
            new_sign:runAction(cc.Sequence:create(cc.MoveTo:create(time_delay, center_pos), cc.DelayTime:create(0.1), cc.RemoveSelf:create()))
        end
    end

    local anim_path = G_GetMgr(ACTIVITY_REF.BalloonRush):getLogoAnim()
    if anim_path then
        self.m_machine:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(time_delay),
                cc.CallFunc:create(
                    function()
                        local anim = util_createAnimation(anim_path)
                        if anim then
                            local lb_lock_tip = anim:findChild("lb_lock_tip")
                            if lb_lock_tip then
                                local iconNum, dropNum = G_GetMgr(ACTIVITY_REF.BalloonRush):getSlotData()
                                lb_lock_tip:setString("x" .. dropNum)
                            end
                            local center_pos = self.m_machine:convertToNodeSpace(globalData.bingoCollectPos)
                            anim:setPosition(center_pos)
                            gLobalViewManager:showUI(anim, ViewZorder.ZORDER_UI, false)
                            anim:runCsbAction(
                                "start",
                                false,
                                function()
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BALLOON_RUSH_GET_REWARD)
                                    if func then
                                        func()
                                    end
                                    anim:runCsbAction(
                                        "idle",
                                        false,
                                        function()
                                            anim:runCsbAction(
                                                "over",
                                                false,
                                                function()
                                                    anim:removeSelf()
                                                end
                                            )
                                        end
                                    )
                                end
                            )                            
                        else
                            if func then
                                func()
                            end
                        end
                    end
                )
            )
        )
    end
end

-----------------------------------气球限时活动  end--------------------------------------------------------------

-----------------------------------minz--------------------------------------------------------------
--[[
    Minz获取角标位置
]]
function ActivitySignManager:randMinzSignPos(actData)
    local actMgr = G_GetMgr(actData.actMgrName)
    if not actMgr then
        return
    end

    local data = actMgr:getPointData()
    if not data then
        return
    end

    actData.signPosAry = {}

    for posIndex,num in pairs(data) do
        local posData = {
            posIndex = tonumber(posIndex),
            num = num
        }

        actData.signPosAry[#actData.signPosAry + 1] = posData
    end
    
end

--[[
    Minz添加角标
]]
function ActivitySignManager:addMinzActSign(symbolNode,actData)
    local signTag = actData.signTag
    local sign = symbolNode:getChildByTag(signTag)
    if not tolua.isnull(sign) then
        sign:removeFromParent()
    end

    local actMgr = G_GetMgr(actData.actMgrName)
    if not actMgr then
        return
    end

    if not actData.signPosAry or #actData.signPosAry == 0 then
        return
    end
    --检测该小块上是否有角标
    local function checkHasSign(posIndex)
        for index = 1, #actData.signPosAry do
            if actData.signPosAry[index].posIndex == posIndex then
                return actData.signPosAry[index]
            end
        end
        return nil
    end
    if symbolNode and symbolNode.m_isLastSymbol == true then
        local posIndex = self.m_machine:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local data = checkHasSign(posIndex)
        if data then
            local scale = actData.signScale
            local sign,act = actMgr:getLevelLogoRes()
            if sign then
                --创建角标精灵
                local size = G_GetMgr(actData.actMgrName):getLogoSize()
                local anim = sign:getChildByName("anim")
                local label = anim:getChildByName("lb_num")
                local p_num = data.num
                if p_num then
                    label:setString(p_num)
                end
                sign:setScale(scale)
                size.width = size.width * scale
                size.height = size.height * scale
                sign:setTag(actData.signTag)
                symbolNode:addChild(sign, 100000)
                util_csbPlayForKey(act,"ilde",true,nil)
                local pos = self:getSignPosByType(actData.positionType,size)
                --将角标放在图标的左下角
                sign:setPosition(pos)
            end
        end
    end
end

--[[
    收集Minz事件
]]
function ActivitySignManager:collectMinzSighEffect(actData,index,func)
    if not actData.signPosAry or #actData.signPosAry == 0 then
        --清理活动数据
        self:clearSignDataByAct(actData.actMgrName)
        self:collectNextActSign(index + 1,func)
        return
    end

    if type(self[actData.aniFunc]) == "function" then
        self[actData.aniFunc](self,function()
            --清理活动数据
            self:clearSignDataByAct(actData.actMgrName)
            self:collectNextActSign(index + 1,func)
        end)
    end
end

--[[
    检测收集minz
]]
function ActivitySignManager:checkCollectMinzActSign(func)
    local actMgr = G_GetMgr(ACTIVITY_REF.Minz)
    local actSignData = self:getActSignData(ACTIVITY_REF.Minz)
    if not actSignData.signPosAry or #actSignData.signPosAry == 0 then
        if func then
            func()
        end
        return
    end

    local signPosAry = actSignData.signPosAry
    local signs = {}
    for index , data in ipairs(signPosAry) do
        local symbolNode = self.m_machine:getSymbolByPosIndex(data.posIndex)
        if not tolua.isnull(symbolNode) then
            local sign = symbolNode:getChildByTag(actSignData.signTag)
            if sign then
                signs[#signs + 1] = sign
            end
        end
    end

    if signs and table.nums(signs) > 0 then
        local _node = gLobalActivityManager:getEntryNode(ACTIVITY_REF.Minz)
        local end_pos = cc.p(0,0)
        local _isVisible = gLobalActivityManager:getEntryNodeVisible(ACTIVITY_REF.Minz)
        if not _isVisible then
            end_pos = gLobalActivityManager:getEntryArrowWorldPos()
        elseif _node then
            end_pos = _node:getParent():convertToWorldSpace(cc.p(_node:getPosition()))
        end
        local center_pos = self.m_machine:convertToNodeSpace(globalData.bingoCollectPos)
        local time_delay = 0.5
        local signCount = #signs
        local arriveIdx = 0
        for idx, sign in ipairs(signs) do
            sign:setVisible(false)
            local new_sign,act= actMgr:getLevelLogoRes()
            if new_sign then
                local anim = sign:getChildByName("anim")
                local anim_new = new_sign:getChildByName("anim")
                local sorce = 0
                if anim and anim_new then
                    local label = anim:getChildByName("lb_num")
                    sorce = label:getString()
                    local label_new = anim_new:getChildByName("lb_num")
                    label_new:setString(sorce)
                end
                local world_pos = sign:getParent():convertToWorldSpace(cc.p(sign:getPosition()))
                local node_pos = gLobalViewManager:getViewLayer():convertToNodeSpace(world_pos)
                new_sign:setPosition(node_pos)
                new_sign:addTo(gLobalViewManager:getViewLayer())
                new_sign:setZOrder(ViewZorder.ZORDER_UI)
                local tbAct = {}
                tbAct[#tbAct+1] = cc.DelayTime:create(0.2)
                tbAct[#tbAct+1] = cc.Spawn:create(cc.MoveTo:create(time_delay, end_pos),cc.ScaleTo:create(time_delay, 0.4))
                tbAct[#tbAct+1] = cc.RemoveSelf:create()
                tbAct[#tbAct+1] = cc.CallFunc:create(function()
                    arriveIdx = arriveIdx + 1
                    if arriveIdx == signCount then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_MINZ_GETSPIN_REWARD)
                    end
                end)
                
                -- 移动到中心位置
                new_sign:runAction(cc.Sequence:create(tbAct))
            end
        end
    end
    if func then
        func()
    end
end

-----------------------------------minz  end--------------------------------------------------------------

--[[
    DiyFeature获取角标位置
]]
function ActivitySignManager:randDiyFeatureSignPos(actData)
    local actMgr = G_GetMgr(actData.actMgrName)
    if not actMgr then
        return
    end

    local data = actMgr:getPointData()
    if not data then
        return
    end

    actData.signPosAry = {}

    for posIndex,num in pairs(data) do
        local posData = {
            posIndex = tonumber(posIndex),
            num = num
        }

        actData.signPosAry[#actData.signPosAry + 1] = posData
    end
    
end
--[[
    DiyFeature添加角标
]]
function ActivitySignManager:addDiyFeatureActSign(symbolNode,actData)
    local signTag = actData.signTag
    local sign = symbolNode:getChildByTag(signTag)
    if not tolua.isnull(sign) then
        sign:removeFromParent()
    end

    local actMgr = G_GetMgr(actData.actMgrName)
    if not actMgr then
        return
    end
    local isUseCriticalMult = false
    local activityData = actMgr:getRunningData()
    if activityData then
        -- if activityData.p_criticalMult and activityData.p_criticalMult > 1 then
        --     -- 暴击不播放 start2
        --     isUseCriticalMult = true
        -- end
        
        if activityData.p_buffDropMult and activityData.p_buffDropMult > 1 then
            -- 双倍
            isUseCriticalMult = true
        end
    end
    if not actData.signPosAry or #actData.signPosAry == 0 then
        return
    end
    --检测该小块上是否有角标
    local function checkHasSign(posIndex)
        for index = 1, #actData.signPosAry do
            if actData.signPosAry[index].posIndex == posIndex then
                return actData.signPosAry[index]
            end
        end
        return nil
    end
    if symbolNode and symbolNode.m_isLastSymbol == true then
        local posIndex = self.m_machine:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local data = checkHasSign(posIndex)
        if data then
            local scale = actData.signScale
            local sign,act = actMgr:getLevelLogoRes()
            if sign then
                --创建角标精灵
                local size = G_GetMgr(actData.actMgrName):getLogoSize()
                local anim = sign:getChildByName("anim")
                local label = anim:getChildByName("lb_num")
                local p_num = data.num
                if p_num then
                    label:setString(p_num)
                end
                sign.isUseCriticalMult = isUseCriticalMult
                sign:setScale(scale)
                size.width = size.width * scale
                size.height = size.height * scale
                sign:setTag(actData.signTag)
                symbolNode:addChild(sign, 100000)
                util_csbPlayForKey(act,"idle",true,nil)
                local pos = self:getSignPosByType(actData.positionType,size)
                --将角标放在图标的左下角
                sign:setPosition(pos)
            end
        end
    end
end

--[[
    收集DiyFeature事件
]]
function ActivitySignManager:collectDiyFeatureSighEffect(actData,index,func)
    if not actData.signPosAry or #actData.signPosAry == 0 then
        --清理活动数据
        self:clearSignDataByAct(actData.actMgrName)
        self:collectNextActSign(index + 1,func)
        return
    end

    if type(self[actData.aniFunc]) == "function" then
        self[actData.aniFunc](self,function()
            --清理活动数据
            self:clearSignDataByAct(actData.actMgrName)
            self:collectNextActSign(index + 1,func)
        end)
    end
end

--[[
    检测收集minz
]]
function ActivitySignManager:checkCollectDiyFeatureActSign(func)
    local actMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    local _data = actMgr:getRunningData()
    if not _data then
        -- 活动结束了
        return
    end
    local actData = clone(_data)
    _data:clearGainState()
    local actSignData = self:getActSignData(ACTIVITY_REF.DiyFeature)
    if not actSignData.signPosAry or #actSignData.signPosAry == 0 then
        if func then
            func()
        end
        return
    end

    local signPosAry = actSignData.signPosAry
    local signs = {}
    for index , data in ipairs(signPosAry) do
        local symbolNode = self.m_machine:getSymbolByPosIndex(data.posIndex)
        if not tolua.isnull(symbolNode) then
            local sign = symbolNode:getChildByTag(actSignData.signTag)
            if sign then
                signs[#signs + 1] = sign
            end
        end
    end

    if signs and table.nums(signs) > 0 then
        local _node = gLobalActivityManager:getEntryNode(ACTIVITY_REF.DiyFeature)
        local end_pos = cc.p(0,0)
        local _isVisible = gLobalActivityManager:getEntryNodeVisible(ACTIVITY_REF.DiyFeature)
        if not _isVisible then
            end_pos = gLobalActivityManager:getEntryArrowWorldPos()
        elseif _node then
            end_pos = _node:getParent():convertToWorldSpace(cc.p(_node:getPosition()))
        end
        local center_pos = self.m_machine:convertToNodeSpace(globalData.bingoCollectPos)
        local time_delay = 0.5
        local signCount = #signs
        local arriveIdx = 0
        for idx, sign in ipairs(signs) do
            sign:setVisible(false)
            local new_sign, act= actMgr:getLevelLogoRes()
            if new_sign then
                local anim = sign:getChildByName("anim")
                local label = anim:getChildByName("lb_num")
                local sorce = label:getString()
                local anim_new = new_sign:getChildByName("anim")
                local world_pos = sign:getParent():convertToWorldSpace(cc.p(sign:getPosition()))
                local node_pos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(world_pos)
                new_sign:setPosition(node_pos)
                new_sign:addTo(gLobalViewManager.p_ViewLayer)
                if sign.isUseCriticalMult then 
                    local label_new = anim_new:getChildByName("lb_num2")
                    label_new:setString(sorce)
                    util_csbPlayForKey(act, "start2", false, function()
                        util_csbPlayForKey(act, "idle2", true, nil, 60)
                    end, 60)
                else
                    local label_new = anim_new:getChildByName("lb_num")
                    label_new:setString(sorce)
                    util_csbPlayForKey(act, "start", false, function()
                        util_csbPlayForKey(act, "idle", true, nil, 60)
                    end, 60)
                end
                new_sign:setZOrder(ViewZorder.ZORDER_UI)
                local tbAct = {}
                tbAct[#tbAct+1] =  cc.DelayTime:create(0.6)
                tbAct[#tbAct+1] =  cc.Spawn:create(cc.MoveTo:create(time_delay, end_pos),cc.ScaleTo:create(time_delay, 0.4))
                tbAct[#tbAct+1] = cc.RemoveSelf:create()
                tbAct[#tbAct+1] =  cc.CallFunc:create(function()
                    arriveIdx = arriveIdx + 1
                    if tonumber(arriveIdx) == signCount then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DIYFEATURE_FLYPOINT_OVER, {actData = actData, isMul=sign.isUseCriticalMult})
                    end
                end)
                
                -- 移动到中心位置
                new_sign:runAction(cc.Sequence:create(tbAct))
            end
        end
    end
    if func then
        func()
    end
end

-----------------------------------DiyFeature  end--------------------------------------------------------------

-----------------------------------系统表现相关接口  end--------------------------------------------------------------

return ActivitySignManager
