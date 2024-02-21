--[[
    -- 关卡角色
    self.m_roleAnim = util_createView("CalacasParadeSrc.CalacasParadeRole", {spineName="", atlasName=""}) 
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
]]
local CalacasParadeRole = class("CalacasParadeRole", cc.Node)

function CalacasParadeRole:initData_(_machine)
    self.m_machine = _machine

    self.m_curAnimName = ""
    self.m_curAnimLoop = false

    self:initUI()
end

function CalacasParadeRole:initUI()
    self.m_roleList = {}
    for _index=1,4 do
        local spineName = string.format("CalacasParade_huache%d", _index)
        local spine = util_spineCreate(spineName, true, true)
        self:addChild(spine)
        self.m_roleList[_index] = spine
    end
    -- 延时节点
    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
end

function CalacasParadeRole:onEnter()
    CalacasParadeRole.super.onEnter()
    for _index,_spine in ipairs(self.m_roleList) do
        local posNode = self.m_machine:findChild(string.format("hc_%d", _index))
        _spine:setPosition(util_convertToNodeSpace(posNode, self))
    end
end

function CalacasParadeRole:runRoleAnim(_spineIndex, _name, _bLoop, _fun)
    local roleSpine = self.m_roleList[_spineIndex]
    roleSpine:stopAllActions()
    util_spinePlay(roleSpine, _name, _bLoop)
    if nil ~= _fun then
        local animTime = roleSpine:getAnimationDurationTime(_name)
        performWithDelay(roleSpine, _fun, animTime)
    end
end
--淡入淡出
function CalacasParadeRole:playRoleFadeAct(_spineIndex, _bFadeIn, _fun)
    local roleSpine = self.m_roleList[_spineIndex]
    local actList  = {}
    local fadeTime = 0.5
    if _bFadeIn then
        roleSpine:setOpacity(0)
        table.insert(actList, cc.FadeIn:create(fadeTime))
    else
        table.insert(actList, cc.FadeOut:create(fadeTime))
    end
    if _fun then
        table.insert(actList, cc.CallFunc:create(_fun))
    end
    roleSpine:runAction(cc.Sequence:create(actList))
end
--进入退出
function CalacasParadeRole:playRoleStartOver(_spineIndex, _bStart, _fun)
    _fun = _fun or function()    end
    local animName = _bStart and "start" or "over"
    self:runRoleAnim(_spineIndex, animName, false, _fun)
end
--base界面循环idle
function CalacasParadeRole:playBaseLoopIdle(_showIndex)
    local index = 2
    for i,_spine in ipairs(self.m_roleList) do
        _spine:setVisible(i == index)
    end
    self:runRoleAnim(index, "idleframe", true)
end
-- function CalacasParadeRole:playBaseLoopIdle(_showIndex)
--     if nil ~= self.m_fnOnceIdleOver then
--         return
--     end

--     local index = _showIndex
--     while index == _showIndex do
--         index = math.random(1, #self.m_roleList)
--     end
--     self.m_curIndex = index

--     --下一次递归
--     self.m_fnOnceIdleOver = function()
--         self:playBaseLoopIdle(index)
--     end
--     local fnNext = function()
--         self:baseLoopIdleCall()
--     end

--     -- 没有正在idle
--     if not _showIndex then
--         for _spineIndex,roleSpine in ipairs(self.m_roleList) do
--             local bVis = _spineIndex == index
--             roleSpine:setVisible(bVis)
--             if bVis then
--                 self:runRoleAnim(index, "idleframe", true, fnNext)
--             end
--         end
--     else
--         for _spineIndex,roleSpine in ipairs(self.m_roleList) do
--             local bVis = _spineIndex == index or _spineIndex == _showIndex
--             roleSpine:setVisible(bVis)
--             --退出
--             if _spineIndex == _showIndex then
--                 self:runRoleAnim(_showIndex, "over", false, function()
--                     self.m_roleList[_showIndex]:setVisible(false)
--                 end)
--             --进入
--             elseif _spineIndex == index then
--                 self:runRoleAnim(index, "start", false, function()
--                     self:runRoleAnim(index, "idleframe", true, fnNext)
--                 end)
--             end
--         end
--     end
-- end
function CalacasParadeRole:baseLoopIdleCall()
    if self.m_fnOnceIdleOver then
        local fnTemp = self.m_fnOnceIdleOver
        self.m_fnOnceIdleOver = nil
        fnTemp()
    end
end
-- 停止下一轮idle
function CalacasParadeRole:stopNextBaseLoopIdle()
    self.m_fnOnceIdleOver = nil
end
-- 一轮idle结束后恢复循环idle
function CalacasParadeRole:restoreNextBaseLoopIdle()
    if self.m_fnOnceIdleOver then
        return
    end
    local roleSpine = self.m_roleList[self.m_curIndex]
    util_spineEndCallFunc(roleSpine,  "idleframe", function()
        self:playBaseLoopIdle(self.m_curIndex)
    end)
end


return CalacasParadeRole