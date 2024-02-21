--[[
    外观类
    author: 徐袁
    time: 2021-07-02 10:52:19
]]
local Model = import(".Model")
local Controller = import(".Controller")

local Facade = class("Facade", BaseSingleton)

function Facade:ctor()
    Facade.super.ctor(self)
    self.model = nil

    self.controller = nil
    self:initializeFacade()
end

function Facade:initializeFacade()
    self:initializeModel()
    self:initializeController()
end

-- =============================================

function Facade:initializeController()
    if (self.controller ~= nil) then
        return
    end
    self.controller = Controller:getInstance()
end

function Facade:initializeModel()
    if (self.model ~= nil) then
        return
    end
    self.model = Model:getInstance()
end

-- ==============================================
-- 控制模块相关
function Facade:getCtrl(_ctrlName)
    return self.controller:getCtrl(_ctrlName)
end

function Facade:registerCtrl(ctrl)
    self.controller:registerCtrl(ctrl)
end

function Facade:removeCtrl(ctrl)
    self.controller:removeCtrl(ctrl)
end
-- =============================================
-- 数据模块相关
function Facade:getModel(_modelName)
    return self.model:getModel(_modelName)
end

function Facade:registerModel(_model)
    self.model:registerModel(_model)
end

function Facade:removeModel(_model)
    self.model:removeModel(_model)
end

return Facade
