--[[
    集卡系统 Link小游戏管理
--]]
local CardSysLinkManager = class("CardSysLinkManager")
function CardSysLinkManager:ctor()
    self:reset()
    self:initBaseData()
end

function CardSysLinkManager:reset()
    -- 需要进入Nado机
    self.m_isNeedEnterNado = false
end

function CardSysLinkManager:initBaseData()
end

function CardSysLinkManager:setNeedEnterNado(isNeed)
    self.m_isNeedEnterNado = isNeed
end
-- 是否需要进入Nado机
function CardSysLinkManager:isNeedEnterNado()
    return self.m_isNeedEnterNado
end

-- nado卡获得进度界面
function CardSysLinkManager:showCardLinkProgressComplete(params, _curLogic)
    if gLobalViewManager:getViewByName("CardLinkProgressComplete") ~= nil then
        return
    end
    if not _curLogic then
        _curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    end
    if _curLogic then
        local view = _curLogic:createCardLinkProgressComplete(params)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        view:setName("CardLinkProgressComplete")
        CardSysManager:setLinkProgressUI(view)
        return view
    end
end

-- nado卡完成界面
function CardSysLinkManager:showCardLinkComplete(params, _curLogic)
    if not _curLogic then
        _curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    end
    if _curLogic then
        local linkOverComplete = _curLogic:createCardLinkComplete(params)
        gLobalViewManager:showUI(linkOverComplete, ViewZorder.ZORDER_UI)
        CardSysManager:setLinkOverCompleteUI(linkOverComplete)
        return linkOverComplete
    end
end

function CardSysLinkManager:hasNadoMachineUI()
    if gLobalViewManager:getViewByExtendData("CardNadoWheelMainUI") ~= nil then
        return true
    end
    return false
end

-- 显示Link小游戏面板 --传入卡ID和link玩法数量
function CardSysLinkManager:showAceView(source)
    if self.m_linkView ~= nil then
        return
    end
    -- 是否进入的当前开启的赛季
    -- 是否存在赛季信息【赛季是否处在空档期】

    self:setSource(source)

    -- CardSysManager:getLinkMgr():setHasDrops(false)
    -- 正式逻辑在这里
    -- self.m_linkView = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelMainUI")
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.m_linkView = curLogic:createNadoMachineMain()
        gLobalViewManager:showUI(self.m_linkView, ViewZorder.ZORDER_UI)
    end
end

function CardSysLinkManager:setSource(source)
    self.m_source = source
end

function CardSysLinkManager:getSource()
    return self.m_source
end

function CardSysLinkManager:setNadoMachineOverCall(callFunc)
    self.m_overCallFunc = callFunc
end

-- function CardSysLinkManager:setHasDrops(hasDrops)
--     self.m_hasDrops = hasDrops
-- end

-- function CardSysLinkManager:getHasDrops()
--     return self.m_hasDrops
-- end

function CardSysLinkManager:closeAceView(overFunc)
    if self.m_linkView and self.m_linkView.closeUI then
        self.m_linkView:closeUI(overFunc)
        self.m_linkView = nil

        -- if not self.m_hasDrops then
            if self.m_overCallFunc then
                self.m_overCallFunc()
                self.m_overCallFunc = nil
            end
        -- end
    end
end

return CardSysLinkManager
