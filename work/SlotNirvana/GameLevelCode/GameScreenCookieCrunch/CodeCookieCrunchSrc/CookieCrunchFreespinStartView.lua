local CookieCrunchFreespinStartView = class("CookieCrunchFreespinStartView",util_require("Levels.BaseLevelDialog"))

function CookieCrunchFreespinStartView:initDatas(_initData)
    self.m_initData = {}
end
function CookieCrunchFreespinStartView:initUI()
    self.m_allowClick = false

    self:createCsbNode("CookieCrunch/FreeSpinStart.csb")
    -- self:findChild("Button_collect"):setEnabled(false)
end

--点击回调
function CookieCrunchFreespinStartView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_click.mp3")
    self:clickCollectBtn(sender)
end

function CookieCrunchFreespinStartView:clickCollectBtn(_sender)
    self:playOverAnim()
end


function CookieCrunchFreespinStartView:initViewData(_ownerlist, _overFun, _isAuto)
    --数据
    self.m_initData.isAuto    = _isAuto
    self:updateOwnerVar(_ownerlist)
    self:setOverAniRunFunc(_overFun)

    --展示
    self:openDialog()
end

--开始弹框
function CookieCrunchFreespinStartView:openDialog()

    if self.m_initData.isAuto then
        --弹出自动弹版
        self:showAuto()
    else
        --正常弹出开始弹版
        self:showStart()
    end
end
-- 自动
function CookieCrunchFreespinStartView:showAuto()
    self:runCsbAction("start", false, function()
        -- self:findChild("Button_collect"):setEnabled(true)
        self.m_allowClick = true

        self:runCsbAction("idle", false)

        local idleTime = util_csbGetAnimTimes(self.m_csbAct, "idle")
        performWithDelay(
        self,
        function()
            self:playOverAnim()
        end,
        idleTime
    )
   end)
end
-- 手动
function CookieCrunchFreespinStartView:showStart()
    self:runCsbAction("start", false, function()
        -- self:findChild("Button_collect"):setEnabled(true)
        self.m_allowClick = true

        self:runCsbAction("idle", true)
   end)
end

function CookieCrunchFreespinStartView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_freeStart_actionframe.mp3")
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("over", false)
        local animTime = util_csbGetAnimTimes(self.m_csbAct, "over")

        performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:removeFromParent()
        end,
        animTime
    )
    end)
    
end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function CookieCrunchFreespinStartView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function CookieCrunchFreespinStartView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

return CookieCrunchFreespinStartView