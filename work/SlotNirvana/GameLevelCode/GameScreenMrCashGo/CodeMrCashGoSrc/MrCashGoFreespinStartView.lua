local MrCashGoFreespinStartView = class("MrCashGoFreespinStartView",util_require("Levels.BaseLevelDialog"))

function MrCashGoFreespinStartView:initDatas(_initData)
    self.m_initData = {}
end
function MrCashGoFreespinStartView:initUI()
    self.m_allowClick = false

    self:createCsbNode("MrCashGo/FreeSpinStart.csb")
end

--点击回调
function MrCashGoFreespinStartView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    self:clickCollectBtn(sender)
end

function MrCashGoFreespinStartView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_dialog_click.mp3")

    self:playOverAnim()
end


function MrCashGoFreespinStartView:initViewData(_ownerlist, _overFun, _isAuto)
    --数据
    self.m_initData.isAuto    = _isAuto
    self:updateOwnerVar(_ownerlist)
    self:setOverAniRunFunc(_overFun)

    --展示
    self:openDialog()
end

--开始弹框
function MrCashGoFreespinStartView:openDialog()
    self:setVisible(true)
    self:findChild("Button"):setEnabled(true)
    
    if self.m_initData.isAuto then
        --弹出自动弹版
        self:showAuto()
    else
        --正常弹出开始弹版
        self:showStart()
    end
end
-- 自动
function MrCashGoFreespinStartView:showAuto()
    self:runCsbAction("start", false, function()
        self.m_allowClick = true

        self:runCsbAction("idle", true)
        local animTime = 3
        performWithDelay(
            self,
            function()
                self:playOverAnim()
            end,
            animTime
        )
   end)
end
-- 手动
function MrCashGoFreespinStartView:showStart()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_allowClick = true
   end)
end

function MrCashGoFreespinStartView:playOverAnim()
    self:findChild("Button"):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    local animTime = util_csbGetAnimTimes(self.m_csbAct, "over")
    performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:setVisible(false)
        end,
        animTime
    )
end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function MrCashGoFreespinStartView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function MrCashGoFreespinStartView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

return MrCashGoFreespinStartView