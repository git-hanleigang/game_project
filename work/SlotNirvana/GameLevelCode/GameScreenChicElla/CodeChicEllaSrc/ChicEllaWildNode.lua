
local ChicEllaWildNode = class("ChicEllaWildNode", cc.Node)

function ChicEllaWildNode:ctor(...)
    local args = {...}
    self.m_args = {}
    if #args > 0 then
        for k, v in ipairs(args) do
            table.insert(self.m_args, v)
        end
        self.m_machine = self.m_args[1]
        self.m_showType = self.m_args[2]    -- 1骨骼 2静态图
    end

    self:createNode()
end

function ChicEllaWildNode:createNode()
    local wildSpr = util_spineCreate("Socre_ChicElla_Wild", true, true)
    local wildSprStatic = util_createSprite("ChicEllaSymbol/Socre_ChicElla_Wild.png")
    self:addChild(wildSpr, 1, 1)
    self:addChild(wildSprStatic, 2, 2)
    wildSpr:setPosition(cc.p(0, 0))
    wildSprStatic:setPosition(cc.p(0, 0))
    wildSprStatic:setScale(0.5)
    self.m_spine = wildSpr
    self.m_static = wildSprStatic

    self:updateUI()
end

function ChicEllaWildNode:updateUI()
    self.m_spine:setVisible(self.m_showType == 1)
    self.m_static:setVisible(self.m_showType == 2)
end

function ChicEllaWildNode:playAction(multi, isChange, isDown)
    
    local str = "idle"
    local endStr = "idle"
    local texturePath = "ChicEllaSymbol/Socre_ChicElla_Wild.png"
    if multi == 1 then
        str = "actionframe5"
        endStr = "idleframe"
        texturePath = "ChicEllaSymbol/Socre_ChicElla_Wild.png"
    elseif multi == 2 then
        if isDown then
            str = "actionframe1_2"
        else
            str = "actionframe5_x2"
        end
        
        endStr = "idleframe2"
        texturePath = "ChicEllaSymbol/Socre_ChicElla_Wildx2.png"
    elseif multi == 3 then
        if isDown then
            str = "actionframe1_3"
        else
            str = "actionframe5_x3"
        end
        endStr = "idleframe3"
        texturePath = "ChicEllaSymbol/Socre_ChicElla_Wildx3.png"
    end
    if isChange then
        util_spinePlay(self.m_spine, str, false)

        local spineEndCallFunc = function()
            util_spinePlay(self.m_spine, endStr, true)
        end
        util_spineEndCallFunc(self.m_spine, str, spineEndCallFunc)
    else
        util_spinePlay(self.m_spine, endStr, true)
    end
    

    
    util_changeTexture(self.m_static, texturePath)
end

function ChicEllaWildNode:setShowType(_type)
    self.m_showType = _type
    self:updateUI()
end 


return ChicEllaWildNode