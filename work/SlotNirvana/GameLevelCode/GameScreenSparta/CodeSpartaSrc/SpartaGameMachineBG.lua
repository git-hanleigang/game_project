---
--island
--2017年8月28日
--SpartaGameMachineBG.lua

local SpartaGameMachineBG = class("SpartaGameMachineBG", util_require("views.gameviews.GameMachineBG"))

SpartaGameMachineBG.m_ccbClassName = nil -- 
SpartaGameMachineBG.m_ccbNode = nil -- 
---
-- 初始化BG
-- @param moduleName string 模块名字
-- 
function SpartaGameMachineBG:initBgByModuleName(moduleName,isLoop)
    if not isLoop then
        isLoop= false
    end
    self.m_ccbClassName = string.format("GameScreen%sBg",moduleName)
    local resourceFilename=string.format("%s/GameScreen%sBg.csb",moduleName,moduleName)
    self:createCsbNode(resourceFilename,true)
    self:runCsbAction("normal", isLoop)   
end
function SpartaGameMachineBG:getUIScalePro()
    return 1
end

function SpartaGameMachineBG:onEnter()
    -- body
    printInfo("xcyy : %s","SpartaGameMachineBG:onEnter")
    gLobalNoticManager:addObserver(self,function(MainClass,params,isForver,func)
                                    self:changeBGAnim(params)
    end,ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG)

    gLobalNoticManager:addObserver(self,function(MainClass,params)
        MainClass:setVisible(false)
    end,ViewEventType.NOTIFY_ENTER_BONUS_GAME)

    gLobalNoticManager:addObserver(self,function(MainClass,params)
        MainClass:setVisible(true)
    end,ViewEventType.NOTIFY_EXIT_BONUS_GAME)
end
--
function SpartaGameMachineBG:changeBGAnim(params)
    if type(params) == "string" then
        self:runCsbAction(params) 
    elseif type(params) == "table" then

        self:runCsbAction(params[1],params[2],params[3]) 
  
    end
     
end

function SpartaGameMachineBG:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return SpartaGameMachineBG