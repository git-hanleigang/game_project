---
--xcyy
--2018年5月23日
--StarryXmasCollectBarView.lua

local StarryXmasCollectBarView = class("StarryXmasCollectBarView",util_require("base.BaseView"))

local PROGRESS_WIDTH = 515

function StarryXmasCollectBarView:initUI()

    self:createCsbNode("StarryXmas_shoujilan.csb")
    
    -- 进度条上的雪橇车
    self.cheNode = self:findChild("che")
    self.cheHead = util_spineCreate("StarryXmas_shoujilan",true,true)
    self.cheNode:addChild(self.cheHead)
    
    --进度条右边小关
    self.smallGuanNode = util_createView("CodeStarryXmasSrc.collect.StarryXmasCollectActView","StarryXmas_shoujilan_shengdanshu")
    self:findChild("shoujilan_shengdanshu"):addChild(self.smallGuanNode)
    self.smallGuanNode:setVisible(false)

    --进度条右边大关
    self.daGuanNode = util_createView("CodeStarryXmasSrc.collect.StarryXmasCollectBarDaGuanTail")
    self:findChild("daguan"):addChild(self.daGuanNode)
    self.daGuanNode:setVisible(false)

    --星星
    self.xingxingSpine = util_spineCreate("Socre_StarryXmas_WildBonus",true,true)
    self:findChild("xingxing"):addChild(self.xingxingSpine)
    util_spinePlay(self.xingxingSpine, "actionframe_idle", true)

    --提示按钮
    self.collectTipView = util_createView("CodeStarryXmasSrc.collect.StarryXmasCollectActView","StarryXmas_Map_tips")
    self:findChild("Node_tips"):addChild(self.collectTipView)

    self.m_progress = self:findChild("Node_jindutiao")

    self:initLoadingbar(0)
    self.actNode = cc.Node:create()
    self:addChild(self.actNode)
    
    -- 点击
    self:addClick(self.m_csbOwner["map"])
end

function StarryXmasCollectBarView:onEnter()
 

end

function StarryXmasCollectBarView:initLoadingbar(_percent)
    self.m_progress:setPositionX(_percent * 0.01 * PROGRESS_WIDTH)
end

function StarryXmasCollectBarView:updateLoadingbar(_collectCount, _needCount, _update, _func)
    local percent = self:getPercent(_collectCount, _needCount)
    if _update then
        self:initLoadingbar(percent)
    else
        self:updateLoadingAct(percent, _func)
    end
end

function StarryXmasCollectBarView:updateLoadingAct(_percent, _func)
    util_spinePlay(self.cheHead, "zengzhang", false)

    self:runCsbAction("zengzhang",false, function()
        self:idle()
    end)

    self.actNode:stopAllActions() 
    local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100
    local curOldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100
    util_schedule(self.actNode,function( )
        oldPercent = oldPercent + (_percent-curOldPercent)/16
        if oldPercent >= _percent then
            oldPercent = _percent
            self.m_progress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            self.actNode:stopAllActions() 
            if _func then
                _func()
            end
        else
            self.m_progress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
        end
    end,0.05)
end


function StarryXmasCollectBarView:getPercent(_collectCount, _needCount)
    local percent = 0
    if _collectCount and _needCount  then
        if _collectCount >= _needCount and _needCount ~= 0 then
            percent = 100
        elseif _collectCount == 0 and _needCount == 0 then
            percent = 0
        else
            percent = (_collectCount / _needCount) * 100
        end
    end
    return percent
end

-- 重新设置车的位置
function StarryXmasCollectBarView:changeChePos(_node, _percent)
    local width = _node:getContentSize().width
    local posX = width*_percent/100
    self.cheNode:setPosition(posX-410,11)
end

--锁定进度条
function StarryXmasCollectBarView:lock(betLevel)
    self.m_iBetLevel = betLevel
    self.cheHead:setVisible(false)
    self:stopAllActions()
    self:runCsbAction("lock",false,function (  )
        self:idle()
    end)
end
--解锁进度条
function StarryXmasCollectBarView:unLock(betLevel)
    self.m_iBetLevel = betLevel
    self.cheHead:setVisible(true)
    self:stopAllActions()
    self:runCsbAction("unlock", false, function()
        
        self:idle()
    end)
end

function StarryXmasCollectBarView:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
        self:runCsbAction("idle3", true)
    else
        self:runCsbAction("idle", true)
    end
end

function StarryXmasCollectBarView:onExit()
 
end

--默认按钮监听回调
function StarryXmasCollectBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "anniu" then
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")
    elseif name == "map" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end


return StarryXmasCollectBarView