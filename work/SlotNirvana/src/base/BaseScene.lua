--[[
    基础场景类
    author:{author}
    time:2023-02-24 17:05:12
]]
local BaseScene =
    class(
    "BaseScene",
    function(isPhysics)
        if isPhysics then
            -- 创建物理场景
            return cc.Scene:createWithPhysics()
        else
            -- 创建普通场景
            return cc.Scene:create()
        end
    end
)

function BaseScene:ctor()
    self:registerScriptHandler(
        function(event)
            if self == nil then
                return
            end
            if event == "enter" then
                self:onEnter()
            elseif event == "exit" then
                self:onExit()
            elseif event == "cleanup" then
                self:onCleanup()
            elseif event == "exitTransitionStart" then
                self:onExitStart()
            elseif event == "enterTransitionFinish" then
                self:onEnterFinish()
            end
        end
    )
end

function BaseScene:onEnter()
    release_print("BaseScene:onEnter " .. tostring(self.name_))
end

function BaseScene:onEnterFinish()
    release_print("BaseScene:onEnterFinish " .. tostring(self.name_))
    if globalData.userRunData then
        globalData.userRunData:sysServerTmSchedule()
    end
end

function BaseScene:onExitStart()
    release_print("BaseScene:onExitStart " .. tostring(self.name_))
    if globalData.userRunData then
        globalData.userRunData:stopServerTmSchedule()
    end

    if gLobalSoundManager then
        gLobalSoundManager:stopAllAuido()
        gLobalSoundManager:uncacheAll()
    end
end

function BaseScene:onExit()
    release_print("BaseScene:onExit " .. tostring(self.name_))
end

function BaseScene:onCleanup()
    release_print("BaseScene:onCleanup " .. tostring(self.name_))
end

return BaseScene
