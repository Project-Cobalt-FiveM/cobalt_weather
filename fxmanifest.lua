fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_weather'
author 'Project Cobalt'
description 'Server-authoritative weather and time'
version '1.0.0'

dependencies {
    'ox_lib',
}

shared_script '@ox_lib/init.lua'

client_script 'client/init.lua'
server_script 'server/init.lua'

files {
    'shared/*.lua',
}
