---
--island
--2017年8月28日
--LittleReelsGameMachineBG.lua

local LittleReelsGameMachineBG = class("LittleReelsGameMachineBG", util_require("views.gameviews.GameMachineBG"))

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"


function LittleReelsGameMachineBG:initUI( reelId )
    self.m_reelId = reelId
end

---
-- 初始化BG
-- @param csbpath string 模块名字
-- 
function LittleReelsGameMachineBG:initBgByModuleName(csbpath,isLoop)
    if not isLoop then
        isLoop= false
    end
    self.m_ccbClassName = ""
    local resourceFilename= csbpath
    self:createCsbNode(resourceFilename,true)
    self:runCsbAction("normal", isLoop)
end

function LittleReelsGameMachineBG:getUIScalePro()

    local ratio = display.width / display.height
    if ratio <= 1.34 then
        return 1
    end

    local x=display.width/DESIGN_SIZE.width
    local y=display.height/DESIGN_SIZE.height
    local pro=x/y

    if self.m_reelId == ChilliFiesta_Reels or self.m_reelId == Pomi_Reels  then
        pro = 1
    end
    


    return pro
end




return LittleReelsGameMachineBG