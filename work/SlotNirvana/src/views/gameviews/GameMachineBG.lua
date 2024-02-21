---
--island
--2017年8月28日
--GameMachineBG.lua

local GameMachineBG = class("GameMachineBG", util_require("base.BaseView"))

GameMachineBG.m_ccbClassName = nil -- 
GameMachineBG.m_ccbNode = nil -- 
---
-- 初始化BG
-- @param moduleName string 模块名字
-- 
function GameMachineBG:initBgByModuleName(moduleName,isLoop)
    if not isLoop then
        isLoop= false
    end
    self.m_ccbClassName = string.format("GameScreen%sBg",moduleName)
    local resourceFilename=string.format("%s/GameScreen%sBg.csb",moduleName,moduleName)
    self:createCsbNode(resourceFilename,true)
    self:runCsbAction("normal", isLoop)   
end
function GameMachineBG:getUIScalePro()

    local ratio = display.width / display.height
    if ratio <= 1.34 then
        return 1
    end

    local x=display.width/DESIGN_SIZE.width
    local y=display.height/DESIGN_SIZE.height
    local pro=x/y
    return pro
end

function GameMachineBG:onEnter()
    -- body
    printInfo("xcyy : %s","GameMachineBG:onEnter")
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
function GameMachineBG:changeBGAnim(params)
    if type(params) == "string" then
        self:runCsbAction(params) 
    elseif type(params) == "table" then

        self:runCsbAction(params[1],params[2],params[3]) 
  
    end
     
end

function GameMachineBG:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return GameMachineBG