-- Copyright © 2010-2014 Lanerra. See LICENSE file for license terms.
Settings = {
    Show = {
        CastBars = true,
        Focus = true,
        ToT = true,
        Party = true,
        Raid = true,
        HealerOverride = true
    },
    Media = {
        Border = 'Interface\\Addons\\oUF_Lanerra\\media\\borderTexture.tga',
        StatusBar = 'Interface\\Addons\\oUF_Lanerra\\media\\statusbarTexture.tga',
        Font = 'Interface\\Addons\\oUF_Lanerra\\media\\font.ttf',
        FontSize = 15,
        BorderSize = 12,
        BorderColor = { 0.65, 0.65, 0.65 },
        BackdropColor = { 0, 0, 0, 0.5 },
        BorderPadding = 4
    },
    Units = {
        Player = {
            Height = 30,
            Width = 200,
            Position = {'CENTER', UIParent, -325, -175},
            Health = {
                Percent = false,
                Deficit = false,
                Current = true,
            },
            ShowPowerText = true,
            ShowBuffs = false,
        },
        Pet = {
            Height = 30,
            Width = 80,
            Position = {'CENTER', UIParent, -485, -175},
            Health = {
                Percent = false,
                Deficit = false,
                Current = false,
            },
        },
        Target = {
            Height = 30,
            Width = 200,
            Position = {'CENTER', UIParent, 325, -175},
            Health = {
                Percent = true,
                Deficit = false,
                Current = false,
                PerCur = false,
            },
            ShowPowerText = true,
            ShowBuffs = true,
        },
        ToT = {
            Height = 30,
            Width = 80,
            Position = {'CENTER', UIParent, 485, -175},
            Health = {
                Percent = false,
                Deficit = false,
                Current = false,
            },
        },
        Focus = {
            Height = 30,
            Width = 30,
            Position = {'CENTER', UIParent, 0, -175},
            Health = {
                Percent = false,
                Deficit = false,
                Current = false,
            },
            VerticalHealth = true,
        },
        Party = {
            Height = 20,
            Width = 100,
            TinyPosition = {'TOPLEFT', UIParent, 25, -210},
            Position = {'TOPLEFT', UIParent, 25, -25},
            Health = {
                Percent = true,
                Deficit = false,
                Current = false,
                ClassColor = true,
            },
            ShowBuffs = false, -- Show buffs on party frames
            HidePower = true, -- Reserved for future use
            Healer = true,
        },
        Raid = {
            Height = 18,
            Width = 100,
            TinyPosition = {'TOPLEFT', UIParent, 25, -210},
            Position = {'TOPLEFT', UIParent, 25, -25},
            Health = {
                Percent = false,
                Deficit = true,
                Current = false,
                ClassColor = true,
            },
            HidePower = true, -- Reserved for future use
            Healer = true, -- If true, overrides height and width in this section and gets set to a static amount
        },
    },
    CastBars = {
        Player = {
            Show = true,
            Height = 25,
            Width = 200,
            Scale = 1,
            Position = {'CENTER', UIParent, -325, -232},
            ClassColor = false,
            SafeZone = true,
            Latency = false,
            Color = {.25, .25, .25},
        },
        Target = {
            Show = true,
            Height = 25,
            Width = 200,
            Scale = 1,
            Position = {'CENTER', UIParent, 325, -232},
            ClassColor = false,
            Color = {.25, .25, .25},
            InterruptHighlight = false,
            InterruptColor = {1, 0, 1},
        },
    },
}