--[[
    
    author: 徐袁
    time: 2021-07-02 10:29:15
]]
local Model = class("Model", BaseSingleton)

function Model:ctor()
    Model.super.ctor(self)
    -- 数据表
    self.m_modelMap = {}
    self:initializeModel()
end

--[[
    @desc: 初始化
    author: 徐袁
    time: 2021-07-02 10:32:47
    @return: 
]]
function Model:initializeModel()
end

--[[
    @desc: 注册数据模块
    author: 徐袁
    time: 2021-07-02 10:35:46
    --@_model: 
    @return: 
]]
function Model:registerModel(_model)
    if not _model then
        return
    end
    self.m_modelMap[_model:getModelName()] = _model
    _model:onRegister()
end

--[[
    @desc: 获得模块数据
    author: 徐袁
    time: 2021-07-02 10:40:26
    --@proxyName: 
    @return: 
]]
function Model:getModel(_modelName)
    return self.m_modelMap[_modelName]
end

--[[
    @desc: 移除模块
    author: 徐袁
    time: 2021-07-02 10:40:40
    --@proxyName: 
    @return: 
]]
function Model:removeModel(_modelName)
    local _model = self.m_modelMap[_modelName]
    if (_model ~= nil) then
        self.m_modelMap[_modelName] = nil
        _model:onRemove()
    end
    return _model
end

return Model
