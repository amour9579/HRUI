local _, ns = ...

local function GetFontValues()
  local values = {}

  if ns.Media and ns.Media.fonts then
    for key in pairs(ns.Media.fonts) do
      values[key] = key
    end
  end

  if not next(values) then
    values["default"] = "default"
  end

  return values
end

if not StaticPopupDialogs["HRUI_RELOAD_ACTIONBARS"] then
  StaticPopupDialogs["HRUI_RELOAD_ACTIONBARS"] = {
    text = "이 설정은 적용을 위해 UI 리로드가 필요합니다.\n지금 리로드하시겠습니까?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      ReloadUI()
    end,
    OnCancel = function(_, data)
      if data and data.onCancel then
        data.onCancel()
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
end

local function ShowActionBarsReloadPopup(onCancel)
  if StaticPopup_Visible("HRUI_RELOAD_ACTIONBARS") then
    return
  end

  StaticPopup_Show("HRUI_RELOAD_ACTIONBARS", nil, nil, {
    onCancel = onCancel,
  })
end

local function SetActionBarsOptionWithReload(key, value)
  local db = ns.db and ns.db.profile and ns.db.profile.actionbars
  if not db then
    return
  end

  if db[key] == value then
    return
  end

  db[key] = value
  ShowActionBarsReloadPopup()
end

function ns:CreateActionBarsOptions()
  return {
    type = "group",
    name = "단축바, 기본바",
    order = 30,
    args = {
      skin = {
        type = "toggle",
        name = "단축바 스킨 사용",
        desc = "해제 시 기본 스킨 복원을 위해 /reload 필요",
        order = 1,
        get = function()
          return ns.db.profile.actionbars.skin
        end,
        set = function(_, value)
          ns.db.profile.actionbars.skin = value

          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end

          if not value then
            if ns.HRUI and ns.HRUI.Print then
              ns.HRUI:Print("|cffff5555단축바 기본 스킨 복원을 위해 /reload 필요|r")
            else
              print("|cffff5555HRUI: 단축바 기본 스킨 복원을 위해 /reload 필요|r")
            end
          end
        end,
      },

      skin_notice = {
        type = "description",
        name = "|cffff5555※ 스킨 해제 시 /reload 필요|r",
        order = 2,
      },

      font = {
        type = "select",
        name = "폰트",
        order = 10,
        values = GetFontValues,
        get = function()
          return ns.db.profile.actionbars.font or "default"
        end,
        set = function(_, value)
          ns.db.profile.actionbars.font = value
          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end
        end,
      },

      fontOutline = {
        type = "select",
        name = "외곽선",
        order = 11,
        values = {
          [""] = "없음",
          ["OUTLINE"] = "OUTLINE",
          ["THICKOUTLINE"] = "THICKOUTLINE",
          ["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
        },
        get = function()
          return ns.db.profile.actionbars.fontOutline or "OUTLINE"
        end,
        set = function(_, value)
          ns.db.profile.actionbars.fontOutline = value
          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end
        end,
      },

      hotkeyFontSize = {
        type = "range",
        name = "단축키 글자 크기",
        order = 20,
        min = 6,
        max = 24,
        step = 1,
        get = function()
          return ns.db.profile.actionbars.hotkeyFontSize or 11
        end,
        set = function(_, value)
          ns.db.profile.actionbars.hotkeyFontSize = value
          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end
        end,
      },

      macroFontSize = {
        type = "range",
        name = "매크로 글자 크기",
        order = 21,
        min = 6,
        max = 24,
        step = 1,
        get = function()
          return ns.db.profile.actionbars.macroFontSize or 10
        end,
        set = function(_, value)
          ns.db.profile.actionbars.macroFontSize = value
          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end
        end,
      },

      countFontSize = {
        type = "range",
        name = "중첩 글자 크기",
        order = 22,
        min = 6,
        max = 24,
        step = 1,
        get = function()
          return ns.db.profile.actionbars.countFontSize or 11
        end,
        set = function(_, value)
          ns.db.profile.actionbars.countFontSize = value
          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end
        end,
      },

      showMacroName = {
        type = "toggle",
        name = "매크로 글자 표시",
        order = 30,
        get = function()
          return ns.db.profile.actionbars.showMacroName
        end,
        set = function(_, value)
          ns.db.profile.actionbars.showMacroName = value
          if ns.Modules and ns.Modules.ActionBars then
            ns.Modules.ActionBars:Refresh()
          end
        end,
      },

      reloadNotice = {
        type = "description",
        name = "|cffffcc00※ 가방바/메뉴바 숨김 설정은 리로드 후 적용됩니다.|r",
        order = 39,
      },

      hideBagBar = {
        type = "toggle",
        name = "가방바 숨기기",
        order = 40,
        get = function()
          return ns.db.profile.actionbars.hideBagBar
        end,
        set = function(_, value)
          SetActionBarsOptionWithReload("hideBagBar", value)
        end,
      },

      hideMicroMenu = {
        type = "toggle",
        name = "메뉴바 숨기기",
        order = 41,
        get = function()
          return ns.db.profile.actionbars.hideMicroMenu
        end,
        set = function(_, value)
          SetActionBarsOptionWithReload("hideMicroMenu", value)
        end,
      },
    },
  }
end
