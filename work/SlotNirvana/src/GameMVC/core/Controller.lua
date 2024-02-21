--[[
    
    author: 徐袁
    time: 2021-07-02 10:29:15
]]
local Controller = class("Controller", BaseSingleton)

function Controller:ctor()
    Controller.super.ctor(self)
    -- 数据表
    self.m_controllerMap = {}
    self:initializeController()
end

--[[
    @desc: 初始化
    author: 徐袁
    time: 2021-07-02 10:32:47
    @return: 
]]
function Controller:initializeController()
end

--[[
    @desc: 注册控制模块
    author: 徐袁
    time: 2021-07-02 10:35:46
    --@_ctrl: 
    @return: 
]]
function Controller:registerCtrl(_ctrl)
    if not _ctrl then
        return
    end
    local _ctrlName = _ctrl:getCtrlName()
    assert(_ctrlName, "" .. _ctrl.__cname .. " control name is nil !!!")
    self.m_controllerMap[_ctrlName] = _ctrl
    _ctrl:onRegister()
end

--[[
    @desc: 获得控制对象
    author: 徐袁
    time: 2021-07-02 10:40:26
    --@proxyName: 
    @return: 
]]
function Controller:getCtrl(_ctrlName)
    local ctrlObj = self.m_controllerMap[_ctrlName] 
    return ctrlObj
end

--[[
    @desc: 移除模块
    author: 徐袁
    time: 2021-07-02 10:40:40
    --@proxyName: 
    @return: 
]]
function Controller:removeCtrl(_ctrlName)
    local _ctrl = self.m_controllerMap[_ctrlName]
    if (_ctrl ~= nil) then
        self.m_controllerMap[_ctrlName] = nil
        _ctrl:onRemove()
    end
    return _ctrl
end

return Controller
