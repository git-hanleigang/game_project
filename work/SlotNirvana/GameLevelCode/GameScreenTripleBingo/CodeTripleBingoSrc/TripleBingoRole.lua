--[[
    关卡角色
]]
local TripleBingoRole = class("TripleBingoRole", cc.Node)

function TripleBingoRole:initData_(_params)
    --[[
        _params = {
            spineName = "TripleBingo_juese2",
            atlasName = "Socre_TripleBingo_9",
            TripleBingo_juese
        }
    ]]
    self.m_data = _params
    self.m_curAnimName = ""
    self.m_curAnimLoop = false

    self:initUI()
end

function TripleBingoRole:initUI()
    local spineName = self.m_data.spineName
    local atlasName = self.m_data.atlasName or "Socre_TripleBingo_9"
    self.m_spine    = util_spineCreateDifferentPath(spineName, atlasName, true, true)
    -- util_spineCreate("Socre_TripleBingo_9", true, true)
    self:addChild(self.m_spine)
    -- util_spineMix(self.m_spine, "actionframe8","actionframe9",0.2)
    -- util_spineMix(self.m_spine, "idleframe1","actionframe6",0.2)

    --延时节点
    -- self.m_delayNode = cc.Node:create()
    -- self:addChild(self.m_delayNode)
end

function TripleBingoRole:runRoleAnim(_name, _bLoop, _fun)
    self.m_curAnimName = _name
    self.m_curAnimLoop = _bLoop

    util_spinePlay(self.m_spine, _name, _bLoop)
    if nil ~= _fun then
        util_spineEndCallFunc(self.m_spine, _name, _fun)
    end
end

--主界面idle
function TripleBingoRole:playBaseIdleAnim()
    local animName = "idleframe"
    self:runRoleAnim(animName, true)
end

--[[
    bet档位选择弹板
]]
function TripleBingoRole:playChooseViewIdleAnim()
    local animName = "idleframe_choose"
    self:runRoleAnim(animName, true)
end
function TripleBingoRole:playChooseViewSelectAnim()
    local animName = "actionframe_choose"
    self:runRoleAnim(animName, false)
end

--预告中奖
function TripleBingoRole:playYugaoAnim()
    local animName = "actionframe_yugao"
    self:runRoleAnim(animName, false, function()
        self:playBaseIdleAnim()
    end)
end

--free图标触发
function TripleBingoRole:playFreeTriggerAnim()
    local animName = "actionframe"
    self:runRoleAnim(animName, false, function()
        self:playBaseIdleAnim()
    end)
end

--bingo连线联动
function TripleBingoRole:playBingoLineAnim()
    local animName = "actionframe_bingo"
    self:runRoleAnim(animName, false, function()
        self:playBaseIdleAnim()
    end)
end


--大赢
function TripleBingoRole:playBigWinAnim()
    local animName = "actionframe_yugao"
    self:runRoleAnim(animName, false, function()
        self:playBaseIdleAnim()
    end)
end


return TripleBingoRole