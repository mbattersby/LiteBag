--[[----------------------------------------------------------------------------

  LiteBag/BankFrame.lua

  Copyright 2013-2016 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local BANK_BAG_IDS = { -1, 5, 6, 7, 8, 9, 10, 11 }

function LiteBagBank_OnLoad(self)
    LiteBagFrame_OnLoad(self)

    -- Basic slots panel for the bank slots

    local panel = CreateFrame("Frame", "LiteBagBankPanel", self, "LiteBagPanelTemplate")
    LiteBagPanel_Initialize(panel, BANK_BAG_IDS)
    panel.defaultColumns = 16
    panel.canResize = true
    LiteBagFrame_AddPanel(self, panel, BankFrameTab1:GetText())

    -- Attach in the other Blizzard bank panels. Note that we are also
    -- responsible for handling their events!

    for i = 2, #BANK_PANELS do
        local data = BANK_PANELS[i]
        panel = _G[data.name]
        panel:ClearAllPoints()
        panel:SetSize(data.size.x, data.size.y)
        LiteBagFrame_AddPanel(self, panel, _G["BankFrameTab"..i]:GetText())
    end

    self.OnShowPanel = function (self, n)
            -- Use the title text from the Bank Frame itself
            BANK_PANELS[self.selectedTab].SetTitle()
            self.TitleText:SetText(BankFrameTitleText)
        end

    -- UIPanelLayout stuff so the Blizzard UIParent code will position us
    -- automatically. See
    --   http://www.wowwiki.com/Creating_standard_left-sliding_frames
    -- but note that UIPanelLayout-enabled isn't a thing at all.

    self:SetAttribute("UIPanelLayout-defined", true)
    self:SetAttribute("UIPanelLayout-area", "left")
    self:SetAttribute("UIPanelLayout-pushable", 6)

    -- Different inset texture for the bank

    self.Inset.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", true, true)

    -- Select the right search box 
    self.searchBox = BankItemSearchBox
    self.sortButton = BankItemAutoSortButton

    -- Bank frame specific events
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
end

function LiteBagBank_OnEvent(self, event, ...)
    LiteBag_Print("Bank OnEvent " .. event)
    if event == "BANKFRAME_OPENED" then
        LiteBagFrame_ShowPanel(self, 1)
        ShowUIPanel(self)
    elseif event == "BANKFRAME_CLOSED" then
        HideUIPanel(self)
    elseif event == "INVENTORY_SEARCH_UPDATE" then
        ContainerFrame_UpdateSearchResults(ReagentbankFrame)
    elseif event == "ITEM_LOCK_CHANGED" then
        local bag, slot = ...
        if bag == REAGENTBANK_CONTAINER then
            local button = ReagentBankFrame["Item"..(slot)]
            if button then
                BankFrameItemButton_UpdateLocked(button)
            end
        end
    elseif event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
        local slot = ...
        BankFrameItemButton_Update(ReagentBankFrame["Item"..(slot)])
    end
end

-- Note that the reagent bank frame refreshes all its own slots in its
-- OnShow handler so we don't have to do that for it.

function LiteBagBank_OnShow(self)
    LiteBagFrame_OnShow(self)

    SetPortraitTexture(self, "npc")

    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
end

function LiteBagBank_OnHide(self)
    -- Call this so the server knows we closed and it needs to send us a
    -- new BANKFRAME_OPENED event if we interact with the NPC again.
    CloseBankFrame()
    self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:UnregisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
end
