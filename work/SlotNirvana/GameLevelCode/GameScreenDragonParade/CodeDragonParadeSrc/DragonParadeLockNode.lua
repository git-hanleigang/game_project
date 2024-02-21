
local DragonParadeLockNode = class("DragonParadeLockNode", cc.Node)

function DragonParadeLockNode:ctor(...)
    local args = {...}
    self.m_args = {}

    self.m_spine = {}
    if #args > 0 then
        for k, v in ipairs(args) do
            table.insert(self.m_args, v)
        end
        self.m_machine = self.m_args[1]
        self.m_showType = self.m_args[2]    -- 1骨骼 2静态图
        self.m_symbolType = self.m_args[3]
    end
    self.m_delayNode = cc.Node:create() -- 延时node
    self:addChild(self.m_delayNode)
    self.m_num = 3
    -- self.m_playChange = false
    self:createNode()
end

function DragonParadeLockNode:createNode()
    -- local csbName = "Socre_DragonParade_wild1"
    -- if self.m_symbolType == 92 then
    --     csbName = "Socre_DragonParade_wild1"
    -- elseif self.m_symbolType == 101 then
    --     csbName = "Socre_DragonParade_wild2"
    -- elseif self.m_symbolType == 102 then
    --     csbName = "Socre_DragonParade_wild3"
    -- end

    local spineName = {"Socre_DragonParade_wild3", "Socre_DragonParade_wild2", "Socre_DragonParade_wild1"}
    --数组索引即次数
    for i=1,3 do
        self.m_spine[i] = util_spineCreate(spineName[i], true, true)
        self:addChild(self.m_spine[i], 1, 1)
        self.m_spine[i]:setPosition(cc.p(0, 0))

        util_setCascadeOpacityEnabledRescursion(self.m_spine[i],true)
    end
    
    -- self.m_spine = util_spineCreate(csbName, true, true)
    -- self:addChild(self.m_spine, 1, 1)
    -- self.m_spine:setPosition(cc.p(0, 0))

    

    self:runIdleAction()
    


    if self.m_symbolType == 92 then
        self:updateCornerNum(3)
    end

    -- self:updateUI()
end

function DragonParadeLockNode:setWhichSpineShow(num)
    for i=1,3 do
        if self.m_spine and self.m_spine[i] then
            self.m_spine[i]:setVisible(i == num)

            util_spinePlay(self.m_spine[i], "idle", true)
        end
    end
end

function DragonParadeLockNode:updateCornerNum(_num, _isPlayAnim)
    if self:isWildSymbol() then
        self.m_delayNode:stopAllActions()
        
        self.m_num = _num
        if _isPlayAnim then
            local time = 15
            if _num == 3 then
                self:playLockAction("switchreload", false, function (  )
                    self:runIdleAction()
                end, true)
            else
                time = 25
                self:playLockAction("switch", false, function (  )
                    self:runIdleAction()
                end, true)
            end
            -- self.m_playChange = true
            --延时五帧切数字
            performWithDelay(self.m_delayNode, function()
                self:setNum(_num)
            end, 5/30)

            --转换动画结束切不同spine
            performWithDelay(self.m_delayNode, function()
                self:setWhichSpineShow(_num) --切spine
                -- self.m_playChange = false
            end, time/30)
        else

            self:setNum(_num)

            self:setWhichSpineShow(_num)
        end
        
    end
end

function DragonParadeLockNode:setNum(_numInner)
    for i=1,3 do
        if self.m_spine[i] then
            util_spineRemoveSlotBindNode(self.m_spine[i], "guadian")
            self.m_spine[i].m_wildTimesNode = nil
            if not self.m_spine[i].m_wildTimesNode then
                local label = util_createAnimation("Socre_DragonParade_Wild_Num1.csb")
                    
                -- label:setScale(0.8)
                util_spinePushBindNode(self.m_spine[i], "guadian", label)
                self.m_spine[i].m_wildTimesNode = label

                util_setCascadeOpacityEnabledRescursion(self.m_spine[i], true)
                
            end

            if self.m_spine[i].m_wildTimesNode then
                self.m_spine[i].m_wildTimesNode:findChild("m_lb_coins"):setString(_numInner)
            end
            
        end
    end 
end

function DragonParadeLockNode:resetStatus()
    self:setNum(self.m_num)
    self:setWhichSpineShow(self.m_num)
    self:runIdleAction()

    self.m_delayNode:stopAllActions()

end

function DragonParadeLockNode:playLockAction(_animName, _loop, func, notReset)
    if notReset then
    else
        self:setNum(self.m_num)
        self:setWhichSpineShow(self.m_num)

        self.m_delayNode:stopAllActions()
    end
        

    for i=1,3 do
        if self.m_spine[i] and self.m_spine[i]:isVisible() then
            util_spinePlay(self.m_spine[i], _animName, _loop)

            if not _loop then
                local spineEndCallFunc = function()
                    if func then
                        func()
                    else
                        self:runIdleAction()
                    end
                    
                end

                util_spineEndCallFunc(self.m_spine[i], _animName, spineEndCallFunc)
            end

            break
        end
    end

end

function DragonParadeLockNode:playCornerOverAction()

    if self:isWildSymbol() then
        local rightDownNumNode = util_getChildByName(self, "rightDownNum")
        if not rightDownNumNode then
            rightDownNumNode = util_createAnimation("Socre_DragonParade_Wild_Num1.csb")
            self:addChild(rightDownNumNode, 10)
            rightDownNumNode:setName("rightDownNum")
            rightDownNumNode:setPosition(cc.p(0, 0))
        end

        -- rightDownNumNode:playAction("over", false, function()
        --     rightDownNumNode:playAction("idle2", true)
        -- end)

    end
end

function DragonParadeLockNode:runIdleAction()
    for i=1,3 do
        if self.m_spine and self.m_spine[i] and i == self.m_num then
            util_spinePlay(self.m_spine[i], "idle", true)
        end
    end
    
end

function DragonParadeLockNode:isWildSymbol()
    if self.m_symbolType == 92 or self.m_symbolType == 101 or self.m_symbolType == 102 then
        return true
    end
    return false
end
--数字 渐消
-- function DragonParadeLockNode:numFadeOut(  )
--     local rightDownNumNode = util_getChildByName(self, "rightDownNum")
--     if rightDownNumNode then
--         util_playFadeOutAction(rightDownNumNode, 15/30, function (  )
            
--         end)
--     end
-- end

return DragonParadeLockNode