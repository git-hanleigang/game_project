--
--大厅关卡容器节点 用来放JACKPOT 或者一列多个关卡情况
--
local LevelNewWindows = class("LevelNewWindows", util_require("base.BaseView"))



function LevelNewWindows:initUI(leveName)

    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self:createCsbNode("Lobby/"..leveName.."NewWin.csb", isAutoScale)
    self.m_levelName = leveName
    self:runCsbAction("show",false)
end

function LevelNewWindows:onKeyBack()
    self:runCsbAction("over",false,function ( )
        self:removeFromParent()
    end,60)
end

function LevelNewWindows:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()    
    if name == "player" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:postNotification(self.m_levelName.."Windows",true) 
        self:removeFromParent()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    elseif name == "close" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over",false,function ( )
            self:removeFromParent()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end,60)
    end
end
return LevelNewWindows
