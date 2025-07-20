fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'HRCarWash'
author 'HRScripts'
description 'Car wash script with car wash stations option and realistic car washing by yourself'
version '1.0.0'

shared_script '@HRLib/import.lua'

client_script 'client/*.lua'

server_script 'server/*.lua'

files {
    'config.lua',
    'translation.lua'
}

dependencies {
    'HRLib',
    'oxmysql'
}