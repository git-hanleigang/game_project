local LinkFishRespinStartBtn = class("LinkFishRespinStartBtn", util_require("base.BaseView"))
-- 构造函数
function LinkFishRespinStartBtn:initUI(data)
    local resourceFilename="Socre_LinkFish_Chip_freespin.csb"
    self:createCsbNode(resourceFilename)
    

    self:addClick(self:findChild("click_respin_star"))
    self.m_func = nil

end

function LinkFishRespinStartBtn:onEnter()

    -- --点击了特殊spin按钮 监听
    gLobalNoticManager:addObserver(self,function(Target,params)
        self:RespinStarCallFunc()
    end,ViewEventType.NOTIFY_LEVEL_CLICKED_SPECIAL_SPIN)
    
end

function LinkFishRespinStartBtn:initCallFunc( func )
    self.m_func = func
end
function LinkFishRespinStartBtn:setAction( isloop,func )
    self:runCsbAction("idle2",isloop,func)
end

function LinkFishRespinStartBtn:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LinkFishRespinStartBtn:RespinStarCallFunc( )
    --gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_spin_respin.mp3")
        if self.m_func  then
            self.m_func() 
        end
        self:setAction(false)
        self:setVisible(false)
        -- 隐藏特殊spin按钮
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN)
    
end

function LinkFishRespinStartBtn:clickFunc(sender)
    
    print("点击了开始respin")
    self:RespinStarCallFunc()
end

return LinkFishRespinStartBtn