local addonName = GetAddOnMetadata('GatherMate2Marker', 'Title')
local addonNameFull = GetAddOnMetadata('GatherMate2Marker', 'X-FullName')
local addonVersion = GetAddOnMetadata('GatherMate2Marker', 'Version')

local GatherMate2Marker = LibStub('AceAddon-3.0'):NewAddon('GatherMate2Marker', 'AceConsole-3.0', 'AceTimer-3.0')
local GatherMate = LibStub('AceAddon-3.0'):GetAddon('GatherMate2')
local GatherMate2MarkerCfg = LibStub('AceConfig-3.0')

profile = nil

GM_Display, GM_Display_addMiniMapPinStub = nil
PinDB, GM2_DB = nil

local showOptionsPanel = false

HeaderColor_h1 = '|cffffd200'
HeaderColor_h2 = '|cffffff78'
Text_normal = '|cffffffff'
Text_special1 = '|cFF8888FF'
Text_special2 = '|cFFFF4500'

local GatherMate2MarkerOptions = {
    name = addonNameFull .. ' Options',
    handler = GatherMate2Marker,
    type = 'group',
    childGroups = 'select',
    args = {
        general = {
            name = 'General',
            type = 'group',
            order = 1,
            args = {
                helpGeneral = {
                    type = 'description',
                    name = 'General Options',
                    order = 1
                },
                enabled = {
                    type = 'toggle',
                    name = 'Add-On Enabled',
                    desc = 'Enable or disable marking of recently visited GM2 tracking nodes via ' .. addonNameFull,
                    get = 'GetEnabled',
                    set = 'SetEnabled',
					width = 'full',
                    order = 2
                },
                helpNode = {
                    type = 'description',
                    name = '\r\nNode Options',
                    order = 3
                },				
				markedNodeColor = {
					type = 'color',
					name = 'Marked Node Color',
					hasAlpha = true,
					desc = 'Color and Alpha for marked nodes. To simply dim existing minimap icon and GM2 circles, just set to white and adjust alpha value.',
                    get = 'GetMarkedNodeColor',
                    set = 'SetMarkedNodeColor',
					width = 'full',
					order = 4
				},
				markResetTimeInMinutes = {
					type = 'input',
					name = 'Mark Reset Minutes',
					desc = 'Time (in minutes) to reset marked node icons. Default is 5. Supports partial minutes (0.5, etc.)',
                    get = 'GetResetTimeInMinutes',
                    set = 'SetResetTimeInMinutes',
					width = 'full',
					order = 5
				},
                helpMisc = {
                    type = 'description',
                    name = '\r\nWhile reloading the UI should not be required, doing so will reset the state of things (Timers, marked node colors, etc.) If you radically change your timers or experience any visual issues, simply click the button below.',
                    order = 6
                },				
				reloadUIButton = {
					type = 'execute',
					name = 'Reload UI',
					desc = 'Reload the Blizz UI',
					func = function () ReloadUI() end,
					order = 7,
				}
            }
        },
        help = {
			type = 'group',
			name = 'Help / FAQ',
			args = {
				whatIsThisThingFaqHeader = {
					order = 1,
					type = 'description',
					name = HeaderColor_h1 .. 'What does ' .. addonNameFull .. ' do?',
					width = 'full',
					fontSize = 'large'
				},
				whatIsThisThingFaqDetails = {
					order = 2,
					type = 'description',
					name = '\r\n' .. addonNameFull .. ' works with GatherMate2 to optionally dim or color nodes once you have \'seen\' them on your minimap. If you walk or fly close to a resource node, the node on your MiniMap will mark itself as \'seen\', per your ' .. addonNameFull .. ' settings.',
					width = 'full',
					fontSize = 'medium'
				},
				optimalDistanceFaqHeader = {
					order = 3,
					type = 'description',
					name = HeaderColor_h1 .. '\r\nOptimal Tracking Distance',
					width = 'full',
					fontSize = 'large'
				},
				optimalDistanceFaqDetails = {
					order = 4,
					type = 'description',
					name = '\r\n' .. 'To get the most out of ' .. addonNameFull .. ', set GatherMate2\'s \'Tracking Distance\' (located under ' 
						.. Text_special1 .. 'GatherMate 2->Minimap->Tracking Distance|r to somewhere around ' .. Text_special2 .. 
						'80 -110|r.\r\n\r\nThe general idea is that when you pass near a resource node, GatherMate displays a tracking circle (dependent on how far you are from the historical data node.)\r\n\r\nIf a resource exists at that point, it will light up (via WoW\'s built-in tracker). ' .. 
						'\r\n\r\n' .. addonNameFull .. ' will change the resource node icon\'s color on your MiniMap to let you know you\'ve already scanned the node.\r\n\r\nIcons will reset to their normal color once ' .. 
						addonNameFull .. '\'s timer has ended.',
					width = 'full',
					fontSize = 'medium'
				},
				miscFaqHeader = {
					order = 5,
					type = 'description',
					name = HeaderColor_h1 .. '\r\nWhy set a custom color?',
					width = 'full',
					fontSize = 'large'
				},
				miscDistanceFaqDetails = {
					order = 6,
					type = 'description',
					name = '\r\n' .. 'GatherMate automatically fades resource nodes that are far away. They are shown on the edges of the MiniMap. Choosing an explicit color/alpha can help to disambiguate visited/marked resource nodes from GM2\'s fade rules.',
					width = 'full',
					fontSize = 'medium'
				},
				generalFaqHeader = {
					order = 7,
					type = 'description',
					name = HeaderColor_h1 .. '\r\nFuture Improvements',
					width = 'full',
					fontSize = 'large'
				},
				generalDistanceFaqDetails = {
					order = 8,
					type = 'description',
					name = '\r\n' .. '- Integrated Routes support: Set marked node colors to the choosen Routes route color.\r\n\r\n- Optional SFX or UI notification when a node has been marked \'seen\'. This might be useless, since Blizz doesn\'t notify when actual collectable resoures are available.',
					width = 'full',
					fontSize = 'medium'
				}
			}
        },
        version = {
			type = 'group',
			name = 'Version',
			args = {
				versionText = {
					order = 1,
					type = 'description',
					name = HeaderColor_h1 .. 'Version: ' .. addonVersion,
					width = 'full',
					fontSize = 'large'
				}
			}
        }
    }
}

local optionDefaults = {
    profile = {
        enabled = true,
		ResetTimeInMinutes = 5,
		nodeColor = { 1.0, 1.0, 1.0, 0.45 }
    }
}

GatherMate2MarkerOptionsDlg = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(addonName, addonNameFull)

function GatherMate2Marker:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('GatherMate2MarkerDB', optionDefaults)

    self.db.RegisterCallback(self, 'OnProfileChanged', 'RefreshConfig')
    self.db.RegisterCallback(self, 'OnProfileCopied', 'RefreshConfig')
    self.db.RegisterCallback(self, 'OnProfileReset', 'ResetConfig')

    profile = self.db.profile

    GatherMate2MarkerOptions.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
    GatherMate2MarkerOptions.args.profiles.order = 2
    GatherMate2MarkerCfg:RegisterOptionsTable(addonName, GatherMate2MarkerOptions)

	-- general initialization
	PinDB = {}

	-- get ahold of GatherMate2 modules and data
	GM2_DB = GatherMate.db.profile

	GM_Display = GatherMate2:GetModule('Display')
	GM_Display_addMiniMapPinActual = GM_Display.addMiniPin

	-- if we are enabled, override addMiniPin with our local override
	if profile.enabled == true then
		GM_Display.addMiniPin = GatherMate2Marker.AddMiniPin_STUB
	end

    self:RegisterChatCommand('gmm', 'ToggleOptions')	
    self:RegisterChatCommand('gm2m', 'ToggleOptions')	
    self:RegisterChatCommand('GatherMate2Marker', 'ToggleOptions')	
    self:RegisterChatCommand('GatherMate2Marker', 'ToggleOptions')	
    self:RegisterChatCommand('GatherMate2Marker', 'ToggleOptions')	
    self:RegisterChatCommand('GatherMateMarker', 'ToggleOptions')	
    self:RegisterChatCommand('gathermatemarker', 'ToggleOptions')	

	GatherMate2Marker:CancelAllTimers()

	print(addonNameFull .. ' initialized')
end	

function GatherMate2Marker:SetEnabled(info, val)
	profile.enabled = val

	if profile.enabled == true then
		if GM_Display.addMiniPin ~= GatherMate2Marker.AddMiniPin_STUB then
	 		GM_Display.addMiniPin = GatherMate2Marker.AddMiniPin_STUB
		end
	else
	 	GM_Display.addMiniPin = GM_Display_addMiniMapPinActual
	end

	-- Update GM2, which should send current minimap pin updates
	GM_Display:UpdateMiniMap(true)
end

function GatherMate2Marker:GetEnabled(info)
    return profile.enabled
end

function GatherMate2Marker:GetMarkedNodeColor(info)
	return UnpackColorData(profile.nodeColor)
end

function GatherMate2Marker:SetMarkedNodeColor(info, r, g, b, a)
	profile.nodeColor = { r, g, b, a }
    self:RefreshConfig()    
end

function GatherMate2Marker:GetResetTimeInMinutes(info)
    return tostring(profile.ResetTimeInMinutes)
end

function GatherMate2Marker:SetResetTimeInMinutes(info, val)
	profile.ResetTimeInMinutes = val
    self:RefreshConfig()    
end

local function ScrollToCategory(panelName, offset)
    local idx = 0
    InterfaceOptionsFrameAddOnsListScrollBar:SetValue(0)
    for i,cat in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do 
        if not cat.hidden then 
            idx = idx + 1
            if cat.name == panelName then
                break
            end
        end
    end

    local numbuttons = #(InterfaceOptionsFrameAddOns.buttons)
    if idx and numbuttons and idx > numbuttons then
        local btnHeight = InterfaceOptionsFrameAddOns.buttons[1]:GetHeight()
        InterfaceOptionsFrameAddOnsListScrollBar:SetValue((offset+idx-numbuttons)*btnHeight)
    end
end

function GatherMate2Marker:ToggleOptions()
	showOptionsPanel = not showOptionsPanel
	if showOptionsPanel then
		InterfaceOptionsFrame_Show()
		ScrollToCategory(addonNameFull)
		InterfaceOptionsFrame_OpenToCategory(addonNameFull)
	else
		InterfaceOptionsFrame_Show()
	end 
end

function GatherMate2Marker:RefreshConfig()
	GM_Display:UpdateMiniMap(false)
end

function GatherMate2Marker:ResetConfig()
	profile.nodeColor = optionDefaults.profile.nodeColor
	profile.ResetTimeInMinutes = optionDefaults.profile.ResetTimeInMinutes
	profile.enabled = optionDefaults.profile.enabled
end

function GatherMate2Marker:AddMiniPin_STUB(pin, refresh)	
	-- trigger the original GM2 addMinimapPin method
	GM_Display_addMiniMapPinActual(_, pin, refresh)	

	if profile.enabled == false then
		return
	end

	-- GM2 still marks the circles, but no point in marking them as seen, since like.. we're dead!
	local isDeadOrGhost = UnitIsDeadOrGhost('player') 
	local isTraveling = UnitOnTaxi('player')

	if isDeadOrGhost == true or isTraveling == true then
		return
	end

	if pin.isCircle == true then		
		if PinDB[pin.coords] == nil then
			PinDB[pin.coords] = {}
		end

		PinDB[pin.coords].touched = true

		pin.texture:SetVertexColor(UnpackColorData(profile.nodeColor))

		-- for future debugging
		-- local pinX, pinY = GatherMate:DecodeLoc(pin.coords) 

		if PinDB[pin.coords].activeTimer ~= nil then
			GatherMate2Marker:CancelTimer(PinDB[pin.coords].activeTimer)
		end

		PinDB[pin.coords].activeTimer = GatherMate2Marker:ScheduleTimer(function() GatherMate2Marker:ResetNodeToDefault(pin.coords) end, profile.ResetTimeInMinutes * 60, nil, nil)		
	elseif PinDB[pin.coords] ~= nil and PinDB[pin.coords].touched == true then
		pin.texture:SetVertexColor(UnpackColorData(profile.nodeColor))
	end
end

function GatherMate2Marker:ResetNodeToDefault(coords)
	if coords == nil then
		print('received invalid coords on ResetNodeToDefault callback!')
	end
	
	if PinDB[coords] == nil then
		PinDB[coords] = {}
	end

	PinDB[coords].touched = false
	PinDB[coords].activeTimer = nil
end

-- internal utility methods
function UnpackColorData(val)
	return unpack(val)
end