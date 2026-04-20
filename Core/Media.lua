local _, ns = ...

ns.Media = ns.Media or {}

ns.Media.fonts = {
  default = STANDARD_TEXT_FONT,
  ["2002"] = "Fonts\\2002.ttf",
  ["2002B"] = "Fonts\\2002B.ttf",
  ["K_Damage"] = "Fonts\\K_Damage.ttf",
  ["GmarketSansTTFBold"] = "Interface\\AddOns\\HRUI\\Media\\Fonts\\GmarketSansTTFBold.ttf",
  ["ChosunCentennial_ttf"] = "Interface\\AddOns\\HRUI\\Media\\Fonts\\ChosunCentennial_ttf.ttf",
  ["Maplestory Light"] = "Interface\\AddOns\\HRUI\\Media\\Fonts\\Maplestory Light.ttf",
  ["ActionMan"] = "Interface\\AddOns\\HRUI\\Media\\Fonts\\ActionMan.ttf",
}

ns.Media.Textures = {
  default = "Interface\\TARGETINGFRAME\\UI-StatusBar",
  smooth  = "Interface\\Buttons\\WHITE8x8",
  aluminium = "Interface\\AddOns\\HRUI\\Media\\Textures\\Aluminium",
  diagonal  = "Interface\\AddOns\\HRUI\\Media\\Textures\\Diagonal",
  glowTex   = "Interface\\AddOns\\HRUI\\Media\\Textures\\GlowTex",
  melli     = "Interface\\AddOns\\HRUI\\Media\\Textures\\Melli",
  minimalist = "Interface\\AddOns\\HRUI\\Media\\Textures\\Minimalist",
  normTex   = "Interface\\AddOns\\HRUI\\Media\\Textures\\NormTex",
  normTex2    = "Interface\\AddOns\\HRUI\\Media\\Textures\\NormTex2",
  normTex3   = "Interface\\AddOns\\HRUI\\Media\\Textures\\NormTex3",
  rocks      = "Interface\\AddOns\\HRUI\\Media\\Textures\\Rocks",
  striped    = "Interface\\AddOns\\HRUI\\Media\\Textures\\Striped",
}

function ns:GetTexture()
  local key = ns.db and ns.db.profile and ns.db.profile.general and ns.db.profile.general.texture
  if key and ns.Media.Textures[key] then
    return ns.Media.Textures[key]
  end

  return ns.Media.Textures.default
end

function ns:GetTextAnchorPoint(anchor)
  if anchor == "CENTER" then
    return "CENTER"
  elseif anchor == "RIGHT" then
    return "RIGHT"
  end
  return "LEFT"
end

function ns:GetFont()
  return ns.db.profile.general.font
end

function ns:GetFontByKey(fontKey)
  if ns.Media and ns.Media.fonts and ns.Media.fonts[fontKey or "default"] then
    return ns.Media.fonts[fontKey or "default"]
  end

  if fontKey and fontKey ~= "default" then
    return fontKey
  end

  return ns:GetFont()
end
