---
--xcyy
--2018年5月23日
--HogHustlerMainMapItem.lua

local HogHustlerMainMapItem = class("HogHustlerMainMapItem",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

function HogHustlerMainMapItem:initUI(data, map)

    self.m_mapInfo = data.mapInfo
    self.m_index = data.index
    self.m_rolePos = data.rolePos
    self.m_planNum = data.hummerNum
    self.m_mainMap = map
    self.m_scale = 1
    self.m_maxGridNum = table.nums(self.m_mapInfo)
    local mapItemCsbName = string.format("HogHustler_dafuweng%d.csb", self.m_index)
    self:createCsbNode(mapItemCsbName)

    --道具父节点
    self.m_parentPropNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_parentPropNode)

    -- --角色父节点
    -- self.m_parentRoleNode = cc.Node:create()
    -- self:findChild("root"):addChild(self.m_parentRoleNode)
    self:runCsbAction("idle") -- 播放时间线
    self.m_GridItemNode_tab = {} --存储所有的格子
    self:initGridItem()
    self:initPropItem()
    self:initRole()
    self:initPig()
end

function HogHustlerMainMapItem:resetMapItemData(data, isClearProp)
    self.m_mapInfo = data.mapInfo
    self.m_index = data.index
    self.m_rolePos = data.rolePos
    self.m_planNum = data.hummerNum

    for i = 1, self.m_maxGridNum do
        if self.m_GridItemNode_tab[i] then
            self.m_GridItemNode_tab[i]:resetGridItem()
        end
    end

    -- if isClearProp then
    --     for i = 1, self.m_maxGridNum do
    --         local prop = self.m_parentPropNode:getChildByTag(i + 100)
    --         if prop then
    --             prop:removeFromParent()
    --         end
    --     end
    --     self:initPropItem()
    -- else
        for i = 1, self.m_maxGridNum do
            local prop = self.m_parentPropNode:getChildByTag(i + 100)
            if prop then
                prop:setVisible(true)
            end
        end
    -- end

    
    

    if self.m_roleItme then
        self.m_roleItme:setPosition(self:findChild("gezi_"..(self.m_rolePos - 1)):getPosition())
        self.m_GridItemNode_tab[self.m_rolePos]:initCurGridBg(true)
        local prop = self.m_parentPropNode:getChildByTag(self.m_rolePos + 100)
        if prop then
            prop:hideProp()
        end
    end

    if self.m_pig then
        self.m_pig:setPlan(self.m_planNum)
        self.m_pig:updateKeyNum()
    end
    
end


function HogHustlerMainMapItem:onEnter()
    HogHustlerMainMapItem.super.onEnter(self)
end

function HogHustlerMainMapItem:onExit()
    HogHustlerMainMapItem.super.onExit(self)
end

function HogHustlerMainMapItem:setDiceBttonWorldPos(pos)
    self.m_diceBttonWorldPos = pos
end

function HogHustlerMainMapItem:initGridItem(_func)
    --加速就不分帧了
    -- if cc.Director:getInstance():getScheduler():getTimeScale() ~= 1 then
        for i = 1, self.m_maxGridNum do
            local gridItme = util_createView("CodeHogHustlerSrc.Map.HogHustlerGridItem", {index = i})
            self.m_GridItemNode_tab[i] = gridItme
            self:findChild("gezi_"..(i - 1)):addChild(gridItme)
        end
        -- if _func then
        --     _func()
        -- end
    -- else
    --     self.addGridItemCoroutine =
    --         coroutine.create(
    --         function()
    --             for i = 1, self.m_maxGridNum do
    --                 local gridItme = util_createView("CodeHogHustlerSrc.Map.HogHustlerGridItem", {index = i})
    --                 self.m_GridItemNode_tab[i] = gridItme
    --                 self:findChild("gezi_"..(i - 1)):addChild(gridItme)
    --                 util_nextFrameFunc(
    --                     function()
    --                         util_resumeCoroutine(self.addGridItemCoroutine)
    --                     end
    --                 )
    --                 coroutine.yield()
    --             end
    --             self.addGridItemCoroutine = nil
    --             if _func then
    --                 _func()
    --             end
    --         end
    --     )

    --     util_resumeCoroutine(self.addGridItemCoroutine)
    -- end


    
end

function HogHustlerMainMapItem:initPropItem()
    -- if cc.Director:getInstance():getScheduler():getTimeScale() ~= 1 then
        for i = 1, self.m_maxGridNum do
            local propType = self.m_mapInfo[i]
            if propType > 100 then
                local node = self:findChild("gezi_"..(i - 1))
                local data = node:getComponent("ComExtensionData") or 0
                local tag = tonumber(data:getCustomProperty()) or 0
                local propItme = util_createView("CodeHogHustlerSrc.Map.HogHustlerPropItem", {index = i, propType = propType, zorder = 100 + tag}, self)
                self.m_parentPropNode:addChild(propItme)
                propItme:setTag(100 + i)
                propItme:setPosition(node:getPosition())
            end
        end
    -- else
    --     self.addPropItemCoroutine =
    --         coroutine.create(
    --         function()
    --             for i = 1, self.m_maxGridNum do
    --                 local propType = self.m_mapInfo[i]
    --                 if propType > 100 then
    --                     local node = self:findChild("gezi_"..(i - 1))
    --                     local data = node:getComponent("ComExtensionData") or 0
    --                     local tag = tonumber(data:getCustomProperty()) or 0
    --                     local propItme = util_createView("CodeHogHustlerSrc.Map.HogHustlerPropItem", {index = i, propType = propType, zorder = 100 + tag}, self)
    --                     self.m_parentPropNode:addChild(propItme)
    --                     propItme:setTag(100 + i)
    --                     propItme:setPosition(node:getPosition())
    --                     util_nextFrameFunc(
    --                         function()
    --                             util_resumeCoroutine(self.addPropItemCoroutine)
    --                         end
    --                     )
    --                     coroutine.yield()
    --                 end
    --             end
    --             self.addPropItemCoroutine = nil
    --         end
    --     )

    --     util_resumeCoroutine(self.addPropItemCoroutine)
    -- end

    
end

-- function HogHustlerMainMapItem:delItem(_cb)
--     self.delItemCoroutine =
--         coroutine.create(
--         function()
--             for i = 1, self.m_maxGridNum do
--                 local GridItemNode = self.m_GridItemNode_tab[i]
--                 if GridItemNode and not tolua.isnull(GridItemNode) then
--                     GridItemNode:removeFromParent()
--                 end
--                 util_nextFrameFunc(
--                     function()
--                         util_resumeCoroutine(self.delItemCoroutine)
--                     end
--                 )
--                 coroutine.yield()

--                 if self.m_parentPropNode then
--                     local propItem = self.m_parentPropNode:getChildByTag(100 + i)
--                     if propItem and not tolua.isnull(propItem) then
--                         propItem:removeFromParent()
--                     end
--                 end
--                 util_nextFrameFunc(
--                     function()
--                         util_resumeCoroutine(self.delItemCoroutine)
--                     end
--                 )
--                 coroutine.yield()
--             end
--             self.delItemCoroutine = nil
--             if _cb then
--                 _cb()
--             end
--         end
--     )

--     util_resumeCoroutine(self.delItemCoroutine)
-- end

function HogHustlerMainMapItem:initRole()
    local data = {mapIndex = self.m_index, posIndex = self.m_rolePos}
    self.m_roleItme = util_createView("CodeHogHustlerSrc.Map.HogHustlerMapRole", data)
    self.m_parentPropNode:addChild(self.m_roleItme)
    self.m_roleItme:setTag(500)
    self.m_roleItme:setPosition(self:findChild("gezi_"..(self.m_rolePos - 1)):getPosition())
    self.m_GridItemNode_tab[self.m_rolePos]:initCurGridBg(true)
    local prop = self.m_parentPropNode:getChildByTag(self.m_rolePos + 100)
    if prop then
        prop:hideProp()
    end
end

function HogHustlerMainMapItem:initPig()
    self.m_pig = util_createView("CodeHogHustlerSrc.Map.HogHustlerMapPig", {index = self.m_index, plan = self.m_planNum})
    self.m_parentPropNode:addChild(self.m_pig)
    self.m_pig:setLocalZOrder(150)
    local pos = util_convertToNodeSpace(self:findChild("baoxianxiang"), self.m_parentPropNode)
    self.m_pig:setPosition(pos)
end

function HogHustlerMainMapItem:roleMove(moveNum, coins, callBack)
    -- if curPos then --用服务器数据
    --     self.m_rolePos = curPos
    -- end
    
    local cur_pos = self.m_rolePos
    self.m_rolePos = self:getMapPos(self.m_rolePos + moveNum)
    -- print(string.format("移动： 位置%d  移动%d  终点%d", cur_pos,moveNum,self.m_rolePos))
    local move_posIndex_tab = {} --经过格子节点的索引表
    for i = 1, moveNum do
        local pos = cur_pos + i
        pos = self:getMapPos(pos)
        table.insert( move_posIndex_tab, pos)
    end

    local move_tiem = 0.3
    local move_startTime = 0.2
    local daley_tiem = 0.15
    local action_list = {}
    for index, v in ipairs(move_posIndex_tab) do
        local pos_index = v
        local temp_index = index
        action_list[#action_list + 1] = cc.CallFunc:create(function()
            self.m_GridItemNode_tab[pos_index]:changeGridBg(temp_index == moveNum)
        end)
        action_list[#action_list + 1] = cc.DelayTime:create(daley_tiem)
    end
    if moveNum > 1 then
        action_list[#action_list + 1] = cc.CallFunc:create(function()
            self.m_roleItme:playRun()
        end)
        action_list[#action_list + 1] = cc.DelayTime:create(move_startTime)
    end
    for index, v in ipairs(move_posIndex_tab) do
        local temp_index = index
        local pos_index = v
        local temp_move_tiem = temp_index == moveNum and 0.4 or move_tiem --移动时间
        local endPos = cc.p(self:findChild("gezi_"..(pos_index - 1)):getPosition())
        action_list[#action_list + 1] = cc.CallFunc:create(function()
            if temp_index == 1 then
                self:scaleToMap(self:getMapPos(cur_pos + moveNum), moveNum)
                local lastPos = self:getMapPos(cur_pos + index - 1)
                self.m_GridItemNode_tab[lastPos]:changeGridBg()
                local prop = self.m_parentPropNode:getChildByTag(lastPos + 100)
                if prop then
                    prop:showProp()
                end
            end
            if temp_index == moveNum  then 
                self.m_roleItme:playRunOver()
            end
            if temp_index == moveNum or temp_index == 1 then
                local temp_posIndex = temp_index == moveNum and pos_index or nil
                gLobalNoticManager:postNotification("PROP_CHANGE_Z_SMELLYRICH", temp_posIndex)
            end
            self.m_roleItme:setRoleType(self.m_index,pos_index)
        end)
        action_list[#action_list + 1] = cc.MoveTo:create(temp_move_tiem, endPos)
        action_list[#action_list + 1] = cc.CallFunc:create(function()
            --添加金币
            if temp_index == moveNum then
                self.m_GridItemNode_tab[pos_index]:initCurGridBg()
                if callBack and type(callBack) == "function" then
                    callBack()
                end 
                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_roleRun_1.mp3")
                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_roleRun_2.mp3")
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_role_footsteps_left)
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_role_footsteps_right)
            else
                local soundIndx = temp_index % 2
                soundIndx = soundIndx == 0 and 2 or 1
                -- local soundStr = string.format("HogHustlerSounds/sound_smellyRich_roleRun_%d.mp3", soundIndx)
                -- gLobalSoundManager:playSound(soundStr)
                if soundIndx == 1 then
                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_role_footsteps_left)
                else
                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_role_footsteps_right)
                end
                self.m_GridItemNode_tab[pos_index]:changeGridBg()
            end
            local coin = coins[temp_index] or 0
            if coin > 0 then
                self:showCoinsPropEffect(coin, pos_index)
            end
        end)
    end
    local seq = cc.Sequence:create(action_list)
    self.m_roleItme:runAction(seq)
end

function HogHustlerMainMapItem:getMapPos(pos)
    if pos > self.m_maxGridNum then
        pos  = pos - self.m_maxGridNum
    end
    return pos
end

function HogHustlerMainMapItem:showPropEffect(type, win, pos, isFirst)
    local prop = self.m_parentPropNode:getChildByTag(pos + 100)
    if prop then
        local pos = cc.p(prop:getPosition()) 
        pos = cc.pMul(pos, self.m_scale)
        local zorder = prop:getZOrder()
        prop:hideProp()
        local propItme = util_createView("CodeHogHustlerSrc.Map.HogHustlerPropItem", {index = pos, propType = type, zorder = zorder}, self)
        self.m_mainMap.m_effectPropNode:addChild(propItme, 2)
        propItme:setPosition(pos)
        propItme:showEffect(win, isFirst)
    end
end

function HogHustlerMainMapItem:getBoxKeyWorldPos()
    -- local pos = util_convertToNodeSpace(self.m_pig:getKeyWorldPos(),self.m_mainMap)

    local worldPos, keyNode = self.m_pig:getKeyWorldPos()
    return worldPos, keyNode
end

-- function HogHustlerMainMapItem:getDiceBttonPos()
--     local worldPos = self.m_diceBttonWorldPos
--     if not worldPos then
--         worldPos = cc.p(0, 0)
--     end
--     local pos = self.m_mainMap:convertToNodeSpace(worldPos)
--     return pos
-- end
-- function HogHustlerMainMapItem:getDiceButtonWorldPos()
--     local worldPos = self.m_diceBttonWorldPos
--     if not worldPos then
--         worldPos = cc.p(0, 0)
--     end
--     local pos = self.m_mainMap:convertToNodeSpace(worldPos)
--     return pos
-- end

function HogHustlerMainMapItem:getLevelStartPos()
    local pos = util_convertToNodeSpace(self.m_mainMap.m_level_node:findChild("Node_huizhang") ,self.m_mainMap)
    return pos
end

function HogHustlerMainMapItem:getLevelStartWorldPos()
    local targetNode = self.m_mainMap.m_level_node:findChild("Node_huizhang")
    if not targetNode then
        return cc.p(0, 0)
    end
    local worldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPosition()))
    return worldPos
end

function HogHustlerMainMapItem:showPigEffect(win)
    self.m_pig:showEffect(win)
end

function HogHustlerMainMapItem:showRoleStart()
    if self.m_roleItme then
        self.m_roleItme:showStartIdle()
    end
end

function HogHustlerMainMapItem:showPropMark(csbName)
    if csbName then
        self.m_mainMap:showPropMark(csbName)
    end
end

function HogHustlerMainMapItem:getAllWinLabelWorldPos()
    local pos = self.m_mainMap:getAllWinLabelWorldPos()
    return pos
end

function HogHustlerMainMapItem:showAddCoins()
    self.m_pig:showAddCoins()
    self.m_roleItme:roelGreed()
end

--显示道具效果
function HogHustlerMainMapItem:showCoinsPropEffect(coins, index)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_mapCoins_show.mp3")
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_stepcoin_fly2allwin_begin)
    local node = self:findChild("gezi_"..(index - 1))
    local pos = util_convertToNodeSpace(node, self.m_mainMap.m_effectPropNode)
    -- local curScale = self.m_mainMap:getMapBgNode():getScale()
    -- pos = cc.pMul(pos, self.m_scale)
    -- pos = cc.pMul(pos, curScale)
    
    local coinItem = util_createAnimation("HogHustler_jinbi.csb")
    local endPos = util_convertToNodeSpace(self.m_mainMap.m_allWin_node:findChild("glow"), self.m_mainMap.m_effectPropNode)
    endPos = cc.pSub(endPos, cc.p(0, 22))
    coinItem:findChild("m_lb_coins"):setString(util_formatCoins(coins, 3))
    self.m_mainMap.m_effectPropNode:addChild(coinItem)  --动效需求改动，这里提了层级
    coinItem:setPosition(pos)
    coinItem:playAction("actionframe", false)
    local action_list1 = {}
    action_list1[#action_list1 + 1] = cc.DelayTime:create(0.5)
    action_list1[#action_list1 + 1] = cc.CallFunc:create(function()
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_mapCoins_fly.mp3")
    end)
    action_list1[#action_list1 + 1] = cc.MoveTo:create(1/3, endPos)
    action_list1[#action_list1 + 1] = cc.CallFunc:create(function()
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_mapCoin_fankui.mp3")
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_stepcoin_fly2allwin_end)
        gLobalNoticManager:postNotification("MAP_ADD_COINS_SMELLYRICH", {coins})
    end)
    action_list1[#action_list1 + 1] = cc.DelayTime:create(2/15)
    action_list1[#action_list1 + 1] = cc.RemoveSelf:create()
    local sq1 = cc.Sequence:create(action_list1)
    coinItem:runAction(sq1)
end

function HogHustlerMainMapItem:scaleToMap(index, moveNum, isInit)
    local roleHeight = 160 * self.m_mainMap.m_machine.m_machineRootScale --角色高度
    local node = self:findChild("gezi_"..(index - 1))
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local topUiH = self.m_mainMap:getTopUIHeight()
    local scale_tiem = 0.3 * moveNum
    local surplusSpace = display.height - topUiH  --剩余空间
    local tempScale1 = 1 - (worldPos.y - surplusSpace) / display.cy
    local tempScale2 = 1 + roleHeight / display.cy
    local scale = tempScale1 / tempScale2
    if (scale > 0 and self.m_scale > scale) or (scale >= 1 and self.m_scale ~= 1 ) then
        scale = math.min(scale, 1)
        scale = math.max(scale, 0.85)
        self.m_scale = scale
        if isInit then
            self.m_mainMap:getMapBgNode():setScale(self.m_scale)
        else
            util_playScaleToAction(self.m_mainMap:getMapBgNode(), scale_tiem, self.m_scale)
        end    
    end
end

function HogHustlerMainMapItem:initMapScale()
    self:scaleToMap(self.m_rolePos, 0, true)
end

function HogHustlerMainMapItem:showMask()
    if self.m_mainMap then
        self.m_mainMap:showMask()
    end
end

function HogHustlerMainMapItem:hideMask()
    if self.m_mainMap then
        self.m_mainMap:hideMask()
    end
end

function HogHustlerMainMapItem:showGuide(_type, _win)
    if self.m_mainMap then
        self.m_mainMap:showGuide(function ()
            
        end, _type, _win)
    end
end

return HogHustlerMainMapItem