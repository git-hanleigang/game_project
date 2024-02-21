
local KittysCatchLockNode = class("KittysCatchLockNode", cc.Node)

function KittysCatchLockNode:ctor(...)
    local args = {...}
    self.m_args = {}
    if #args > 0 then
        for k, v in ipairs(args) do
            table.insert(self.m_args, v)
        end
        self.m_machine = self.m_args[1]
        self.m_showType = self.m_args[2]    -- 1骨骼 2静态图
        self.m_symbolType = self.m_args[3]
    end

    self:createNode()
end

function KittysCatchLockNode:createNode()
    local csbName = "Socre_KittysCatch_Scatter2"
    if self.m_symbolType == 95 then
    elseif self.m_symbolType == 96 then
    elseif self.m_symbolType == 97 then
        csbName = "Socre_KittysCatch_Wild_2"
    end

    
    
    self.m_spine = util_spineCreate(csbName, true, true)
    self:addChild(self.m_spine, 1, 1)
    self.m_spine:setPosition(cc.p(0, 0))

    util_setCascadeOpacityEnabledRescursion(self.m_spine,true)

    self:runIdleAction()
    


    if self.m_symbolType == 95 then
        self:updateCornerNum(3)
    end

    -- local wildSpr = util_spineCreate("Socre_ChicElla_Wild", true, true)
    -- local wildSprStatic = util_createSprite("ChicEllaSymbol/Socre_ChicElla_Wild.png")
    -- self:addChild(wildSpr, 1, 1)
    -- self:addChild(wildSprStatic, 2, 2)
    -- wildSpr:setPosition(cc.p(0, 0))
    -- wildSprStatic:setPosition(cc.p(0, 0))
    -- wildSprStatic:setScale(0.5)
    -- self.m_spine = wildSpr
    -- self.m_static = wildSprStatic

    self:updateUI()
end

function KittysCatchLockNode:updateCornerNum(_num, _isPlayAnim)
    if self.m_symbolType == 95 then
        local rightDownNumNode = util_getChildByName(self, "rightDownNum")
        if not rightDownNumNode then
            rightDownNumNode = util_createAnimation("KittysCatch_scatterjiaobiao.csb")
            self:addChild(rightDownNumNode, 10)
            rightDownNumNode:setName("rightDownNum")
            rightDownNumNode:setPosition(cc.p(50, -50))
        end

        local setNum = function(_rightDownNumNode, _numInner)
            local label = util_getChildByName(_rightDownNumNode, "m_lb_num_1")
            if label then
                label:setString(_numInner)
                if _numInner == 1 then
                    label:setPositionX(-2)
                else
                    label:setPositionX(0)
                end
            end
        end
        
        if _isPlayAnim then
            rightDownNumNode:playAction("actionframe", false, function()
                rightDownNumNode:playAction("idle1", true)
            end)
            performWithDelay(self, function()
                setNum(rightDownNumNode, _num)
                
            end, 5/60)
        else
            setNum(rightDownNumNode, _num)
        end
        
    end
end

function KittysCatchLockNode:updateUI()
    self.m_spine:setVisible(self.m_showType == 1)
    -- self.m_static:setVisible(self.m_showType == 2)
end

function KittysCatchLockNode:playLockAction(_animName, _loop, func)

    util_spinePlay(self.m_spine, _animName, _loop)

    if not _loop then
        local spineEndCallFunc = function()
            if func then
                func()
            else
                self:runIdleAction()
            end
            
        end

        util_spineEndCallFunc(self.m_spine, _animName, spineEndCallFunc)
    end
    

end

function KittysCatchLockNode:playCornerOverAction()

    if self.m_symbolType == 95 then
        local rightDownNumNode = util_getChildByName(self, "rightDownNum")
        if not rightDownNumNode then
            rightDownNumNode = util_createAnimation("KittysCatch_scatterjiaobiao.csb")
            self:addChild(rightDownNumNode, 10)
            rightDownNumNode:setName("rightDownNum")
            rightDownNumNode:setPosition(cc.p(50, -50))
        end

        rightDownNumNode:playAction("over", false, function()
            rightDownNumNode:playAction("idle2", true)
        end)

    end
end

function KittysCatchLockNode:runIdleAction()
    if self.m_symbolType == 97 then
        util_spinePlay(self.m_spine, "idleframe2", true)
    elseif self.m_symbolType == 96 then
        util_spinePlay(self.m_spine, "idleframe2", true)
    else
        util_spinePlay(self.m_spine, "idleframe", true)
    end
end

-- function KittysCatchLockNode:setShowType(_type)
--     self.m_showType = _type
--     self:updateUI()
-- end 


return KittysCatchLockNode